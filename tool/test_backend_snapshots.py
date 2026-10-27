"""Consistent snapshots over real local HTTP/JWT/PostgreSQL; synthetic owners only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_milestone_create import milestone
from test_backend_tag_commands import tag
from test_backend_memberships import membership
from test_backend_saved_views import view, preference

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261026212133_consistent_snapshots.sql'


def begin_request(f):
    return {'protocol_version': 2, 'server_epoch': f.epoch}


def page_request(f, manifest, page=0):
    return dict(begin_request(f), token=manifest['token'], page=page)


def snapshot_rpc(f, name, request):
    reply = f.backend.rpc(name, f.token, request)
    if reply['status'] == 'success':
        f.backend.wire[-1]['checked_at_utc'] = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
    return reply


def begin(f):
    return snapshot_rpc(f, 'snapshot_begin', begin_request(f))['result']


def page(f, manifest, number=0):
    return snapshot_rpc(f, 'snapshot_page', page_request(f, manifest, number))['result']


def stored(f):
    return sql(f"select (select count(*) from sync_private.snapshots where owner_id='{f.owner}')||','||"
               f"(select count(*) from sync_private.snapshot_pages where owner_id='{f.owner}');")


def candidate_smoke(backend, epoch):
    f = TaskFixture(backend, epoch); f.apply(f.create())
    before = f.state(), f.history()
    source = ('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
              f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
              'select public.sync_snapshot_begin(' + literal(json.dumps(begin_request(f))) + '::jsonb); '
              'set constraints all immediate; rollback;')
    result = json.loads(sql(source).splitlines()[-1])
    require(result['result']['record_count'] == 1, 'Candidate real-owner snapshot')
    require((f.state(), f.history()) == before, 'Candidate preserves exact task/history/receipt/watermark state')
    require(sql("select to_regclass('sync_private.snapshots') is null;") == 't', 'Candidate schema rollback')
    print('PASS: candidate snapshot and retained-state rollback', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--supabase', default='supabase')
    parser.add_argument('--wire-output', type=Path)
    parser.add_argument('--candidate', action='store_true')
    args = parser.parse_args()
    subprocess.run([sys.executable, str(ROOT / 'tool/local_backend.py')], check=True)
    backend = Backend(args.supabase)
    epoch = sql('select server_epoch from sync_private.backend_state;')
    passed = 0

    def check(label):
        nonlocal passed
        passed += 1
        print('PASS: ' + label, flush=True)

    try:
        if args.candidate:
            candidate_smoke(backend, epoch)
            return
        f = TaskFixture(backend, epoch)
        empty = begin(f)
        require(empty['at']['revision'] == 0 and empty['record_count'] == 0 and empty['page_count'] == 1,
                'Empty manifest')
        require(empty['device_high_waters'] == {f.device: 0}, 'Frozen empty watermark')
        require(page(f, empty)['records'] == [] and page(f, empty)['is_last'], 'Empty terminal page')
        ttl = datetime.fromisoformat(empty['expires_at_utc'].replace('Z', '+00:00')) - datetime.now(timezone.utc)
        require(86390 < ttl.total_seconds() <= 86400, 'Trusted server 24-hour expiry')
        require(begin(f) == empty, 'Lost begin response retries stable token')
        with ThreadPoolExecutor(max_workers=2) as pool:
            requests = list(pool.map(lambda _: backend.rpc('snapshot_begin', f.token, begin_request(f)), range(2)))
        # Captures from concurrent helper calls need their read time for Dart validation.
        for entry in backend.wire:
            if entry['rpc'].startswith('snapshot_'):
                entry.setdefault('checked_at_utc', datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'))
        require(all(r['result'] == empty for r in requests) and stored(f) == '1,1', 'Concurrent begin reuse')
        check('empty snapshot, canonical UTC TTL, concurrent/lost-response begin reuse')

        f = TaskFixture(backend, epoch)
        task, label, step, saved = f.create(), tag(f, 2), milestone(f, 3), view(f, 4)
        # Same UUID across kinds must remain distinct in pages.
        label['entity']['key'] = [f.task]; step['entity']['key'] = [f.task]; saved['entity']['key'] = [f.task]
        relation = membership(f, label, 5)
        selected = preference(f, 6, saved['entity']['key'][0])
        f.apply(task, label, step, saved, relation, selected)
        losing = f.op(7, 'candidate', observed(1, 'original'))
        held = f.op(8, 'held successor', predecessor(losing, 'candidate'))
        f.apply(losing, held, deletion(f, 9))
        before = f.state(), f.history()
        capture = begin(f); contents = page(f, capture)
        require(capture['record_count'] == 8 and capture['at']['revision'] == 9, 'Six shadows and two candidates')
        require({r['entity']['kind'] for r in contents['records']} ==
                {'task','tag','milestone','view','membership','preference'}, 'All current shadow kinds')
        require(next(r for r in contents['records'] if r['entity']['kind']=='task')['delete_operation_id'] is not None,
                'Winning deletion identity retained')
        require([r['operation'] for r in sorted(contents['recovery'], key=lambda r:r['revision'])] == [losing,held],
                'Original base and held predecessor payloads retained')
        require((f.state(), f.history()) == before, 'Snapshots never mutate canonical state/history')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; "
            f"delete from sync_private.change_log where owner_id='{f.owner}'; "
            f"update sync_private.account_state set retained_after=revision where owner_id='{f.owner}';")
        require(backend.rpc('pull',f.token,{'protocol_version':2,'after':{'server_epoch':epoch,'revision':0},
                                          'limit':200})['code']=='cursorExpired', 'Expired cursor needs snapshot')
        require(page(f, capture) == contents and begin(f) == capture, 'Pages independent of expired receipts/logs')
        check('all six kinds, deletion identities, original unresolved/held candidates and receipt expiry')

        f = TaskFixture(backend, epoch); f.apply(f.create())
        capture = begin(f); original = page(f, capture)
        f.apply(f.op(2, 'later', observed(1, 'X')))
        require(page(f, capture) == original, 'Frozen page survives live edits')
        require(f.pull(capture['at']['revision'])['groups'][0]['revision'] == 2, 'Pull continues after fixed R')
        later = begin(f)
        require(later['at']['revision'] == 2 and page(f,later)['records'][0]['fields']['title']['value']=='later',
                'New capture sees later state')
        new_device = uid(); f.register(new_device)
        registered = begin(f)
        require(registered['token'] != later['token'] and registered['device_high_waters'][new_device] == 0,
                'Same-revision registration refreshes watermarks')
        require(new_device not in later['device_high_waters'], 'Prior manifest watermarks immutable')
        check('stable page retries, incremental continuation and new-device watermark capture')

        # Hold an uncommitted writer, prove begin blocks, then sees its commit.
        f = TaskFixture(backend, epoch); creation = f.create()
        source = (f"begin; set local application_name='{f.owner}'; set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true); "
                  'select public.sync_apply(' + literal(json.dumps(f.request(creation))) + '::jsonb); '
                  'select pg_sleep(2); commit;')
        with ThreadPoolExecutor(max_workers=2) as pool:
            writer = pool.submit(sql, source)
            deadline = time.monotonic()+5
            while sql(f"select exists(select 1 from pg_stat_activity where wait_event='PgSleep' "
                      f"and application_name='{f.owner}');") != 't':
                require(time.monotonic()<deadline,'Writer entered transaction'); time.sleep(.05)
            start = time.monotonic(); capture = begin(f); writer.result()
        require(time.monotonic()-start > 1 and capture['at']['revision']==1 and capture['device_high_waters'][f.device]==1,
                'Begin waited for canonical/log/receipt/watermark commit')
        require(page(f,capture)['records'][0]['fields']==f.fields(), 'No torn state after late commit')
        check('account lock waits for late commit and captures matching revision, fields and watermark')

        f = TaskFixture(backend,epoch)
        for offset in range(0,205,32):
            f.apply(*(f.create(i+1,task=uid()) for i in range(offset,min(offset+32,205))))
        capture = begin(f)
        first,last = page(f,capture),page(f,capture,1)
        require(capture['record_count']==205 and capture['page_count']==2 and len(first['records'])==200
                and len(last['records'])==5 and not first['is_last'] and last['is_last'], 'Count-bounded stable paging')
        require(len({r['entity']['key'][0] for r in first['records']+last['records']})==205, 'No duplicate/missing identities')
        require(page(f,capture,1)==last and page(f,capture)==first,'Out-of-order interrupted page retries')
        check('multi-page count limits, exact counts, no duplicates and interrupted/out-of-order retries')

        f = TaskFixture(backend,epoch); f.apply(f.create())
        for offset in range(0,205,32):
            f.apply(*(f.op(i+2,'candidate '+str(i),observed(1,'wrong original'))
                      for i in range(offset,min(offset+32,205))))
        capture=begin(f); pages=[page(f,capture,i) for i in range(capture['page_count'])]
        candidates=[r for p in pages for r in p['recovery']]
        require(capture['record_count']==206 and capture['page_count']==2 and len(candidates)==205
                and len({r['id'] for r in candidates})==205 and all(len(p['recovery'])<=200 for p in pages),
                'Recovery count pagination independent of shadow count')
        check('recovery count limit, exact combined manifest count and complete candidate identities')

        # Large but valid accepted operation candidates force byte-limited pages
        # before the 200-record count. Canonical content stays unchanged.
        f = TaskFixture(backend,epoch); f.apply(f.create())
        for offset in range(0,70,10):
            f.apply(*(f.op(i+2,'x'*50000,observed(1,''),group='description') for i in range(offset,offset+10)))
        capture = begin(f)
        pages = [page(f,capture,i) for i in range(capture['page_count'])]
        require(capture['page_count']>=2 and capture['record_count']==71 and sum(len(p['recovery']) for p in pages)==70,
                'Byte bounded recovery pages')
        require(all(len(json.dumps(p).encode())<4194304 and len(p['recovery'])<=200 for p in pages),'Response bounds')
        check('byte-bounded pages preserve large original recovery operations within Dart response limit')

        f = TaskFixture(backend,epoch); f.apply(f.create()); capture=begin(f)
        stranger=TaskFixture(backend,epoch)
        require(snapshot_rpc(stranger,'snapshot_page',page_request(stranger,capture))['code']=='snapshotExpired',
                'Foreign token indistinguishable from missing')
        require(snapshot_rpc(f,'snapshot_page',dict(page_request(f,capture),token=uid()))['code']=='snapshotExpired','Unknown token')
        for name, request in (('snapshot_begin',begin_request(f)),('snapshot_page',page_request(f,capture))):
            require(backend.rpc(name,f.token,dict(request,server_epoch=uid()))['code']=='serverEpochChanged','Wrong epoch')
            require(backend.rpc(name,f.token,dict(request,protocol_version=3))['code']=='unsupportedProtocol','Wrong protocol')
            for malformed in (dict(request,owner_id=f.owner),dict(request,server_epoch='bad'),{}):
                code,_=backend.request('POST','/rest/v1/rpc/sync_'+name,f.token,{'request':malformed})
                require(code==400,'Malformed request denied')
            code,_=backend.request('POST','/rest/v1/rpc/sync_'+name,None,{'request':request})
            require(code in (401,403),'Anonymous execute denied')
        for number in (-1,True,1.5,1000000,capture['page_count']):
            code,_=backend.request('POST','/rest/v1/rpc/sync_snapshot_page',f.token,
                                   {'request':page_request(f,capture,number)})
            require(code==400,'Invalid or out-of-range page')
        check('X/Y token isolation, anonymous denial, epoch/protocol and strict page/request validation')

        for table in ('snapshots','snapshot_pages'):
            require(sql(f"select relrowsecurity and relforcerowsecurity from pg_class where oid='sync_private.{table}'::regclass;")=='t','Forced RLS')
            require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{stranger.owner}',true) is not null; "
                        f"select count(*) from sync_private.{table} where owner_id='{f.owner}'; rollback;").splitlines()[-1]=='0','Foreign RLS read')
            require(sql(f"select has_table_privilege('dourstuff_rpc','sync_private.{table}','UPDATE');")=='f','Immutable capture grants')
            for token in (None,f.token,stranger.token):
                for method in ('GET','POST','PATCH','DELETE'):
                    code,_=backend.request(method,'/rest/v1/'+table,token,None if method=='GET' else {})
                    require(code in (401,403,404),'Raw REST denial')
                code,_=backend.request('GET','/rest/v1/'+table,token,headers={'Accept-Profile':'sync_private'})
                require(code in (401,403,404,406),'Private schema denied')
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{stranger.owner}',true) is not null; "
                    'do $test$ begin begin insert into sync_private.snapshot_pages values '
                    f"('{f.owner}','{capture['token']}',5,'[]','[]'); raise exception 'Foreign insert allowed'; "
                    'exception when insufficient_privilege then null; end; end $test$; rollback;').splitlines()==['t'], 'Foreign RLS insert denied')
        check('forced RLS, actual foreign insert rejection, raw REST isolation and immutable grants')

        sql(f"update sync_private.account_state set revoked_at=clock_timestamp() where owner_id='{f.owner}';")
        for name,request in (('snapshot_begin',begin_request(f)),('snapshot_page',page_request(f,capture))):
            require(backend.rpc(name,f.token,request)['code']=='accountDeleted','Revoked account denied')
        sql(f"update sync_private.account_state set revoked_at=null where owner_id='{f.owner}';")
        code,_=backend.request('DELETE','/auth/v1/admin/users/'+f.owner,backend.admin)
        require(code==200,'Delete synthetic Auth identity')
        for name,request in (('snapshot_begin',begin_request(f)),('snapshot_page',page_request(f,capture))):
            require(backend.rpc(name,f.token,request)['code']=='accountDeleted','Stale JWT denied after Auth deletion')
        check('revocation and auth-deletion block old snapshot tokens without recreating identity')

        f = TaskFixture(backend,epoch); f.apply(f.create()); captures=[begin(f)]
        for seq in (2,3):
            f.apply(f.op(seq,str(seq),observed(seq-1,'X' if seq==2 else str(seq-1))))
            captures.append(begin(f))
        f.apply(f.op(4,'4',observed(3,'3')))
        require(snapshot_rpc(f,'snapshot_begin',begin_request(f))['code']=='rateLimited' and stored(f)=='3,3','Active capture quota')
        require(page(f,captures[0])['records'][0]['fields']['title']['value']=='X','Quota never evicts unexpired pages')
        sql(f"update sync_private.snapshots set expires_at=clock_timestamp()-interval '1 second' where owner_id='{f.owner}' "
            f"and token='{captures[0]['token']}';")
        require(snapshot_rpc(f,'snapshot_page',page_request(f,captures[0]))['code']=='snapshotExpired','Expired token denied')
        fresh=begin(f)
        require(fresh['at']['revision']==4 and stored(f)=='3,3','Begin removes only expired captures and their pages')
        check('active capture quota, expiration and owner-scoped cascading capture cleanup')

        f = TaskFixture(backend,epoch); f.apply(f.create()); before=f.state(),f.history()
        sql("create function sync_private.test_snapshot_fail() returns trigger language plpgsql as $$ "
            "begin raise exception 'Injected snapshot failure'; end $$; "
            "create trigger test_snapshot_fail before insert on sync_private.snapshots for each row execute function sync_private.test_snapshot_fail();")
        try:
            code,_=backend.request('POST','/rest/v1/rpc/sync_snapshot_begin',f.token,{'request':begin_request(f)})
            require(code==400 and stored(f)=='0,0' and (f.state(),f.history())==before,'Failure after page inserts fully rolls back')
        finally:
            sql('drop trigger test_snapshot_fail on sync_private.snapshots; drop function sync_private.test_snapshot_fail();')
        require(begin(f)['record_count']==1,'Retry after rollback')
        check('injected final-manifest failure rolls back pages and preserves all canonical state')

        # Privileged synthetic pressure fixture verifies capacity failure cannot
        # leave half a snapshot. This is not accepted-command semantic evidence.
        f = TaskFixture(backend,epoch); f.apply(f.create())
        sql(f"update sync_private.task_shadow set fields=jsonb_build_object('description',jsonb_build_object('revision',1,'value',repeat('x',3145728))) where owner_id='{f.owner}';")
        require(snapshot_rpc(f,'snapshot_begin',begin_request(f))['code']=='rateLimited' and stored(f)=='0,0','Oversized record atomic refusal')
        check('oversized synthetic record fails closed without partial capture')
        sql(f"update sync_private.task_shadow set fields=jsonb_build_object('description',jsonb_build_object('revision',1,'value',repeat('x',2097152))) where owner_id='{f.owner}'; "
            f"insert into sync_private.task_shadow(owner_id,task_id,fields) select '{f.owner}',gen_random_uuid(),fields "
            f"from sync_private.task_shadow cross join generate_series(1,32) where owner_id='{f.owner}';")
        require(snapshot_rpc(f,'snapshot_begin',begin_request(f))['code']=='rateLimited' and stored(f)=='0,0',
                'Total capacity rolls back already inserted pages')
        check('64 MiB aggregate capacity rolls back partial pages without touching canonical rows')
        print(f'{passed} snapshot integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True,exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire),encoding='utf-8')


if __name__ == '__main__':
    main()

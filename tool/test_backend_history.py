"""History extension over real local HTTP/JWT/PostgreSQL. Synthetic accounts only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture, status
from test_backend_task_delete import deletion
from test_backend_apply import observed, uid
from test_backend_snapshots import begin as legacy_begin, page as legacy_page, stored

ROOT=Path(__file__).resolve().parents[1]
MIGRATION=ROOT/'supabase/migrations/20261027100646_status_history_transport.sql'


def request(f, **extra):
    return dict(protocol_version=2, history_version=1, server_epoch=f.epoch, **extra)


def rpc(f,name,q):
    reply=f.backend.rpc(name,f.token,q)
    if reply['status']=='success' and name.startswith('snapshot_'):
        f.backend.wire[-1]['checked_at_utc']=datetime.now(timezone.utc).isoformat().replace('+00:00','Z')
    return reply


def begin(f):
    return rpc(f,'snapshot_begin',request(f))['result']


def page(f,m,n=0):
    return rpc(f,'snapshot_page',request(f,token=m['token'],page=n))['result']


def pull(f,after=0,limit=200):
    return rpc(f,'pull',dict(protocol_version=2,history_version=1,
                            after=dict(server_epoch=f.epoch,revision=after),limit=limit))


def seed(backend,epoch):
    fixture=json.loads((ROOT/'test/fixtures/account-history-v1.json').read_text(encoding='utf-8'))
    f=TaskFixture(backend,epoch)
    f.device=fixture['operations'][0]['device_epoch']; f.task=fixture['operations'][0]['entity']['key'][0]
    f.register(f.device); f.apply(*fixture['operations'])
    sql(f"update sync_private.task_status_history set operation=null where owner_id='{f.owner}' and revision=1;")
    return f,fixture


def candidate(backend,epoch):
    f,_=seed(backend,epoch); old=legacy_begin(f); old_page=legacy_page(f,old)
    before=f.state(),f.history(),stored(f)
    q=literal(json.dumps(request(f)))+'::jsonb'
    source=('begin;\n'+MIGRATION.read_text(encoding='utf-8')+
            f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
            f"select public.sync_snapshot_page({q}||jsonb_build_object('token',public.sync_snapshot_begin({q})->'result'->>'token','page',0)); "
            'set constraints all immediate; rollback;')
    result=json.loads(sql(source).splitlines()[-1])['result']
    require(len(result['history'])==2 and result['history'][0]['operation'] is None,'Candidate retains unknown original')
    require((f.state(),f.history(),stored(f))==before and legacy_page(f,old)==old_page,'Exact preexisting capture/data rollback')
    print('PASS: real-owner candidate and existing legacy capture retained through rollback',flush=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--supabase',default='supabase'); parser.add_argument('--wire-output',type=Path)
    parser.add_argument('--candidate',action='store_true'); args=parser.parse_args()
    subprocess.run([sys.executable,str(ROOT/'tool/local_backend.py')],check=True)
    backend=Backend(args.supabase); epoch=sql('select server_epoch from sync_private.backend_state;'); passed=0
    def check(label):
        nonlocal passed
        passed+=1; print('PASS: '+label,flush=True)
    try:
        if args.candidate: candidate(backend,epoch); return
        f,fixture=seed(backend,epoch); before=f.state(),f.history()
        result=pull(f)['result']; events=[e for g in result['groups'] for e in g['history']]
        require([{k:v for k,v in e.items() if k!='recorded_at_utc'} for e in events]==
                [{k:v for k,v in e.items() if k!='recorded_at_utc'} for e in fixture['events']], 'Shared event golden')
        require(events[0]['operation'] is None and events[1]['operation']==fixture['operations'][1],'Known and unknown originals')
        require((f.state(),f.history())==before and pull(f)['result']==result,'Duplicate reads never alter retained state')
        require(all('history' not in g for g in f.pull()['groups']),'Legacy pull shape unchanged')
        check('shared golden, original identities/provenance, backwards device time and legacy pull compatibility')

        old=legacy_begin(f); current=begin(f); frozen=page(f,current)
        require(old['token']!=current['token'] and old['record_count']==1 and current['record_count']==3,'Distinct versioned captures/counts')
        require('history' not in legacy_page(f,old) and frozen['history']==events,'Negotiated page shape')
        require(backend.rpc('snapshot_page',f.token,dict(protocol_version=2,server_epoch=epoch,token=current['token'],page=0))['code']=='snapshotExpired','Downgrade denied')
        require(rpc(f,'snapshot_page',request(f,token=old['token'],page=0))['code']=='snapshotExpired','Legacy token cannot claim history')
        require(begin(f)==current,'Interrupted begin retry reuses correct version')
        f.apply(f.set_status(3,status(),observed(2,status('completed',100))))
        require(page(f,current)==frozen and len(pull(f,2)['result']['groups'][0]['history'])==1,'Fixed R plus incremental history')
        check('token/version binding, complete counts, frozen pages and continuation after status change')

        f.apply(f.set_status(4,status(),observed(3,status())))
        require(pull(f,3)['result']['groups'][0]['history']==[],'No new history for unchanged status')
        f.apply(fixture['operations'][1])
        require(len(f.history())==3,'Immutable duplicate status cannot add history')
        f.apply(deletion(f,5))
        require(len(f.history())==3,'Deletion retains history without inventing a status event')
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}'; "
            f"update sync_private.account_state set retained_after=revision where owner_id='{f.owner}';")
        require(pull(f)['code']=='cursorExpired','Expired cursor')
        latest=begin(f); downloaded=page(f,latest)['history']
        require(page(f,latest)['records'][0]['delete_operation_id'] is not None,'Hidden task history remains downloadable')
        require(len(downloaded)==3 and downloaded[0]['operation'] is None and downloaded[1]['operation']==fixture['operations'][1], 'Retained events outlive logs and receipts')
        require(page(f,current)==frozen,'Existing capture survives expiry')
        check('no-op/dedup semantics and known/unknown historical events survive receipt/log expiry')

        f=TaskFixture(backend,epoch); f.apply(f.create())
        source=(f"begin; set local application_name='{f.owner}'; set local role authenticated; "
                f"select set_config('request.jwt.claim.sub','{f.owner}',true); select public.sync_apply("+
                literal(json.dumps(f.request(f.set_status(2,status('completed',7)))))+'::jsonb); select pg_sleep(3); commit;')
        with ThreadPoolExecutor(max_workers=3) as pool:
            writer=pool.submit(sql,source); deadline=time.monotonic()+5
            while sql(f"select exists(select 1 from pg_stat_activity where application_name='{f.owner}' and wait_event='PgSleep');")!='t':
                require(time.monotonic()<deadline,'Writer started'); time.sleep(.05)
            download=pool.submit(pull,f); capture=begin(f); downloaded=download.result(); writer.result()
        require(capture['at']['revision']==2 and downloaded['result']['through']['revision']==2,'Readers wait for complete commit')
        require(page(f,capture)['history'][-1]['status']==downloaded['result']['groups'][-1]['history'][0]['status'], 'Consistent status/history lock')
        check('concurrent late status commit is atomic in pull and snapshot with matching watermarks')

        f=TaskFixture(backend,epoch); f.apply(f.create()); rival=uid(); f.register(rival)
        a=f.set_status(2,status('completed',10))
        b=f.set_status(1,status('in_progress')); b['device_epoch']=rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes=list(pool.map(f.apply,(a,b)))
        dispositions=[r['result']['results'][0]['disposition'] for r in outcomes]
        require(sorted(dispositions)==['applied','conflict'],'One concurrent status winner')
        winner=a if dispositions[0]=='applied' else b
        history=page(f,begin(f))['history']
        require(len(history)==2 and history[-1]['operation']==winner,'Only winning transition becomes history')
        result=pull(f)['result']
        require(sum(len(g['history']) for g in result['groups'])==2 and any(g['recovery'] for g in result['groups']),
                'Losing candidate remains recovery without fabricated history')
        check('competing device status changes retain one historical winner and the losing recovery candidate')

        f=TaskFixture(backend,epoch); f.apply(f.create())
        for start in range(2,207,32):
            ops=[]
            for seq in range(start,min(start+32,207)):
                prior=status() if seq%2==0 else status('completed',seq-1)
                target=status('completed',seq) if seq%2==0 else status()
                ops.append(f.set_status(seq,target,observed(seq-1,prior)))
            f.apply(*ops)
        capture=begin(f); pages=[page(f,capture,i) for i in reversed(range(capture['page_count']))]
        events=[e for p in pages for e in p['history']]
        require(capture['record_count']==207 and capture['page_count']==2 and len(events)==206
                and len({e['operation_id'] for e in events})==206 and all(len(p['history'])<=200 for p in pages),'History count paging')
        require(page(f,capture)==pages[-1],'Interrupted/repeated page stable')
        after=0; pulled=[]
        while True:
            result=pull(f,after,17)['result']; pulled.extend(e for g in result['groups'] for e in g['history'])
            after=result['through']['revision']
            if not result['has_more']: break
        require(len(pulled)==206 and {e['operation_id'] for e in pulled}=={e['operation_id'] for e in events},'Whole incremental groups match snapshot')
        check('206 events, reverse/interrupted snapshot pages and whole-revision incremental pagination')

        # Large accepted description is copied into each historical state; pages
        # and pull groups must account for that content, not just current shadows.
        f=TaskFixture(backend,epoch); create=f.create()
        create['patches']['description']={'base':{'kind':'absent'},'value':'x'*50000}; f.apply(create)
        for start in range(2,72,10):
            f.apply(*(f.set_status(seq,status('completed',seq) if seq%2==0 else status(),
                      observed(seq-1,status() if seq%2==0 else status('completed',seq-1))) for seq in range(start,min(start+10,72))))
        capture=begin(f); pages=[page(f,capture,i) for i in range(capture['page_count'])]
        require(capture['page_count']>=2 and sum(len(p['history']) for p in pages)==71,'History byte paging')
        result=pull(f)['result']
        require(result['has_more'] and 0<result['through']['revision']<71,'Pull cap includes history')
        require(all(len(json.dumps(p).encode())<4194304 for p in pages),'Reply byte cap')
        require(sum(len(g['history']) for g in result['groups'])+sum(len(g['history']) for g in pull(f,result['through']['revision'])['result']['groups'])==71,'No skipped byte-limited event')
        check('large retained fields count toward snapshot and whole-group pull byte limits')

        other=TaskFixture(backend,epoch)
        require(pull(other)['result']['groups']==[],'X/Y history isolation')
        require(rpc(other,'snapshot_page',request(other,token=capture['token'],page=0))['code']=='snapshotExpired','Foreign capture denied')
        for name,q in [('pull',dict(protocol_version=2,history_version=1,after=dict(server_epoch=epoch,revision=0),limit=200)),
                       ('snapshot_begin',request(f)),('snapshot_page',request(f,token=capture['token'],page=0))]:
            for v in (0,2,None,True,'1'):
                require(backend.rpc(name,f.token,dict(q,history_version=v))['code']=='unsupportedProtocol','Unsupported extension refused')
            code,_=backend.request('POST','/rest/v1/rpc/sync_'+name,None,{'request':q})
            require(code in (401,403),'Anonymous denied')
        for token in (None,f.token,other.token):
            for method in ('GET','POST','PATCH','DELETE'):
                code,_=backend.request(method,'/rest/v1/task_status_history',token,None if method=='GET' else {})
                require(code in (401,403,404),'Raw history access denied')
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    f"select count(*) from sync_private.task_status_history where owner_id='{f.owner}'; rollback;").splitlines()[-1]=='0','History RLS')
        check('history negotiation failures, cross-owner tokens/rows and anonymous/raw REST denial')

        sql(f"update sync_private.account_state set revoked_at=clock_timestamp() where owner_id='{f.owner}';")
        require(pull(f)['code']=='accountDeleted' and rpc(f,'snapshot_page',request(f,token=capture['token'],page=0))['code']=='accountDeleted','Revocation')
        sql(f"update sync_private.account_state set revoked_at=null where owner_id='{f.owner}';")
        backend.request('DELETE','/auth/v1/admin/users/'+f.owner,backend.admin)
        require(pull(f)['code']=='accountDeleted' and rpc(f,'snapshot_begin',request(f))['code']=='accountDeleted','Auth-deleted stale JWT')
        check('revoked and auth-deleted accounts cannot read retained historical payloads')

        f=TaskFixture(backend,epoch); f.apply(f.create()); capture=begin(f)
        sql(f"update sync_private.snapshots set expires_at=clock_timestamp()-interval '1 second' where owner_id='{f.owner}';")
        require(rpc(f,'snapshot_page',request(f,token=capture['token'],page=0))['code']=='snapshotExpired','Expiry')
        fresh=begin(f); require(fresh['token']!=capture['token'] and fresh['record_count']==2,'Fresh bootstrap retains full history')
        old=legacy_begin(f); f.apply(f.set_status(2,status('completed',9))); newest=begin(f)
        f.apply(f.set_status(3,status(),observed(2,status('completed',9))))
        require(rpc(f,'snapshot_begin',request(f))['code']=='rateLimited','Shared legacy/history quota')
        require(page(f,fresh)['history'][0]['revision']==1 and legacy_page(f,old)['records'],'Quota preserves all versions')
        check('expired history tokens restart capture only; legacy and history share quota without eviction')

        f=TaskFixture(backend,epoch); f.apply(f.create()); before=f.state(),f.history()
        sql("create function sync_private.test_history_fail() returns trigger language plpgsql as $$ begin "
            "if jsonb_array_length(new.history)>0 then raise exception 'Injected history failure'; end if; return new; end $$; "
            "create trigger test_history_fail before insert on sync_private.snapshot_pages for each row execute function sync_private.test_history_fail();")
        try:
            code,_=backend.request('POST','/rest/v1/rpc/sync_snapshot_begin',f.token,{'request':request(f)})
            require(code==400 and stored(f)=='0,0' and (f.state(),f.history())==before,'History-page atomic rollback')
        finally:
            sql('drop trigger test_history_fail on sync_private.snapshot_pages; drop function sync_private.test_history_fail();')
        require(begin(f)['record_count']==2,'Retry after failed capture')
        check('injected historical-page failure preserves data and leaves no partial capture')
        print(f'{passed} history integration groups passed.')
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True,exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire),encoding='utf-8')


if __name__=='__main__': main()

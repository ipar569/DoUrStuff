"""Compound create/copy recovery against the guarded local stack; synthetic data only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import time

from test_backend_foundation import Backend, literal, require, sql
from test_backend_apply import uid, predecessor, observed
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_milestone_create import milestone
from test_backend_tag_commands import tag, name
from test_backend_saved_views import view
from test_backend_memberships import membership
from test_backend_resolution import candidates, rows, state, begin, page, pull
from test_backend_retention import age as age_logs, prune as prune_logs, apply, wait_for_sleep
from test_backend_resolved_content import age as age_content, prune as prune_content

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20261101020241_compound_recovery.sql'


def fields(f, entity):
    result = sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                 f"select coalesce(sync_private.recovery_fields({literal(json.dumps(entity))}::jsonb),'null'); rollback;")
    return json.loads(result.splitlines()[1])


def request(f, original, replacement, choice='create', held=()):
    roots = [c for c in candidates(f) if c and c['operation']['operation_id'] == original['operation_id']]
    return dict(protocol_version=2, resolution_version=2,
                cursor=dict(server_epoch=f.epoch, revision=int(sql(f"select revision from sync_private.account_state where owner_id='{f.owner}';"))),
                operation_id=replacement['operation_id'], device_epoch=replacement['device_epoch'], sequence=replacement['sequence'],
                source_operation_id=original['operation_id'], source_entity=deepcopy(original['entity']),
                conflicts=[dict(id=c['id'], revision=c['revision']) for c in roots],
                observed_fields=fields(f, original['entity']), choice=choice, replacement=replacement,
                held_choices=[dict(id=c['id'], revision=c['revision'], choice=decision) for c, decision in held])


def resolve(f, q):
    return f.backend.rpc('resolve_create', f.token, q)


def rejected(backend, epoch):
    f = TaskFixture(backend, epoch)
    original = f.create(title='')
    require(f.apply(original)['result']['results'][0]['disposition'] == 'rejected', 'Rejected original create')
    return f, original


def all_state(f):
    return state(f), rows(f, 'change_log'), rows(f, 'task_status_history'), rows(f, 'milestone_shadow'), rows(f, 'tag_shadow'), rows(f, 'view_shadow')


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
            f, original = rejected(backend, epoch)
            q = request(f, original, f.create(2, title='Repaired'))
            capture = begin(f); frozen = page(f, capture); before = all_state(f)
            source = ('begin;\n' + MIGRATION.read_text(encoding='utf-8') +
                      f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                      f"select public.sync_resolve_create({literal(json.dumps(q))}::jsonb); rollback;")
            result = json.loads(sql(source).splitlines()[1])
            require(result['status'] == 'success' and len(result['result']['resolutions']) == 4, 'Candidate compound create')
            require(all_state(f) == before and page(f, capture) == frozen, 'Exact rollback')
            backend.wire.append(dict(rpc='resolve_create', request=q, reply=result))
            check('forward migration plus four-field create/closures rolls back without changing retained data')
            return

        f, original = rejected(backend, epoch); originals = candidates(f)
        old_receipt = f.apply(original); capture = begin(f); frozen = page(f, capture)
        replacement = f.create(2, title='Repaired')
        replacement['patches'].update(description=dict(base={'kind':'absent'}, value='chosen full content'),
                                      estimate_minutes=dict(base={'kind':'absent'}, value=30))
        q = request(f, original, replacement)
        reply = resolve(f, q)
        require(reply['status'] == 'success' and len(reply['result']['resolutions']) == 4, 'All original groups closed')
        require(f.fields()['description']['value'] == 'chosen full content' and f.fields()['estimate_minutes']['value'] == 30,
                'Complete new entity installed')
        require(candidates(f) == originals and
                f.apply(original)['result']['results'] == old_receipt['result']['results'],
                'Original candidates and retry outcome immutable')
        require(page(f, capture) == frozen, 'Frozen originals survive')
        group = pull(f, 1)['result']['groups'][0]
        require(len(group['records']) == 1 and len(group['resolutions']) == 4, 'One atomic create/closure revision')
        require(page(f, begin(f))['resolutions'] == sorted(reply['result']['resolutions'], key=lambda r:r['conflict_id']), 'New snapshot closure facts')
        before = all_state(f)
        require(resolve(f, q) == reply and all_state(f) == before, 'Lost-response create retry')
        check('absent task compound repair, complete payload, immutable originals/retries and frozen/atomic downloads')

        f = TaskFixture(backend, epoch); original = f.create(2, title='Copied content')
        child = f.op(3, 'held child', predecessor(original, 'Copied content'))
        grandchild = f.op(4, 'held grandchild', predecessor(child, 'held child'))
        f.apply(f.create(), original, child, grandchild)
        cs = candidates(f); held = [c for c in cs if c['operation']['operation_id'] in (child['operation_id'], grandchild['operation_id'])]
        target = uid(); copied = f.create(5, task=target, title='Copied content')
        q = request(f, original, copied, 'copyAsNew', [(held[0],'keepHeld'),(held[1],'discard')])
        source_fields = f.fields(); originals = candidates(f); old = begin(f); frozen = page(f, old)
        reply = resolve(f, q)
        require(reply['status'] == 'success' and reply['result']['mapping'] == dict(source_operation_id=original['operation_id'],
                source_entity=original['entity'], created_entity=copied['entity']), 'Explicit immutable mapping')
        require(f.fields() == source_fields and fields(f,copied['entity'])['title']['value'] == 'Copied content', 'Source unchanged, separate target')
        require(candidates(f) == originals and len(reply['result']['resolutions']) == 5 and page(f,old) == frozen, 'Explicit root and held closure choices')
        late = f.op(6, 'late held', predecessor(original, 'Copied content'))
        require(f.apply(late)['result']['results'][0]['disposition'] == 'held', 'Original UUID/dependency never aliases copy')
        check('colliding task copied to distinct UUID with exact held choices and no automatic reference redirect')

        # Name collision roots have no source shadow; the user must select a
        # noncolliding complete value. No alias to the already-existing tag.
        f = TaskFixture(backend, epoch); first = tag(f,1); original = tag(f,2,name('WORK'))
        f.apply(first,original)
        bad = deepcopy(original); bad['operation_id']=uid(); bad['sequence']=3
        q = request(f,original,bad); before=all_state(f)
        require(resolve(f,q)['code']=='replacementRejected' and all_state(f)==before,'Invalid repaired name rolls back')
        fixed = deepcopy(bad); fixed['patches']['name']['value']=name('Repaired')
        q=request(f,original,fixed); require(resolve(f,q)['status']=='success','Complete tag create repair')
        require(fields(f,first['entity'])['name']['value']==first['patches']['name']['value'],'No existing tag alias')
        check('all-or-nothing tag collision repair preserves original UUID and competing tag')

        f=TaskFixture(backend,epoch); parent=f.create(2,title='conflicting parent')
        original=milestone(f,3,dependency=parent); child=f.op(4,'child',predecessor(original,'Step'))
        child['entity']=original['entity']; child['command']='milestone.edit'
        f.apply(f.create(),parent,original,child)
        held=[c for c in candidates(f) if c['operation']['operation_id']==child['operation_id']]
        fixed=milestone(f,5,identity=original['entity']['key'][0])
        q=request(f,original,fixed,held=[(c,'keepHeld') for c in held])
        require(resolve(f,q)['status']=='success' and fields(f,fixed['entity'])['parent']['value']==f.task,'Explicit milestone parent choice')
        require(all(c in candidates(f) for c in held),'Held child original retained')
        # Saved-view all-group repair uses its complete canonical query.
        f=TaskFixture(backend,epoch); original=view(f,1); original['patches']['name']['value']=''
        f.apply(original); fixed=view(f,2); fixed['entity']=original['entity']
        require(resolve(f,request(f,original,fixed))['status']=='success','Saved view compound repair')
        check('held milestone create with explicit parent and complete saved-view create repair')

        f=TaskFixture(backend,epoch); original=f.op(3,'meaningful late edit')
        f.apply(f.create(),deletion(f),original)
        bad=f.create(4); before=all_state(f)
        require(resolve(f,request(f,original,bad))['code']=='replacementRejected' and all_state(f)==before,'Cannot revive deleted UUID')
        copied=f.create(4,task=uid(),title='Recovered late edit')
        require(resolve(f,request(f,original,copied,'copyAsNew'))['status']=='success','Explicit deleted-content copy')
        require(f.fields()['existence']['value'] is False,'Source tombstone remains')
        check('late-edit copy creates a separate entity while original deletion identity remains authoritative')

        f,original=rejected(backend,epoch); replacement=f.create(2); q=request(f,original,replacement); before=all_state(f)
        missing=deepcopy(q); missing['conflicts'].pop()
        require(resolve(f,missing)['code']=='recoveryChanged' and all_state(f)==before,'No partial root closure')
        changed=deepcopy(q); changed['conflicts'][0]['revision']=0
        code,_=backend.request('POST','/rest/v1/rpc/sync_resolve_create',f.token,{'request':changed})
        require(code==400,'Malformed expected revision')
        f.apply(f.create(2,title='New canonical'))
        stale=deepcopy(q); stale['sequence']=3; stale['replacement']['sequence']=3
        require(resolve(f,stale)['code']=='recoveryChanged','Source preview invalidated')
        # Destination race must roll back, even if its values match the request.
        f,original=rejected(backend,epoch); destination=f.create(2,task=uid())
        q=request(f,original,dict(deepcopy(destination),operation_id=uid(),sequence=3),'copyAsNew')
        f.apply(destination); q['cursor']['revision']=2; before=all_state(f)
        require(resolve(f,q)['code']=='replacementRejected' and all_state(f)==before,'Occupied copy destination')
        check('missing groups, stale source previews and occupied destinations consume no sequence or closure')

        f=TaskFixture(backend,epoch); original=f.create(2); child=f.op(3,'held',predecessor(original,'X'))
        f.apply(f.create(),original,child)
        cs=[c for c in candidates(f) if c['operation']['operation_id']==child['operation_id']]
        q=request(f,original,f.create(4,task=uid()),'copyAsNew',[(c,'keepHeld') for c in cs])
        late=f.op(4,'late',predecessor(child,'held')); f.apply(late)
        q['sequence']=5; q['replacement']['sequence']=5; q['cursor']['revision']=4; before=all_state(f)
        require(resolve(f,q)['code']=='recoveryChanged' and all_state(f)==before,'New descendant invalidates exact held preview')
        check('new transitive held arrival invalidates the complete preview without releasing work')

        f,original=rejected(backend,epoch); q=request(f,original,f.create(2)); reply=resolve(f,q)
        age_content(f); prune_content(f); age_logs(f); prune_logs(f)
        q['cursor']['revision']=int(sql(f"select revision from sync_private.account_state where owner_id='{f.owner}';"))
        before=all_state(f)
        require(resolve(f,q)==reply and apply(f,original)['result']['results'][0]['kind']=='already_processed','Retry proofs outlive all payloads')
        for key in ('choice','source_operation_id','observed_fields','held_choices'):
            changed=deepcopy(q)
            if key=='choice': changed[key]='copyAsNew'
            elif key=='source_operation_id': changed[key]=uid()
            elif key=='observed_fields': changed[key]={}
            else: changed[key]=[dict(id=uid(),revision=1,choice='discard')]
            require(resolve(f,changed)['code']=='payloadMismatch','Permanent full decision hash')
        refreshed=deepcopy(q); refreshed['cursor']['server_epoch']=uid()
        result=sql(f"begin; update sync_private.backend_state set server_epoch='{refreshed['cursor']['server_epoch']}'; "
                   f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                   f"select public.sync_resolve_create({literal(json.dumps(refreshed))}::jsonb); rollback;")
        actual=json.loads(result.splitlines()[1]); expected=deepcopy(reply)
        expected['result']['cursor']['server_epoch']=refreshed['cursor']['server_epoch']
        require(actual==expected and all_state(f)==before,'Compacted decision uses current epoch and original mapping')
        backend.wire.append(dict(rpc='resolve_create',request=refreshed,reply=actual))
        check('90/180-day compaction retains original retry identities, exact mapping and current-epoch decision replay')

        f,original=rejected(backend,epoch); q=request(f,original,f.create(2)); before=all_state(f)
        try:
            sql("begin; create function sync_private.test_compound_fail() returns trigger language plpgsql as $$ begin "
                "raise exception 'Injected failure'; end $$; create trigger test_compound_fail before insert "
                "on sync_private.resolution_requests for each row execute function sync_private.test_compound_fail(); "
                f"set local role authenticated; select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                f"select public.sync_resolve_create({literal(json.dumps(q))}::jsonb); commit;")
            raise AssertionError('Late fault did not trigger')
        except RuntimeError:
            pass
        require(all_state(f)==before,'Full atomic rollback')
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies=list(pool.map(lambda _:resolve(f,q),range(2)))
        require(replies[0]==replies[1] and len(json.loads(rows(f,'resolution_requests')))==1,'One logical concurrent create')
        check('injected late decision-write failure rolls back create/history/identity/closures; simultaneous retry is idempotent')

        f,original=rejected(backend,epoch); q=request(f,original,f.create(2)); label=uid()
        with ThreadPoolExecutor(max_workers=3) as pool:
            first=pool.submit(sql,f"begin; set local application_name='{label}'; set local role authenticated; "
                f"select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
                f"select public.sync_resolve_create({literal(json.dumps(q))}::jsonb); select pg_sleep(1.5); commit;")
            wait_for_sleep(label); download=pool.submit(pull,f); capture=pool.submit(begin,f)
            time.sleep(.1); require(not download.done() and not capture.done(),'Download waits for account lock')
            first.result(); groups=download.result()['result']['groups']; manifest=capture.result()
        require(len(groups[-1]['records'])==1 and len(groups[-1]['resolutions'])==4 and len(page(f,manifest)['resolutions'])==4,'Complete committed capture/pull')
        check('late create commit serializes pull and frozen capture with every group closure')

        x,original=rejected(backend,epoch); y,_=rejected(backend,epoch)
        q=request(x,original,x.create(2)); before_x=all_state(x); before_y=all_state(y)
        require(backend.rpc('resolve_create',y.token,q)['code']=='unavailable','Foreign device rejected')
        qy=deepcopy(q); qy['device_epoch']=y.device; qy['replacement']['device_epoch']=y.device
        require(backend.rpc('resolve_create',y.token,qy)['code']=='recoveryChanged','Foreign recovery invisible')
        code,_=backend.request('POST','/rest/v1/rpc/sync_resolve_create',None,{'request':q})
        require(code in (401,403),'Anonymous denied')
        require(all_state(x)==before_x and all_state(y)==before_y,'Ownership failures write nothing')
        for version in (None,1,3,'2'):
            changed=deepcopy(q); changed['resolution_version']=version
            require(resolve(x,changed)['code']=='unsupportedProtocol','Strict negotiated version')
        for mutate in ('duplicate','nonabsent','dependencies','wrongkind'):
            changed=deepcopy(q)
            if mutate=='duplicate': changed['conflicts'].append(changed['conflicts'][0])
            elif mutate=='nonabsent': changed['replacement']['patches']['title']['base']=observed(1,'X')
            elif mutate=='dependencies': changed['replacement']['dependencies']=[{}]
            else: changed['replacement']['command']='tag.create'
            code,_=backend.request('POST','/rest/v1/rpc/sync_resolve_create',x.token,{'request':changed})
            require(code==400,'Malformed create recovery')
        require(all_state(x)==before_x,'Malformed preflight writes nothing')
        check('anonymous/X/Y denial, strict negotiation and malformed compound preflight preserve all state')
        print(f'{passed} compound recovery integration groups passed.',flush=True)
    finally:
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire,ensure_ascii=False),encoding='utf-8')
        backend.cleanup()


if __name__=='__main__':
    main()

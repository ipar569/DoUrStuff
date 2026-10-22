"""Real local task deletion; retained originals, visibility and atomic progress."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, require, sql
from test_backend_task_create import TaskFixture, status


def deletion(f, seq=2, base=None):
    op = f.op(seq, False, base or observed(1, True), group="existence")
    op["command"] = "task.delete"
    return op


def ledger(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by revision),'[]') "
                         f"from sync_private.task_deletions t where owner_id='{f.owner}';"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--supabase", default="supabase")
    parser.add_argument("--wire-output", type=Path)
    args = parser.parse_args()
    subprocess.run(["python", str(Path(__file__).with_name("local_backend.py"))], check=True)
    backend = Backend(args.supabase)
    epoch = sql("select server_epoch from sync_private.backend_state;")
    passed = 0

    def passed_check(label):
        nonlocal passed
        passed += 1
        print("PASS: " + label, flush=True)

    try:
        for delete_first in (True, False):
            f = TaskFixture(backend, epoch)
            f.apply(f.create(initial=status("completed", 50)))
            second = uid()
            f.register(second)
            remove, edit = deletion(f), f.op(1, "Offline edit")
            edit["device_epoch"] = second
            for op in ((remove, edit) if delete_first else (edit, remove)):
                f.apply(op)
            fields = f.fields()
            require(fields["existence"]["value"] is False, "Deletion dominates visibility")
            require(fields["title"]["value"] == ("X" if delete_first else "Offline edit"), "Latest content retained")
            require(len(f.history()) == 1, "Deletion does not invent a status transition")
            rows = ledger(f)
            require(len(rows) == 1 and rows[0]["operation"] == remove and rows[0]["deleted_at"], "Original deletion and server time retained")
            groups = f.pull()["groups"]
            removed = [g for g in groups if g["revision"] == rows[0]["revision"]][0]
            require(removed["records"][0]["delete_operation_id"] == remove["operation_id"], "Pull carries exact deletion identity")
            if delete_first:
                require(groups[-1]["recovery"][0]["operation"] == edit, "Late edit retains immutable original base")
        passed_check("delete/edit both arrival orders preserve content, original edits and deletion identity")

        f = TaskFixture(backend, epoch)
        create = f.create()
        remove = deletion(f, base=predecessor(create, True))
        result = f.apply(create, remove)
        require([r["disposition"] for r in result["result"]["results"]] == ["applied", "applied"], "Atomic create/delete predecessor chain")
        before = f.state(), ledger(f)
        require(f.apply(create, remove) == result and (f.state(), ledger(f)) == before, "Lost response retry unchanged")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; "
            f"delete from sync_private.change_log where owner_id='{f.owner}';")
        before = f.state(), ledger(f)
        require(f.apply(remove)["result"]["results"][0]["kind"] == "already_processed", "Expired receipt cannot replay")
        reused = deletion(f, 3)
        reused["operation_id"] = remove["operation_id"]
        require(f.apply(reused)["code"] == "payloadMismatch" and (f.state(), ledger(f)) == before, "Deletion identity survives receipt/log expiry")
        f.apply(f.create(3))
        require(f.fields()["existence"]["value"] is False and len(ledger(f)) == 1, "Same UUID cannot recreate deleted task")
        passed_check("create/delete chain, immutable retries, expiry and deleted identity reuse")

        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        second = uid()
        f.register(second)
        a, b = deletion(f), deletion(f, 1)
        b["device_epoch"] = second
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda op: f.apply(op)["result"]["results"][0], [a, b]))
        require(sorted(r["disposition"] for r in replies) == ["applied", "conflict"], "Concurrent deletion has one winner")
        require(len(ledger(f)) == 1, "Competing delete cannot replace the winning identity")
        losing = a if replies[0]["disposition"] == "conflict" else b
        require(f.pull()["groups"][-1]["recovery"][0]["operation"] == losing, "Losing deletion original retained")
        passed_check("simultaneous deletion keeps one identity and recovers the competing original")

        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        invalids = [deletion(f, n) for n in range(2, 6)]
        invalids[0]["patches"]["existence"]["value"] = True
        invalids[1]["patches"]["existence"]["base"] = {"kind": "absent"}
        invalids[2]["patches"]["existence"]["base"] = observed(1, False)
        invalids[3]["patches"]["title"] = {"base": observed(1, "X"), "value": "Smuggled"}
        replies = f.apply(*invalids)["result"]["results"]
        require(all(r["rejection_code"] == "invalid_delete_command" for r in replies), "Only existence true-to-false delete accepted")
        require(f.fields()["title"]["value"] == "X" and f.fields()["existence"]["value"] is True and not ledger(f), "Invalid delete has no partial effect")
        corrupt = deletion(f, 6, observed(99, True))
        require(f.apply(corrupt)["result"]["results"][0]["disposition"] == "conflict", "Stale existence does not delete")
        held = deletion(f, 7, predecessor(corrupt, True))
        require(f.apply(held)["result"]["results"][0]["disposition"] == "held", "Conflicted predecessor holds deletion")
        missing = deletion(f, 8, observed(1, True))
        missing["entity"]["key"] = [uid()]
        require(f.apply(missing)["result"]["results"][0]["rejection_code"] == "entity_missing", "Missing task rejected")
        before = f.state(), ledger(f)
        restore = deletion(f, 9)
        restore["command"] = "task.restore"
        require(f.apply(restore)["code"] == "unsupportedProtocol" and (f.state(), ledger(f)) == before, "Restore remains capability gated")
        passed_check("invalid/stale/held/missing deletion and restore gating")

        f.apply(deletion(f, 9))
        require(len(ledger(f)) == 1, "Owned ledger fixture is nonempty before isolation checks")
        other = TaskFixture(backend, epoch)
        foreign = deletion(other, 1)
        foreign["entity"]["key"] = [f.task]
        before = f.state(), ledger(f)
        require(other.apply(foreign)["result"]["results"][0]["rejection_code"] == "entity_missing", "Cross-owner deletion denied")
        require((f.state(), ledger(f)) == before, "Foreign task unchanged")
        for token in (None, f.token, other.token):
            for method, body in (("GET", None), ("POST", {}), ("PATCH", {}), ("DELETE", None)):
                code, _ = backend.request(method, "/rest/v1/task_deletions", token, body)
                require(code in (401, 403, 404), "Deletion ledger has no raw REST bypass")
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    f"select count(*) from sync_private.task_deletions where owner_id='{f.owner}'; rollback;").splitlines() == ["t", "0"], "Ledger RLS hides other account")
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    "do $test$ begin begin insert into sync_private.task_deletions(owner_id,task_id,operation_id,revision,operation) "
                    f"values ('{f.owner}','{f.task}','{uid()}',1,'{{}}'); "
                    "raise exception 'Cross-owner ledger insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;") == "t", "Ledger RLS denies foreign insertion")
        require(sql("select has_table_privilege('dourstuff_rpc','sync_private.task_deletions','update') "
                    "or has_table_privilege('dourstuff_rpc','sync_private.task_deletions','delete');") == "f", "RPC cannot mutate retained deletion originals")
        passed_check("cross-owner deletion and private ledger access isolation")

        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        remove = deletion(f)
        before = f.state(), ledger(f)
        try:
            sql("create function sync_private.fail_delete_test() returns trigger language plpgsql as $$ "
                "begin raise exception 'injected deletion test failure'; end $$; "
                "create trigger fail_delete_test before insert on sync_private.change_log "
                "for each row execute function sync_private.fail_delete_test();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(remove)})
            require(code >= 400 and (f.state(), ledger(f)) == before, "Deletion identity, visibility, receipt and progress roll back together")
        finally:
            sql("drop trigger if exists fail_delete_test on sync_private.change_log; drop function if exists sync_private.fail_delete_test();")
        require(f.apply(remove)["result"]["results"][0]["disposition"] == "applied", "Original envelope succeeds after rollback")
        passed_check("fault injection rolls back every deletion effect")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} task deletion integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

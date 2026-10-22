"""Real local exact-deletion restore, expiry, concurrency and original recovery."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import time

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, DB, require, sql
from test_backend_task_create import TaskFixture, status
from test_backend_task_delete import deletion, ledger


def restore(f, remove, seq=3, revision=2):
    op = f.op(seq, True, observed(revision, False), group="existence")
    op["command"] = "task.restore"
    op["restore"] = {"delete_operation_id": remove["operation_id"], "revision": revision}
    return op


def restores(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by revision),'[]') "
                         f"from sync_private.task_restorations t where owner_id='{f.owner}';"))


def state(f):
    return f.state(), ledger(f), restores(f)


def deleted(backend, epoch):
    f = TaskFixture(backend, epoch)
    remove = deletion(f)
    f.apply(f.create(initial=status("completed", 10)), remove)
    return f, remove


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
        f, remove = deleted(backend, epoch)
        f.apply(f.op(3, "Late edit"))
        original = f.pull()["groups"][-1]["recovery"][0]
        old_fields, old_history, old_deletions = f.fields(), f.history(), ledger(f)
        undo = restore(f, remove, 4)
        result = f.apply(undo)
        require(result["result"]["results"][0]["disposition"] == "applied", "Exact restore applies")
        require(f.fields() == {**old_fields, "existence": {"revision": 4, "value": True}}, "Restore changes visibility only")
        require(f.history() == old_history and ledger(f) == old_deletions, "No invented status transition or rewritten deletion")
        require(restores(f)[0]["operation"] == undo, "Original restore retained")
        groups = f.pull()["groups"]
        require(groups[2]["recovery"][0] == original, "Late candidate remains unresolved after restore")
        require(groups[-1]["records"][0]["delete_operation_id"] == remove["operation_id"], "Visible shadow retains deletion identity")
        before = state(f)
        require(f.apply(undo) == result and state(f) == before, "Lost restore response retry has no effect")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; "
            f"delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(undo)["result"]["results"][0]["kind"] == "already_processed", "Expired receipt cannot replay restore")
        reused = deepcopy(undo)
        reused["sequence"] = 5
        require(f.apply(reused)["code"] == "payloadMismatch" and state(f) == before, "Restore identity survives receipt/log expiry")
        passed_check("visibility-only restore, immutable content/history/recovery, retries and expired identity")

        f, remove = deleted(backend, epoch)
        undo = restore(f, remove)
        f.apply(undo)
        remove_again = deletion(f, 4, observed(3, True))
        f.apply(remove_again)
        before = state(f)
        f.apply(undo)
        require(state(f) == before, "Historical successful retry cannot undo a newer deletion")
        stale = restore(f, remove, 5)
        require(f.apply(stale)["result"]["results"][0]["rejection_code"] == "stale_deletion", "Old undo invalidated by newer delete")
        require(f.fields()["existence"]["value"] is False, "Stale undo leaves hidden state")
        current = restore(f, remove_again, 6, 4)
        require(f.apply(current)["result"]["results"][0]["disposition"] == "applied", "Current exact delete restores")
        require(len(ledger(f)) == 2 and len(restores(f)) == 2, "Every lifecycle identity retained")
        passed_check("delete/restore cycles preserve old identities and reject stale undo")

        f, remove = deleted(backend, epoch)
        second = uid()
        f.register(second)
        a, b = restore(f, remove), restore(f, remove, 1)
        b["device_epoch"] = second
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda op: f.apply(op)["result"]["results"][0], [a, b]))
        require(sorted(r["disposition"] for r in replies) == ["applied", "rejected"] and len(restores(f)) == 1, "Only one competing restore wins")
        for restore_first in (True, False):
            f, remove = deleted(backend, epoch)
            second = uid()
            f.register(second)
            undo, edit = restore(f, remove), f.op(1, "Edited")
            edit["device_epoch"] = second
            for op in ((undo, edit) if restore_first else (edit, undo)):
                f.apply(op)
            require(f.fields()["existence"]["value"] is True and f.fields()["title"]["value"] == ("Edited" if restore_first else "X"), "Restore/edit order preserves visibility and original content rules")
        passed_check("simultaneous restores and both restore/edit arrival orders")

        f, remove = deleted(backend, epoch)
        invalids = [restore(f, remove, n) for n in range(3, 7)]
        invalids[0]["patches"]["title"] = {"base": observed(1, "X"), "value": "Smuggled"}
        invalids[1]["patches"]["existence"]["value"] = False
        invalids[2]["patches"]["existence"]["base"] = predecessor(remove, False)
        invalids[3]["patches"]["existence"]["base"] = observed(1, False)
        require(all(r["rejection_code"] == "invalid_restore_command" for r in f.apply(*invalids)["result"]["results"]), "Restore cannot carry unrelated edits or guessed bases")
        wrong = restore(f, {"operation_id": uid()}, 7)
        require(f.apply(wrong)["result"]["results"][0]["rejection_code"] == "stale_deletion", "Wrong deletion identity rejected")
        before = state(f)
        for change in ("missing", "extra", "bad_revision", "wrong_command"):
            malformed = restore(f, remove, 8)
            if change == "missing": del malformed["restore"]
            elif change == "extra": malformed["restore"]["extra"] = 1
            elif change == "bad_revision": malformed["restore"]["revision"] = 0
            else: malformed["command"] = "task.delete"
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(malformed)})
            require(code == 400 and state(f) == before, "Malformed restore consumes nothing")
        passed_check("semantic rejection and strict restore envelope without partial writes")

        for zone in ("UTC", "America/New_York", "Pacific/Auckland"):
            result = sql(f"begin; set local time zone '{zone}'; "
                "select sync_private.restore_window_open('2026-03-01T12:00Z','2026-03-31T11:59:59.999Z'), "
                "sync_private.restore_window_open('2026-03-01T12:00Z','2026-03-31T12:00Z'), "
                "sync_private.restore_window_open('2026-03-01T12:00Z','2026-03-01T11:59:59Z'); rollback;")
            require(result == "t|f|f", "Exact 720-hour boundary independent of session DST")
        for reason in ("expired", "future", "missing_content", "missing_identity"):
            f, remove = deleted(backend, epoch)
            if reason == "expired":
                sql(f"update sync_private.task_deletions set deleted_at=clock_timestamp()-interval '721 hours' where owner_id='{f.owner}';")
            elif reason == "future":
                sql(f"update sync_private.task_deletions set deleted_at=clock_timestamp()+interval '1 hour' where owner_id='{f.owner}';")
            elif reason == "missing_content":
                sql(f"update sync_private.task_shadow set fields=fields-'title' where owner_id='{f.owner}';")
            else:
                sql(f"delete from sync_private.task_deletions where owner_id='{f.owner}';")
            undo = restore(f, remove)
            undo["provenance"] = {"occurred_at": 9007199254740991}
            expected = "stale_deletion" if reason == "missing_identity" else "restore_content_expired"
            require(f.apply(undo)["result"]["results"][0]["rejection_code"] == expected and not restores(f), "Server time and retained content gate restore")
        passed_check("exact 30-day boundary, future time, missing content and missing identity fail closed")

        f, remove = deleted(backend, epoch)
        writer = subprocess.Popen(["docker", "exec", "-i", DB, "psql", "-XqAt", "-U", "postgres",
                                   "-d", "postgres", "-v", "ON_ERROR_STOP=1"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8")
        pool = ThreadPoolExecutor(max_workers=1)
        try:
            writer.stdin.write(f"begin; update sync_private.account_state set revision=revision where owner_id='{f.owner}';\n\\echo LOCKED\n")
            writer.stdin.flush()
            require(writer.stdout.readline().strip() == "LOCKED", "Account lock held before restore")
            future = pool.submit(f.apply, restore(f, remove))
            deadline = time.monotonic() + 10
            while sql("select count(*) from pg_stat_activity where wait_event_type='Lock' and query like '%sync_apply%';") == "0":
                require(time.monotonic() < deadline, "Restore waits for account lock")
                time.sleep(0.1)
            require(not future.done(), "Restore cannot bypass uncommitted account work")
            # Its cutoff is after the waiting RPC transaction started, but before
            # the lock is released. transaction_timestamp() would admit it.
            writer.stdin.write(f"update sync_private.task_deletions set deleted_at=clock_timestamp()-interval '720 hours' where owner_id='{f.owner}'; commit;\n\\q\n")
            writer.stdin.flush()
            writer.wait(timeout=10)
            require(writer.returncode == 0, "Expiry fixture commits")
            require(future.result(timeout=15)["result"]["results"][0]["rejection_code"] == "restore_content_expired", "Expiry evaluated after account lock using current server time")
        finally:
            if writer.poll() is None:
                writer.stdin.write("rollback;\n\\q\n")
                writer.stdin.flush()
                writer.wait(timeout=10)
            pool.shutdown(wait=True, cancel_futures=True)
        passed_check("restore waiting on a real account lock cannot use a stale transaction-start time")

        f, remove = deleted(backend, epoch)
        f.apply(restore(f, remove))
        other = TaskFixture(backend, epoch)
        foreign = restore(other, remove, 1)
        foreign["entity"]["key"] = [f.task]
        before = state(f)
        require(other.apply(foreign)["result"]["results"][0]["rejection_code"] == "entity_missing" and state(f) == before, "Foreign restore denied")
        for token in (None, f.token, other.token):
            for method, body in (("GET", None), ("POST", {}), ("PATCH", {}), ("DELETE", None)):
                code, _ = backend.request(method, "/rest/v1/task_restorations", token, body)
                require(code in (401, 403, 404), "Restoration ledger has no REST bypass")
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
                    f"select count(*) from sync_private.task_restorations where owner_id='{f.owner}'; "
                    "do $test$ begin begin insert into sync_private.task_restorations(owner_id,task_id,operation_id,deletion_operation_id,revision,operation) "
                    f"values ('{f.owner}','{f.task}','{uid()}','{remove['operation_id']}',1,'{{}}'); "
                    "raise exception 'Foreign restore ledger insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;").splitlines() == ["t", "0"], "Ledger read/write ownership enforced by RLS")
        require(sql("select has_table_privilege('dourstuff_rpc','sync_private.task_restorations','update') "
                    "or has_table_privilege('dourstuff_rpc','sync_private.task_restorations','delete') "
                    "or has_function_privilege('authenticated','sync_private.restore_window_open(timestamptz,timestamptz)','execute') "
                    "or has_function_privilege('anon','sync_private.restore_window_open(timestamptz,timestamptz)','execute');") == "f", "Ledger immutable and window helper private")
        passed_check("X/Y restore isolation and private immutable restoration ledger")

        f, remove = deleted(backend, epoch)
        undo = restore(f, remove)
        before = state(f)
        try:
            sql("create function sync_private.fail_restore_test() returns trigger language plpgsql as $$ "
                "begin raise exception 'injected restore test failure'; end $$; "
                "create trigger fail_restore_test before insert on sync_private.change_log "
                "for each row execute function sync_private.fail_restore_test();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(undo)})
            require(code >= 400 and state(f) == before, "Restore visibility/ledger/receipts/progress roll back")
        finally:
            sql("drop trigger if exists fail_restore_test on sync_private.change_log; drop function if exists sync_private.fail_restore_test();")
        require(f.apply(undo)["result"]["results"][0]["disposition"] == "applied", "Immutable retry succeeds after rollback")
        passed_check("transaction fault rolls back every restoration effect")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} task restore integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

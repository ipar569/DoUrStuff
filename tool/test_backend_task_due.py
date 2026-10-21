"""Atomic due groups through real local Auth/HTTP/PostgreSQL, never guest upload."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture, status


NONE = {"kind": "none"}
DAY = {"kind": "date", "date": "2026-10-20"}
GAP = {"kind": "timed", "wall_time": "2026-09-27T02:30",
       "zone": "Pacific/Auckland", "instant": 1790433000000}


def with_due(op, due):
    op["patches"]["due"] = {"base": {"kind": "absent"}, "value": due}
    return op


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--supabase", default="supabase")
    parser.add_argument("--fixtures", type=Path, required=True)
    parser.add_argument("--wire-output", type=Path)
    args = parser.parse_args()
    subprocess.run(["python", str(Path(__file__).with_name("local_backend.py"))], check=True)
    fixtures = json.loads(args.fixtures.read_text(encoding="utf-8"))
    backend = Backend(args.supabase)
    epoch = sql("select server_epoch from sync_private.backend_state;")
    passed = 0

    def passed_check(label):
        nonlocal passed
        passed += 1
        print("PASS: " + label, flush=True)

    try:
        f = TaskFixture(backend, epoch)
        cases = fixtures["cases"]
        # Exercise the client's pinned zone vocabulary plus canonical shapes,
        # DST gaps/folds and invalid tuples through the actual RPC validator.
        for start in range(0, len(cases), 32):
            batch = cases[start:start + 32]
            ops = [with_due(f.create(start + i + 1, task=uid()), case["value"])
                   for i, case in enumerate(batch)]
            receipts = f.apply(*ops)["result"]["results"]
            for case, receipt in zip(batch, receipts):
                require(receipt["disposition"] == ("applied" if case["valid"] else "rejected"),
                        "Due parity: " + case["label"])
                if not case["valid"]:
                    require(receipt["rejection_code"] == "invalid_due", "Typed due rejection")
        valid_count = sum(c["valid"] for c in cases)
        require(sql(f"select count(*) from sync_private.task_shadow where owner_id='{f.owner}';") == str(valid_count),
                "Invalid due never partially creates core fields")
        require(len(f.history()) == valid_count, "Invalid creation never creates status history")
        # Private validators must not become a bypass API.
        require(sql("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace "
                    "where n.nspname='sync_private' and p.proname in "
                    "('valid_due','valid_civil_date','due_zone_supported') and "
                    "(has_function_privilege('anon',p.oid,'execute') or "
                    "has_function_privilege('authenticated',p.oid,'execute'));") == "0",
                "Validators are private and execute grants restricted")
        passed_check(f"{len(cases)} client/SQL due cases, {len(fixtures['zones'])} zones and atomic invalid creation")

        f = TaskFixture(backend, epoch)
        create = with_due(f.create(), DAY)
        result = f.apply(create)
        before = f.state()
        require(f.apply(create) == result and f.state() == before, "Lost create reply is idempotent")
        collision = with_due(f.create(2), GAP)
        require(f.apply(collision)["result"]["results"][0]["disposition"] == "conflict",
                "Due cannot merge into a colliding create")
        require(f.fields()["due"]["value"] == DAY, "Collision preserves original tuple")
        # Old four-group create is still supported. Absent differs from none.
        old = f.create(3, task=uid())
        f.apply(old)
        require("due" not in f.fields(old["entity"]["key"][0]), "Missing due remains absent")
        first = f.op(4, NONE, {"kind": "absent"}, task=old["entity"]["key"][0], group="due")
        require(f.apply(first)["result"]["results"][0]["disposition"] == "applied", "First explicit none is valid")
        passed_check("optional due creation, collisions, immutable retry and absent/none compatibility")

        for completion_first in (True, False):
            f = TaskFixture(backend, epoch)
            f.apply(with_due(f.create(), DAY))
            second = uid()
            f.register(second)
            completion = f.set_status(2, status("completed", 50))
            due = f.op(1, GAP, observed(1, DAY), group="due")
            due["device_epoch"] = second
            for op in ((completion, due) if completion_first else (due, completion)):
                require(f.apply(op)["result"]["results"][0]["disposition"] == "applied",
                        "Completion and due merge independently")
            require(f.fields()["due"]["value"] == GAP and f.fields()["status_group"]["value"] == status("completed", 50),
                    "Due edit never reopens or rewrites wall/zone/instant")
            require(f.history()[-1]["fields"]["due"]["value"] == (DAY if completion_first else GAP),
                    "Completion history snapshots canonical due at that commit")
        passed_check("due versus completion in both commit orders with immutable history")

        for reverse in (False, True):
            f = TaskFixture(backend, epoch)
            f.apply(with_due(f.create(), NONE))
            second = uid()
            f.register(second)
            a, b = f.op(2, DAY, observed(1, NONE), group="due"), f.op(1, GAP, observed(1, NONE), group="due")
            b["device_epoch"] = second
            ops = [b, a] if reverse else [a, b]
            replies = [f.apply(op)["result"]["results"][0] for op in ops]
            require([r["disposition"] for r in replies] == ["applied", "conflict"], "Same due group conflicts in either order")
            require(f.fields()["due"]["value"] == ops[0]["patches"]["due"]["value"], "Canonical due is one whole tuple")
            recovery = f.pull()["groups"][-1]["recovery"][0]
            require(recovery["operation"] == ops[1] and recovery["canonical"] == f.fields()["due"],
                    "Original none base and competing complete tuple retained")
        f = TaskFixture(backend, epoch)
        f.apply(with_due(f.create(), NONE))
        second = uid()
        f.register(second)
        a, b = f.op(2, DAY, observed(1, NONE), group="due"), f.op(1, GAP, observed(1, NONE), group="due")
        b["device_epoch"] = second
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda op: f.apply(op)["result"]["results"][0], [a, b]))
        require(sorted(r["disposition"] for r in replies) == ["applied", "conflict"], "Real concurrent due race")
        require(f.fields()["due"]["value"] in (DAY, GAP), "No hybrid tuple from concurrent commits")
        passed_check("same-group races in both orders and simultaneous HTTP calls")

        f = TaskFixture(backend, epoch)
        f.apply(with_due(f.create(), NONE))
        accepted = f.op(2, DAY, observed(1, NONE), group="due")
        f.apply(accepted)
        conflict = f.op(3, GAP, observed(1, NONE), group="due")
        conflict["patches"]["priority"] = {"base": observed(1, "none"), "value": "high"}
        held = f.op(4, NONE, predecessor(conflict, GAP), group="due")
        equivalent = f.op(5, DAY, observed(1, NONE), group="due")
        clear = f.op(6, NONE, predecessor(accepted, DAY), group="due")
        receipts = f.apply(conflict, held, equivalent, clear)["result"]["results"]
        require([r["disposition"] for r in receipts] == ["partial", "held", "applied", "applied"], "Conflict/held/equivalent/clear chain")
        require(receipts[2]["fields"][0]["disposition"] == "equivalent", "Equivalent does not fabricate a revision")
        require(f.fields()["due"]["value"] == NONE and f.fields()["priority"]["value"] == "high", "Independent progress and explicit clearing")
        groups = f.pull()["groups"]
        require(groups[2]["recovery"][0]["operation"] == conflict and groups[3]["recovery"][0]["operation"] == held,
                "Original dependent and observed bases retained")
        before = f.state()
        changed = deepcopy(clear)
        changed["patches"]["due"]["value"] = DAY
        require(f.apply(changed)["code"] == "payloadMismatch" and f.state() == before, "Due retry identity immutable")
        corrupt = f.op(7, GAP, observed(6, DAY), group="due")
        require(f.apply(corrupt)["result"]["results"][0]["fields"][0]["disposition"] == "recovery", "Wrong original due at current revision is recovery")
        invalid = f.op(8, {"kind": "none", "date": "2026-10-20"}, observed(6, NONE), group="due")
        invalid["patches"]["title"] = {"base": observed(1, "X"), "value": "not applied"}
        require(f.apply(invalid)["result"]["results"][0]["rejection_code"] == "invalid_due" and f.fields()["title"]["value"] == "X",
                "Invalid due rejects other groups atomically")
        wrong_command = f.op(9, DAY, observed(6, NONE), group="due")
        wrong_command["command"] = "task.status"
        require(f.apply(wrong_command)["result"]["results"][0]["rejection_code"] == "invalid_status_command", "Status command cannot smuggle due")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        before = f.state()
        require(f.apply(clear)["result"]["results"][0]["kind"] == "already_processed" and f.state() == before, "Expired receipt cannot replay due")
        successor = f.op(10, DAY, predecessor(held, NONE), group="due")
        require(f.apply(successor)["result"]["results"][0]["disposition"] == "held", "Retained held due evidence survives receipt expiry")
        passed_check("partial conflicts, held successors, original bases, clearing, rejection and receipt expiry")

        other = TaskFixture(backend, epoch)
        before = f.state()
        op = other.op(1, GAP, {"kind": "absent"}, task=f.task, group="due")
        require(other.apply(op)["result"]["results"][0]["rejection_code"] == "entity_missing", "Foreign due edit denied")
        require(other.pull()["groups"][0]["recovery"][0]["canonical"] is None and f.state() == before, "No cross-owner due disclosure or mutation")
        other.apply(with_due(other.create(2, task=f.task), GAP))
        require(other.fields(f.task)["due"]["value"] == GAP and f.fields()["due"]["value"] == NONE, "Same UUID has isolated due values per account")
        passed_check("X/Y due read/write and same-UUID isolation")

        f = TaskFixture(backend, epoch)
        op = with_due(f.create(initial=status("completed", 100)), GAP)
        before = f.state()
        try:
            sql("create function sync_private.fail_due_test() returns trigger language plpgsql as $$ "
                "begin raise exception 'injected due test failure'; end $$; "
                "create trigger fail_due_test before insert on sync_private.change_log "
                "for each row execute function sync_private.fail_due_test();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(op)})
            require(code >= 400 and f.state() == before, "Due/create/history/receipt/log/watermark rollback together")
        finally:
            sql("drop trigger if exists fail_due_test on sync_private.change_log; "
                "drop function if exists sync_private.fail_due_test();")
        require(f.apply(op)["result"]["results"][0]["disposition"] == "applied", "Same immutable envelope succeeds after rollback")
        passed_check("transaction failure rolls back due, entity, history, receipt and contiguous progress")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} due integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

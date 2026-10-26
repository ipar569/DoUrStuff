"""Core create/status tests against real local HTTP/JWT/PostgreSQL.

No SQL task seeding: every task in this suite is created through sync_apply.
Only synthetic accounts are used, with cleanup even after assertion failures.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import Fixture, observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql


def status(value="todo", completed_at=None):
    return {"status": value, "completed_at": completed_at}


class TaskFixture(Fixture):
    def __init__(self, backend, epoch):
        self.backend, self.epoch = backend, epoch
        self.owner, self.token = backend.create_user()
        self.device, self.task = uid(), uid()
        self.register(self.device)

    def register(self, device):
        self.backend.rpc("register_device", self.token, {"protocol_version": 2,
            "device_epoch": device, "server_epoch": self.epoch})

    def request(self, *ops):
        return {"protocol_version": 2, "server_epoch": self.epoch,
                "after_revision": 0, "operations": list(ops)}

    def create(self, seq=1, task=None, title="X", initial=None):
        op = self.op(seq, title, task=task)
        op["command"] = "task.create"
        op["patches"] = {group: {"base": {"kind": "absent"}, "value": value}
            for group, value in {"title": title, "priority": "none", "existence": True,
                                 "status_group": initial or status()}.items()}
        return op

    def set_status(self, seq, value, base=None):
        op = self.op(seq, value, observed(1, status()) if base is None else base, group="status_group")
        op["command"] = "task.status"
        return op

    def history(self):
        return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(h) order by revision),'[]') "
                             f"from sync_private.task_status_history h where owner_id='{self.owner}';"))

    def pull(self, after=0):
        return super().pull(after)


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
        f = TaskFixture(backend, epoch)
        creation = f.create()
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda _: f.apply(creation), range(2)))
        require(replies[0] == replies[1], "Concurrent identical creates return one receipt")
        require(len(f.pull()["groups"]) == 1 and len(f.history()) == 1, "One creation revision/history event")
        require(set(f.fields()) == set(creation["patches"]), "Every required core group created")
        require(all(field["revision"] == 1 for field in f.fields().values()), "Atomic creation revision")
        before = f.state()
        require(f.apply(creation) == replies[0], "Lost reply retries original create")
        changed = deepcopy(creation)
        changed["patches"]["title"]["value"] = "changed retry"
        require(f.apply(changed)["code"] == "payloadMismatch", "Create payload remains immutable")
        require(f.state() == before, "Retries have no side effects")
        passed_check("HTTP creation, concurrent/lost-response retries and immutable identity")

        collision = f.create(2, title="different")
        collision["patches"]["priority"]["value"] = "high"
        canonical = f.fields()
        receipt = f.apply(collision)["result"]["results"][0]
        require(receipt["disposition"] == "conflict" and
                all(p["disposition"] == "conflict" for p in receipt["fields"]), "Identity collision conflicts every group")
        require(f.fields() == canonical and len(f.history()) == 1, "Collision never merges pieces")
        recovery = f.pull()["groups"][-1]["recovery"]
        require(len(recovery) == 4 and all(c["operation"] == collision for c in recovery), "Original absent bases retained")
        child = f.op(3, "held", predecessor(collision, "different"))
        require(f.apply(child)["result"]["results"][0]["disposition"] == "held", "Edit after colliding create is held")
        # Both absent creators race from distinct registered installations.
        rival = uid()
        f.register(rival)
        task = uid()
        a, b = f.create(4, task=task, title="A"), f.create(1, task=task, title="B")
        b["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            receipts = [r["result"]["results"][0] for r in pool.map(f.apply, (a, b))]
        require(sorted(r["disposition"] for r in receipts) == ["applied", "conflict"], "Exactly one concurrent creator wins")
        winner = a if receipts[0]["disposition"] == "applied" else b
        require(f.fields(task)["title"]["value"] == winner["patches"]["title"]["value"], "Winning identity stays intact")
        passed_check("create collisions, held successors and competing device creates")

        for mutate in (
            lambda op: op["patches"].pop("status_group"),
            lambda op: op["patches"]["existence"].update(value=False),
            lambda op: op["patches"]["title"].update(base=observed(1, "X")),
            lambda op: op["patches"]["title"].update(value=" \t"),
            lambda op: op["patches"]["priority"].update(value="urgent"),
            lambda op: op["patches"]["status_group"].update(value=status("completed")),
        ):
            g = TaskFixture(backend, epoch)
            op = g.create()
            mutate(op)
            receipt = g.apply(op)["result"]["results"][0]
            require(receipt["disposition"] == "rejected", "Invalid create is terminal")
            require(sql(f"select count(*) from sync_private.task_shadow where owner_id='{g.owner}';") == "0",
                    "Invalid create leaves no partial entity")
            require(not g.history(), "Invalid create has no status history")
            require(all(c["operation"] == op for c in g.pull()["groups"][0]["recovery"]), "Rejected originals retained")
            require(g.apply(g.create(2))["result"]["results"][0]["disposition"] == "applied", "Rejection does not block later work")
        passed_check("all-or-nothing invalid creates, repair originals and contiguous progress")

        for completion_first in (True, False):
            g = TaskFixture(backend, epoch)
            g.apply(g.create())
            second = uid()
            g.register(second)
            completion = g.set_status(2, status("completed", 100))
            edit = g.op(1, "edited", observed(1, "X"))
            edit["device_epoch"] = second
            ordered = (completion, edit) if completion_first else (edit, completion)
            for op in ordered:
                require(g.apply(op)["result"]["results"][0]["disposition"] == "applied", "Independent edit/completion applies")
            require(g.fields()["title"]["value"] == "edited" and
                    g.fields()["status_group"]["value"] == status("completed", 100), "Content edit never reopens")
            event = g.history()[-1]
            require(event["fields"]["title"]["value"] == ("X" if completion_first else "edited"), "History captures accepted content at transition")
            require(event["previous_status"]["value"] == status(), "History retains prior status")
            require(event["provenance"] == completion["provenance"], "History preserves device provenance without ordering by it")
        passed_check("completion/edit concurrency in both commit orders with durable completion snapshots")

        g = TaskFixture(backend, epoch)
        create = g.create(initial=status("completed", -100))
        reopen = g.set_status(2, status(), predecessor(create, status("completed", -100)))
        complete = g.set_status(3, status("completed", 0), predecessor(reopen, status()))
        receipts = g.apply(create, reopen, complete)["result"]["results"]
        require([r["disposition"] for r in receipts] == ["applied"] * 3, "Create/status predecessor chain")
        require(len(g.history()) == 3 and g.history()[1]["status"]["value"] == status(), "Reopen clears current time and retains completion")
        cancel = g.set_status(4, status("cancelled"), observed(2, status()))
        dependent = g.set_status(5, status(), predecessor(cancel, status("cancelled")))
        equivalent = g.set_status(6, status("completed", 0), observed(2, status()))
        receipts = g.apply(cancel, dependent, equivalent)["result"]["results"]
        require([r["disposition"] for r in receipts] == ["conflict", "held", "applied"], "Status conflict/held/equivalent")
        require(len(g.history()) == 3, "Conflicts, held and equivalent do not duplicate history")
        groups = g.pull()["groups"]
        require(groups[3]["recovery"][0]["operation"] == cancel and
                groups[4]["recovery"][0]["operation"] == dependent, "Original status bases preserved")
        retained = g.state()
        g.apply(create, reopen, complete)
        require(g.state() == retained, "Retry never duplicates history")
        sql(f"delete from sync_private.operation_receipts where owner_id='{g.owner}';")
        require(g.apply(create)["result"]["results"][0]["kind"] == "already_processed", "Expired create receipt cannot replay")
        require(len(g.history()) == 3, "History survives receipt removal")
        passed_check("status predecessor/conflict/equivalence, reopen history and receipt expiry")

        g = TaskFixture(backend, epoch)
        g.apply(g.create())
        invalid_command = g.set_status(2, status("completed", 1))
        invalid_command["patches"]["title"] = {"base": observed(1, "X"), "value": "must not apply"}
        receipt = g.apply(invalid_command)["result"]["results"][0]
        require(receipt["rejection_code"] == "invalid_status_command" and
                g.fields()["title"]["value"] == "X" and len(g.history()) == 1,
                "Status command rejects unrelated patches atomically")
        complete = g.set_status(3, status("completed", 5))
        g.apply(complete)
        mixed = g.op(4, "independent edit")
        mixed["patches"]["status_group"] = {"base": observed(1, status()), "value": status("cancelled")}
        receipt = g.apply(mixed)["result"]["results"][0]
        require(receipt["disposition"] == "partial" and g.fields()["title"]["value"] == "independent edit",
                "Content applies alongside conflicting complete status group")
        require(g.fields()["status_group"]["value"] == status("completed", 5) and len(g.history()) == 2,
                "Partial edit cannot split status/time or add false history")
        bad_status = g.op(5, "must not apply", observed(4, "independent edit"))
        bad_status["patches"]["status_group"] = {"base": observed(3, status("completed", 5)), "value": status("todo", 5)}
        receipt = g.apply(bad_status)["result"]["results"][0]
        require(receipt["disposition"] == "rejected" and g.fields()["title"]["value"] == "independent edit",
                "Invalid status rejects entire mixed edit")
        before = g.state()
        changed = deepcopy(complete)
        changed["patches"]["status_group"]["value"]["completed_at"] = 6
        require(g.apply(changed)["code"] == "payloadMismatch" and g.state() == before, "Completion retry is immutable")
        supported, unsupported = g.create(6, task=uid()), g.op(7, [], group="milestone_order")
        unsupported["command"] = "view.restore"
        unsupported["entity"]["kind"] = "view"
        unsupported["patches"] = {"name": {"base": {"kind": "absent"}, "value": "View"}}
        require(g.apply(supported, unsupported)["code"] == "unsupportedProtocol" and g.state() == before,
                "Unsupported batch suffix cannot create an earlier task")
        passed_check("status command boundaries, partial content merge and whole-batch capability preflight")

        g = TaskFixture(backend, epoch)
        create = g.create(initial=status("completed", 100))
        g.apply(create)
        noop = g.set_status(2, status("completed", 100), observed(1, status("completed", 100)))
        receipt = g.apply(noop)["result"]["results"][0]
        require(receipt["disposition"] == "applied" and g.fields()["status_group"]["revision"] == 2,
                "Fresh no-op retains accepted field revision semantics")
        require(len(g.history()) == 1, "Same current-base value is not another completion event")
        before = g.state()
        g.apply(noop)
        require(g.state() == before, "No-op retry has no side effects")
        sql(f"delete from sync_private.operation_receipts where owner_id='{g.owner}';")
        before = g.state()
        changed = deepcopy(create)
        changed["patches"]["title"]["value"] = "changed old payload"
        require(g.apply(changed)["code"] == "payloadMismatch" and g.state() == before,
                "Retained authoritative history payload rejects changed old-sequence retries")
        reused = g.op(3, "stolen identity")
        reused["operation_id"] = create["operation_id"]
        require(g.apply(reused)["code"] == "payloadMismatch" and g.state() == before,
                "History identity cannot be reused by a title-only operation after receipt expiry")
        reused = g.set_status(3, status(), observed(2, status("completed", 100)))
        reused["operation_id"] = create["operation_id"]
        require(g.apply(reused)["code"] == "payloadMismatch" and g.state() == before,
                "History identity reuse returns typed failure before history primary-key collision")
        other_device = uid()
        g.register(other_device)
        reused["device_epoch"], reused["sequence"] = other_device, 1
        before = g.state()
        require(g.apply(reused)["code"] == "payloadMismatch" and g.state() == before,
                "Retained operation IDs remain unique across device epochs")
        require(g.apply(create)["result"]["results"][0]["kind"] == "already_processed",
                "Original consumed create can still reconcile after receipt expiry")
        sql(f"update sync_private.task_status_history set operation=null where owner_id='{g.owner}';")
        before = g.state()
        require(g.apply(reused)["code"] == "payloadMismatch" and g.state() == before,
                "Legacy history without an available original payload still prevents identity reuse")
        require(g.apply(create)["result"]["results"][0]["kind"] == "already_processed",
                "Legacy unknown payload allows consumed-sequence reconciliation without replay")
        passed_check("no-op completion history and retained identity protection after receipt expiry")

        g = TaskFixture(backend, epoch)
        op = g.create()
        op["patches"]["status_group"]["value"] = status("completed")
        op["patches"]["title"]["value"] = " "
        require(g.apply(op)["result"]["results"][0]["rejection_code"] == "invalid_title",
                "Combined semantic errors return a valid terminal title rejection")
        op = g.create(2)
        op["patches"]["status_group"]["value"] = status("todo", 100)
        op["patches"]["title"]["value"] = " "
        op["patches"]["priority"]["value"] = "urgent"
        require(g.apply(op)["result"]["results"][0]["rejection_code"] == "invalid_priority",
                "Combined semantic errors can instead return priority rejection")
        require(not g.history(), "Combined invalid commands cannot create history")
        passed_check("combined invalid status/title/priority preserves terminal rejection parity")

        valid_values = [status(s) for s in ("todo", "in_progress", "cancelled")]
        valid_values += [status("completed", v) for v in (-8640000000000000, -1, 0, 8640000000000000)]
        invalid_values = [None, [], "completed", {}, {"status": "todo"}, status("unknown"),
            status("completed"), status("completed", "100"), status("completed", True),
            status("completed", 8640000000000001), status("completed", -8640000000000001),
            status("todo", 0), status("cancelled", 1), dict(status(), extra=True)]
        for value in valid_values + invalid_values:
            g = TaskFixture(backend, epoch)
            g.apply(g.create())
            op = g.set_status(2, value)
            receipt = g.apply(op)["result"]["results"][0]
            require((receipt["disposition"] == "applied") == (value in valid_values), "Status validation parity boundary")
            if value == status():
                require(len(g.history()) == 1, "Unchanged todo does not create a history event")
            if value in invalid_values:
                require(receipt["rejection_code"] == "invalid_status_group" and len(g.history()) == 1, "Invalid status leaves history intact")
                require(g.fields()["status_group"]["value"] == status(), "Invalid atomic group unchanged")
        passed_check("atomic status member/type/range validation including UTC epoch boundaries")

        g = TaskFixture(backend, epoch)
        creation = g.create(initial=status("completed", 42))
        before = g.state()
        trigger = "test_fault_" + uid().replace("-", "")
        try:
            sql(f"create function sync_private.{trigger}() returns trigger language plpgsql as $$ "
                f"begin if new.owner_id='{g.owner}'::uuid then raise exception 'Injected test failure'; "
                "end if; return new; end $$; "
                f"create trigger {trigger} before insert on sync_private.change_log "
                f"for each row execute function sync_private.{trigger}();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", g.token, {"request": g.request(creation)})
            require(code == 400 and g.state() == before, "Failure after creation/history/receipt rolls back all state")
        finally:
            sql(f"drop trigger if exists {trigger} on sync_private.change_log; drop function if exists sync_private.{trigger}();")
        g.apply(creation)
        other = TaskFixture(backend, epoch)
        before = g.state()
        require(other.apply(other.create(task=g.task))["result"]["results"][0]["disposition"] == "applied", "Task identity scoped to owner")
        require(g.state() == before, "Same UUID in Y cannot change X")
        claim = literal(json.dumps({"sub": other.owner, "role": "authenticated"}))
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claims',{claim},true) is not null; "
                    f"select count(*) from sync_private.task_status_history where owner_id='{g.owner}'; rollback;").splitlines() == ["t", "0"],
                "History RLS denies cross-owner reads")
        row = sql(f"select to_jsonb(h) from sync_private.task_status_history h where owner_id='{g.owner}' limit 1;")
        sql(f"begin; set local role dourstuff_rpc; do $test$ begin perform set_config('request.jwt.claims',{claim},true); "
            f"begin insert into sync_private.task_status_history select * from jsonb_populate_record("
            f"null::sync_private.task_status_history,{literal(row)}::jsonb); raise exception 'Cross-owner insert allowed'; "
            "exception when insufficient_privilege then null; end; end $test$; rollback;")
        for token in (None, g.token, other.token):
            code, _ = backend.request("GET", "/rest/v1/task_status_history", token)
            require(code in (401, 403, 404), "Raw REST history unavailable")
        passed_check("rollback covers status history; same-UUID account isolation and history RLS")

        # A retained tombstone prevents both recreate and completion, including
        # an old/incomplete shadow. SQL injects deletion only; delete RPC is pending.
        sql(f"update sync_private.task_shadow set fields=jsonb_set(fields,'{{existence}}',"
            f"'{{\"revision\":1,\"value\":false}}'),delete_operation_id='{uid()}' "
            f"where owner_id='{g.owner}' and task_id='{g.task}';")
        canonical = g.fields()
        for op in (g.create(2), g.set_status(3, status())):
            receipt = g.apply(op)["result"]["results"][0]
            require(all(p["disposition"] == "recovery" for p in receipt["fields"]), "Deleted identity requires explicit recovery")
        require(g.fields() == canonical and len(g.history()) == 1, "No resurrection or history change")
        passed_check("deleted identity blocks recreation and status mutation")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} task creation/status integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

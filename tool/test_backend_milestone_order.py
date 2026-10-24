"""Real local atomic reorder/add/delete, original bases, ownership and rollback."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture
from test_backend_milestone_create import children, milestone, receipt
from test_backend_milestone_commands import edit, remove, state
from test_backend_task_delete import deletion
from test_backend_task_restore import restore


def value(*ids):
    return {"ordered_ids": list(ids)}


def order(f, ids, seq=4, base=None, dependencies=()):
    op = f.op(seq, value(*ids), {"kind": "absent"} if base is None else base, group="milestone_order")
    op["command"] = "task.milestone_order"
    op["dependencies"] = [{"entity": deepcopy(p["entity"]), "operation_id": p["operation_id"],
                           "sequence": p["sequence"], "group": "existence"} for p in dependencies]
    return op


def projected(f, task=None):
    return json.loads(sql(f"begin; set local role dourstuff_rpc; "
        f"select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
        f"select sync_private.visible_milestone_order('{task or f.task}'); rollback;").splitlines()[-1])


def created(backend, epoch):
    f = TaskFixture(backend, epoch)
    a, b = milestone(f, 2), milestone(f, 3)
    f.apply(f.create(), a, b)
    return f, a, b, a["entity"]["key"][0], b["entity"]["key"][0]


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
        fixture = json.loads((Path(__file__).resolve().parents[1] /
            "test/fixtures/account-protocol-v2-milestone-order.json").read_text(encoding="utf-8"))
        f = TaskFixture(backend, epoch)
        ops = fixture["request"]["operations"]
        f.device, f.task = ops[0]["device_epoch"], ops[0]["entity"]["key"][0]
        f.register(f.device)
        result = f.apply(*ops)
        require(all(r["disposition"] == "applied" for r in result["result"]["results"]), "Shared parent/children/order/predecessor batch")
        require(f.fields()["milestone_order"] == {"revision": 5, "value": ops[-1]["patches"]["milestone_order"]["value"]}, "Original accepted ordered list")
        require(projected(f) == ops[-1]["patches"]["milestone_order"]["value"]["ordered_ids"] and len(f.history()) == 1, "Projection matches without status-history side effects")
        require(f.pull()["groups"][-1]["records"][0]["fields"] == f.fields(), "Pull carries canonical order with revision")
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(list(pool.map(lambda _: f.apply(*ops), range(2))) == [result, result], "Dropped reply and concurrent retries")
        require(state(f) == before, "Retries leave every table unchanged")
        changed = deepcopy(ops[-1])
        changed["patches"]["milestone_order"]["value"]["ordered_ids"].reverse()
        require(f.apply(changed)["code"] == "payloadMismatch" and state(f) == before, "Possibly sent order is immutable")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(ops[-1])["result"]["results"][0]["kind"] == "already_processed" and state(f) == before, "Expired receipt never reorders again")
        passed_check("shared wire fixture, atomic parent/create/order batch, original identities, retries and expiry")

        # The same value cases are checked by Dart without enabling account UI.
        for case in fixture["validity"]:
            require(sql("select sync_private.valid_milestone_order(" + literal(json.dumps(case["value"])) + "::jsonb);") == ("t" if case["valid"] else "f"), "Shared SQL/Dart shape validity")
        for case in fixture["projections"]:
            f = TaskFixture(backend, epoch)
            f.apply(f.create())
            ids = set(case["visible"]) | set((case["order"] or value())["ordered_ids"])
            for seq, identity in enumerate(sorted(ids), 2):
                f.apply(milestone(f, seq, identity=identity))
            seq = 2 + len(ids)
            if case["order"] is not None:
                f.apply(order(f, case["order"]["ordered_ids"], seq))
                seq += 1
            for row in children(f):
                if row["milestone_id"] not in case["visible"]:
                    original = row["creation_operation"]
                    f.apply(remove(f, original, seq, observed(row["fields"]["existence"]["revision"], True)))
                    seq += 1
            require(projected(f) == case["expected"], "Shared projection filters deleted and sorts independent additions")
        passed_check("shared SQL/Dart validator and canonical-versus-visible projection cases")

        for reverse in (False, True):
            f, a, b, aid, bid = created(backend, epoch)
            first = order(f, [aid, bid])
            f.apply(first)
            rival = uid()
            f.register(rival)
            x = order(f, [bid, aid], 5, observed(4, value(aid, bid)))
            y = order(f, [], 1, observed(4, value(aid, bid)))
            y["device_epoch"] = rival
            winner, loser = (y, x) if reverse else (x, y)
            require(receipt(f, winner)["disposition"] == "applied" and receipt(f, loser)["disposition"] == "conflict", "First concurrent order stays canonical")
            require(f.fields()["milestone_order"]["value"] == winner["patches"]["milestone_order"]["value"], "No hybrid or partial order")
            candidate = f.pull()["groups"][-1]["recovery"][0]
            require(candidate["operation"] == loser and candidate["canonical"]["value"] == winner["patches"]["milestone_order"]["value"], "Original concurrent order preserved")
            held = order(f, winner["patches"]["milestone_order"]["value"]["ordered_ids"], loser["sequence"]+1,
                         predecessor(loser, loser["patches"]["milestone_order"]["value"]))
            held["device_epoch"] = loser["device_epoch"]
            unrelated = f.op(held["sequence"]+1, "Unrelated title")
            unrelated["device_epoch"] = held["device_epoch"]
            require([r["disposition"] for r in f.apply(held, unrelated)["result"]["results"]] == ["held", "applied"], "Held before equivalence, unrelated sequence advances")
        f, a, b, aid, bid = created(backend, epoch)
        rival = uid()
        f.register(rival)
        x, y = order(f, [aid, bid]), order(f, [bid, aid], 1)
        y["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(sorted(r["disposition"] for r in pool.map(lambda op: receipt(f, op), (x, y))) == ["applied", "conflict"], "Actual simultaneous reorder race")
        passed_check("both concurrent reorder arrival orders, exact candidates, held chains and simultaneous race")

        for add_first in (False, True):
            for delete_first in (False, True):
                f, a, b, aid, bid = created(backend, epoch)
                child = milestone(f, 4 if add_first else 5)
                cid = child["entity"]["key"][0]
                change = order(f, [bid, aid], 5 if add_first else 4)
                f.apply(*((child, change) if add_first else (change, child)))
                canonical = f.fields()["milestone_order"]
                require(projected(f) == [bid, aid, cid], "Concurrent add survives accepted reorder in either arrival order")
                removed = remove(f, b, 6 if delete_first else 7, observed(3, True))
                second = order(f, [aid, bid], 7 if delete_first else 6, observed(canonical["revision"], canonical["value"]))
                f.apply(*((removed, second) if delete_first else (second, removed)))
                require(projected(f) == [aid, cid] and f.fields()["milestone_order"]["value"] == value(aid, bid), "Delete dominates projection, never rewrites canonical order")
                parent_delete = deletion(f, 8)
                f.apply(parent_delete)
                original = f.fields()["milestone_order"]
                require(projected(f) == [], "Hidden parent has no visible order")
                late = order(f, [], 9, observed(original["revision"], original["value"]))
                require(receipt(f, late)["fields"][0]["disposition"] == "recovery", "Hidden task retains late original order")
                f.apply(restore(f, parent_delete, 10, 8))
                require(projected(f) == [aid, cid] and f.fields()["milestone_order"] == original, "Restore retains child tombstone and original order")
        passed_check("reorder/add/delete in both arrival orders, hidden parent recovery and restore")

        f, a, b, aid, bid = created(backend, epoch)
        adding, deleting = uid(), uid()
        f.register(adding)
        f.register(deleting)
        addition = milestone(f, 1)
        addition["device_epoch"] = adding
        removed = remove(f, b, 1, observed(3, True))
        removed["device_epoch"] = deleting
        with ThreadPoolExecutor(max_workers=3) as pool:
            require(all(r["disposition"] == "applied" for r in pool.map(lambda op: receipt(f, op),
                (order(f, [bid, aid]), addition, removed))), "Concurrent order/add/delete commits")
        require(projected(f) == [aid, addition["entity"]["key"][0]] and
                f.fields()["milestone_order"]["value"] == value(bid, aid), "Simultaneous race converges without changing canonical list")
        passed_check("simultaneous three-device reorder/add/delete convergence")

        f, a, b, aid, bid = created(backend, epoch)
        first = order(f, [aid, bid])
        f.apply(first)
        equivalent = order(f, [aid, bid], 5, {"kind": "absent"})
        require(receipt(f, equivalent)["fields"][0]["disposition"] == "equivalent", "Stale equal order accepted without new field revision")
        corrupt = order(f, [aid, bid], 6, observed(4, value(bid, aid)))
        require(receipt(f, corrupt)["fields"][0]["disposition"] == "recovery", "Wrong original at equal revision cannot use equivalence")
        accepted = order(f, [bid, aid], 7, predecessor(equivalent, value(aid, bid)))
        require(receipt(f, accepted)["disposition"] == "applied", "Equivalent predecessor binds its actual accepted revision")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and sequence=7;")
        expired = order(f, [aid, bid], 8, predecessor(accepted, value(bid, aid)))
        require(receipt(f, expired)["fields"][0]["disposition"] == "recovery", "Expired order predecessor is never guessed")
        wrong_entity = order(f, [], 9, predecessor(a, value()))
        require(receipt(f, wrong_entity)["fields"][0]["disposition"] == "recovery", "Child existence cannot bind task order field")
        passed_check("equivalent predecessor, corrupt original, expired evidence and entity/group binding")

        # Held creation has no row; exact child evidence holds the whole order.
        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        conflict = f.create(2, title="Collision")
        child = milestone(f, 3, dependency=conflict)
        cid = child["entity"]["key"][0]
        waiting = order(f, [cid], 4, dependencies=[child])
        require([r["disposition"] for r in f.apply(conflict, child, waiting, f.op(5, "Progress"))["result"]["results"]] == ["conflict", "held", "held", "applied"], "No phantom child or order from held create")
        require(not children(f) and "milestone_order" not in f.fields(), "Held order never fabricates state")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and sequence=3;")
        missing = order(f, [cid], 6, dependencies=[child])
        require(receipt(f, missing)["fields"][0]["disposition"] == "recovery", "Expired child dependency requires recovery")
        for reason in ("id", "sequence", "epoch", "entity", "foreign_parent", "duplicate", "unlisted"):
            f, a, b, aid, bid = created(backend, epoch)
            dependent = order(f, [aid], dependencies=[a])
            dep = dependent["dependencies"][0]
            if reason == "id": dep["operation_id"] = uid()
            elif reason == "sequence": dep["sequence"] = 1
            elif reason == "epoch":
                rival = uid()
                f.register(rival)
                sql(f"update sync_private.device_state set high_water=3 where owner_id='{f.owner}' and device_epoch='{rival}';")
                dependent["device_epoch"] = rival
            elif reason == "entity": dep["entity"]["kind"] = "task"
            elif reason == "foreign_parent": dependent["entity"]["key"] = [uid()]
            elif reason == "duplicate": dependent["dependencies"].append(deepcopy(dep))
            else: dependent["patches"]["milestone_order"]["value"] = value(bid)
            result = receipt(f, dependent)
            require(result["disposition"] == "rejected" or result["fields"][0]["disposition"] == "recovery", "Exact dependency failure: " + reason)
            require("milestone_order" not in f.fields(), "Invalid dependency never changes order")
        passed_check("held child creation, missing evidence and exact dependency ownership/identity")

        f, a, b, aid, bid = created(backend, epoch)
        original = f.fields(), children(f), f.history()
        invalid = [c["value"] for c in fixture["validity"] if not c["valid"]]
        seq = 4
        for v in invalid:
            bad = order(f, [], seq)
            bad["patches"]["milestone_order"]["value"] = v
            require(receipt(f, bad)["rejection_code"] == "invalid_milestone_order", "Malformed ordered list is consumed rejection")
            seq += 1
        mixed = order(f, [aid], seq)
        mixed["patches"]["title"] = {"base": observed(1, "X"), "value": "Must not leak"}
        require(receipt(f, mixed)["rejection_code"] == "invalid_order_command", "Order command cannot bundle unrelated fields")
        seq += 1
        for command in ("task.edit", "task.create", "task.status"):
            bad = f.create(seq) if command == "task.create" else order(f, [aid], seq)
            bad["command"] = command
            bad["patches"]["milestone_order"] = {"base": {"kind": "absent"}, "value": value(aid)}
            require(receipt(f, bad)["rejection_code"] == "invalid_order_command", "Order cannot bypass its command")
            seq += 1
        require((f.fields(), children(f), f.history()) == original, "No partial semantic rejection mutations")
        before = state(f)
        malformed = order(f, [aid], seq+1, dependencies=[a])
        malformed["dependencies"][0]["sequence"] = seq+1
        code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(order(f, [bid, aid], seq), malformed)})
        require(code == 400 and state(f) == before, "Malformed dependency preflights entire batch")
        passed_check("semantic list validation, command isolation, atomic rejection and batch preflight")

        f, a, b, aid, bid = created(backend, epoch)
        other = TaskFixture(backend, epoch)
        other.task = f.task
        other.apply(other.create())
        own = milestone(other, 2, identity=aid)
        other.apply(own)
        before = state(f)
        require(receipt(other, order(other, [aid], 3))["disposition"] == "applied", "Same UUID scoped independently in Y")
        for seq, child_id in enumerate((bid, uid()), 4):
            require(receipt(other, order(other, [child_id], seq))["fields"][0]["disposition"] == "recovery", "Foreign child indistinguishable from missing")
        second_parent = uid()
        other.apply(other.create(6, task=second_parent))
        wrong_parent = order(other, [aid], 7)
        wrong_parent["entity"]["key"] = [second_parent]
        require(receipt(other, wrong_parent)["fields"][0]["disposition"] == "recovery", "Same-owner other-parent child is unavailable")
        require(state(f) == before and projected(other) == [aid], "X is unchanged and Y projection isolated")
        for token in (None, f.token, other.token):
            for name in ("visible_milestone_order", "milestone_order_decision", "valid_milestone_order"):
                code, _ = backend.request("POST", "/rest/v1/rpc/" + name, token, {})
                require(code in (401, 403, 404), "Private helpers are not exposed RPCs")
        require(sql("select bool_and(not has_function_privilege(r, f, 'EXECUTE')) from "
                    "unnest(array['anon','authenticated','service_role']) r cross join "
                    "unnest(array['sync_private.valid_milestone_order(jsonb)', 'sync_private.milestone_order_decision(jsonb)', "
                    "'sync_private.visible_milestone_order(uuid)']) f;") == "t", "No client helper execute grants")
        passed_check("cross-account and cross-parent reference isolation, same IDs and private helper grants")

        f, a, b, aid, bid = created(backend, epoch)
        before = state(f)
        sql("create function sync_private.test_order_fail() returns trigger language plpgsql as $$ "
            "begin if new.revision=5 then raise exception 'Injected order failure'; end if; return new; end $$; "
            "create trigger test_order_fail before insert on sync_private.change_log "
            "for each row execute function sync_private.test_order_fail();")
        try:
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token,
                {"request": f.request(order(f, [bid, aid]), remove(f, a, 5))})
            require(code == 400 and state(f) == before, "Order/child/receipt/log/cursor/watermark rollback")
        finally:
            sql("drop trigger test_order_fail on sync_private.change_log; drop function sync_private.test_order_fail();")
        require(receipt(f, order(f, [bid, aid]))["disposition"] == "applied", "No sequence consumed by failed transaction")
        passed_check("injected atomic transaction rollback and successful original sequence retry")
        print(f"{passed} milestone-order integration groups passed.")
    finally:
        backend.cleanup()
        if args.wire_output:
            args.wire_output.parent.mkdir(parents=True, exist_ok=True)
            args.wire_output.write_text(json.dumps(backend.wire), encoding="utf-8")


if __name__ == "__main__":
    main()

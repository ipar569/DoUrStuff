"""Real local milestone edit/delete conflicts, recovery, ownership and atomicity."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, require, sql
from test_backend_milestone_create import children, milestone, receipt, visible
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_task_restore import restore


def edit(f, child, seq=3, value="Edited", group="title", base=None):
    original = child["patches"][group]["value"]
    op = f.op(seq, value, observed(2, original) if base is None else base, group=group)
    op["entity"] = deepcopy(child["entity"])
    op["command"] = "milestone.edit"
    return op


def remove(f, child, seq=3, base=None):
    op = edit(f, child, seq, False, "existence", observed(2, True) if base is None else base)
    op["command"] = "milestone.delete"
    return op


def ledger(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(d) order by revision),'[]') "
                         f"from sync_private.milestone_deletions d where owner_id='{f.owner}';"))


def state(f):
    return f.state(), children(f), ledger(f)


def created(backend, epoch):
    f = TaskFixture(backend, epoch)
    child = milestone(f, identity=f.task)
    f.apply(f.create(), child)
    return f, child


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
        fixture = json.loads((Path(__file__).resolve().parents[1] /
            "test/fixtures/account-protocol-v2-milestone-commands.json").read_text(encoding="utf-8"))
        parent, child, change, deleted = fixture["operations"]
        f.device, f.task = parent["device_epoch"], parent["entity"]["key"][0]
        f.register(f.device)
        result = f.apply(parent, child, change, deleted)
        require(all(r["disposition"] == "applied" for r in result["result"]["results"]), "Atomic create/edit/delete fixture")
        row = children(f)[0]
        require(row["fields"]["title"] == {"revision": 3, "value": "Changed"} and
                row["fields"]["completion"] == {"revision": 3, "value": 100} and
                row["fields"]["existence"] == {"revision": 4, "value": False}, "Independent edited fields and tombstone revisions")
        require(row["creation_operation"] == child and ledger(f)[0]["operation"] == deleted and
                row["delete_operation_id"] == deleted["operation_id"] and len(f.history()) == 1, "Original creation/delete and task history preserved")
        require(f.pull()["groups"][-1]["records"][0]["delete_operation_id"] == deleted["operation_id"], "Pull carries exact child deletion identity")
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            retries = list(pool.map(lambda _: f.apply(parent, child, change, deleted), range(2)))
        require(retries == [result, result] and state(f) == before, "Lost response and concurrent retries are idempotent")
        altered = deepcopy(deleted)
        altered["provenance"]["occurred_at"] = 999
        require(f.apply(altered)["code"] == "payloadMismatch" and state(f) == before, "Deletion payload is immutable")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(deleted)["result"]["results"][0]["kind"] == "already_processed" and state(f) == before, "Expired receipt never replays")
        altered = deepcopy(deleted)
        altered["sequence"] = 6
        require(f.apply(f.op(5, "Must roll back"), altered)["code"] == "payloadMismatch" and state(f) == before, "Retained identity mismatch preflights the whole batch")
        recreate = milestone(f, 5, identity=child["entity"]["key"][0])
        require(all(p["disposition"] == "recovery" for p in receipt(f, recreate)["fields"]) and children(f) == before[1], "Deleted child identity cannot be recreated")
        passed_check("shared create/edit/delete fixture, original identities, atomic retries and expiry")

        for completion_first in (True, False):
            f, child = created(backend, epoch)
            rival = uid()
            f.register(rival)
            title = edit(f, child)
            completion = edit(f, child, 1, 10, "completion")
            completion["device_epoch"] = rival
            for op in ((completion, title) if completion_first else (title, completion)):
                require(receipt(f, op)["disposition"] == "applied", "Independent text/completion applies")
            fields = children(f)[0]["fields"]
            require(fields["title"]["value"] == "Edited" and fields["completion"]["value"] == 10, "Editing text never reopens child")
            cleared = edit(f, child, 4, None, "completion", observed(fields["completion"]["revision"], 10))
            require(receipt(f, cleared)["disposition"] == "applied" and children(f)[0]["fields"]["completion"]["value"] is None, "Explicit reopening clears only completion")
        f, child = created(backend, epoch)
        other_child = milestone(f, 3)
        f.apply(other_child)
        a, b = edit(f, child, 4), edit(f, other_child, 1, base=observed(3, "Step"))
        rival = uid()
        f.register(rival)
        b["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            require(all(r["disposition"] == "applied" for r in pool.map(lambda op: receipt(f, op), (a, b))), "Independent children merge")
        reopen = edit(f, child, 5, None, "completion")
        require(receipt(f, reopen)["disposition"] == "applied", "Nullable completion remains independently editable")
        passed_check("both text/completion arrival orders, independent children and nullable completion")

        f, child = created(backend, epoch)
        first = edit(f, child)
        f.apply(first)
        mixed = edit(f, child, 4, "Alternative")
        mixed["patches"]["completion"] = {"base": observed(2, None), "value": -10}
        require(receipt(f, mixed)["disposition"] == "partial", "Uncontested completion survives title conflict")
        held = edit(f, child, 5, "Edited", base=predecessor(mixed, "Alternative"))
        require(receipt(f, held)["disposition"] == "held", "Conflicted predecessor checked before equivalent value")
        require(receipt(f, edit(f, child, 6))["fields"][0]["disposition"] == "equivalent", "Independent stale same-value edit is equivalent")
        corrupt = edit(f, child, 7, "Edited", base=observed(3, "Wrong original"))
        require(receipt(f, corrupt)["fields"][0]["disposition"] == "recovery", "Equal-revision wrong original cannot be bypassed by equivalence")
        candidate = f.pull()["groups"][3]["recovery"][0]
        require(candidate["operation"] == mixed and candidate["canonical"] == {"revision": 3, "value": "Edited"}, "Original base/local/canonical candidate retained")
        rival = uid()
        f.register(rival)
        a = edit(f, child, 8, "A", base=observed(3, "Edited"))
        b = edit(f, child, 1, "B", base=observed(3, "Edited"))
        b["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda op: receipt(f, op), (a, b)))
        require(sorted(r["disposition"] for r in results) == ["applied", "conflict"], "One same-field concurrent edit wins")
        passed_check("partial conflicts, held-before-equivalence, corrupt originals and competing edits")

        f, child = created(backend, epoch)
        a = edit(f, child, base=predecessor(child, "Step"))
        b = edit(f, child, 4, "Again", base=predecessor(a, "Edited"))
        require(all(r["disposition"] == "applied" for r in f.apply(a, b)["result"]["results"]), "Accepted predecessor revisions bind without rewriting")
        wrong_kind = edit(f, child, 5, "Wrong kind", base=predecessor(f.create(), "X"))
        # Use the actual retained parent operation, with the same entity UUID
        # in the shared fixture covered above; a different kind never binds.
        parent = json.loads(sql(f"select operation from sync_private.operation_receipts where owner_id='{f.owner}' and sequence=1;"))
        wrong_kind["patches"]["title"]["base"] = predecessor(parent, "X")
        require(receipt(f, wrong_kind)["fields"][0]["disposition"] == "recovery", "Task predecessor cannot bind a milestone field")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and sequence=4;")
        require(receipt(f, edit(f, child, 6, "Expired", base=predecessor(b, "Again")))["fields"][0]["disposition"] == "recovery", "Expired predecessor does not guess current base")
        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        collision = f.create(2, title="Conflicted parent")
        held_child = milestone(f, 3, dependency=collision)
        held_edit = edit(f, held_child, 4, base=predecessor(held_child, "Step"))
        held_delete = remove(f, held_child, 5, predecessor(held_child, True))
        later = f.op(6, "Independent")
        results = f.apply(collision, held_child, held_edit, held_delete, later)["result"]
        require([r["disposition"] for r in results["results"]] == ["conflict", "held", "held", "held", "applied"], "Missing held child retains causal edit/delete and unrelated progress")
        require(not children(f) and not ledger(f) and results["device_high_water"] == 6, "No phantom child or sequence gap")
        require(receipt(f, edit(f, held_child, 7, base={"kind": "absent"}))["fields"][0]["disposition"] == "recovery", "Missing child cannot be fabricated with absent-base edit")
        passed_check("exact predecessor binding, missing/expired evidence and held child without a row")

        f, child = created(backend, epoch)
        original = children(f)
        invalids = []
        for seq, kind in enumerate(("parent", "existence", "title", "completion", "delete_extra", "delete_true", "delete_absent", "delete_original"), 3):
            op = edit(f, child, seq)
            if kind == "parent": op["patches"]["parent"] = {"base": observed(2, f.task), "value": f.task}
            elif kind == "existence": op["patches"]["existence"] = {"base": observed(2, True), "value": True}
            elif kind == "title": op["patches"]["title"]["value"] = " "
            elif kind == "completion": op["patches"]["completion"] = {"base": observed(2, None), "value": True}
            else:
                op = remove(f, child, seq)
                if kind == "delete_extra": op["patches"]["title"] = {"base": observed(2, "Step"), "value": "Smuggled"}
                elif kind == "delete_true": op["patches"]["existence"]["value"] = True
                elif kind == "delete_absent": op["patches"]["existence"]["base"] = {"kind": "absent"}
                else: op["patches"]["existence"]["base"] = observed(2, False)
            invalids.append(op)
        require(all(r["disposition"] == "rejected" for r in f.apply(*invalids)["result"]["results"]) and children(f) == original and not ledger(f), "Invalid edits/deletes commit no partial content")
        before = state(f)
        unsupported = edit(f, child, 11)
        unsupported["dependencies"] = deepcopy(milestone(f, 11, dependency=child)["dependencies"])
        require(f.apply(unsupported)["code"] == "unsupportedProtocol" and state(f) == before, "Edit parent dependencies remain unsupported; use field predecessors")
        malformed = edit(f, child, 12)
        malformed["patches"]["title"]["base"] = predecessor(malformed, "Step")
        code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(edit(f, child, 11), malformed)})
        require(code == 400 and state(f) == before, "Forward causal base fails entire-batch preflight")
        passed_check("immutable parent, semantic command rejection and strict whole-batch preflight")

        for delete_first in (True, False):
            f, child = created(backend, epoch)
            a, d = edit(f, child, 4 if delete_first else 3), remove(f, child, 3 if delete_first else 4)
            f.apply(*((d, a) if delete_first else (a, d)))
            require(not visible(f, child["entity"]["key"][0]), "Child deletion dominates in both orders")
            require(children(f)[0]["fields"]["title"]["value"] == ("Step" if delete_first else "Edited"), "Accepted/latest hidden content preserved")
            if delete_first:
                require(f.pull()["groups"][-1]["recovery"][0]["operation"] == a, "Late child edit retains original operation")
        for child_first in (True, False):
            f, child = created(backend, epoch)
            parent_remove = deletion(f, 4 if child_first else 3)
            child_remove = remove(f, child, 3 if child_first else 4)
            f.apply(*((child_remove, parent_remove) if child_first else (parent_remove, child_remove)))
            original = children(f), ledger(f)
            f.apply(restore(f, parent_remove, 5, 4 if child_first else 3))
            require((children(f), ledger(f)) == original and not visible(f, child["entity"]["key"][0]), "Independent child deletion survives parent restore in both orders")
        f, child = created(backend, epoch)
        parent_remove = deletion(f, 3)
        f.apply(parent_remove)
        hidden_edit = edit(f, child, 4, "Step")
        require(receipt(f, hidden_edit)["fields"][0]["disposition"] == "recovery", "Hidden parent checked before even equivalent child edits")
        before = children(f)
        f.apply(restore(f, parent_remove, 5, 3))
        require(children(f) == before and visible(f, child["entity"]["key"][0]), "Restoring parent does not replay child recovery")
        passed_check("delete/edit and parent/child-delete orderings with permanent independent tombstones")

        for competing_delete in (True, False):
            f, child = created(backend, epoch)
            rival = uid()
            f.register(rival)
            a = remove(f, child)
            b = remove(f, child, 1) if competing_delete else edit(f, child, 1)
            b["device_epoch"] = rival
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(lambda op: receipt(f, op), (a, b)))
            require(len(ledger(f)) == 1 and not visible(f, child["entity"]["key"][0]), "Concurrent delete keeps one tombstone")
            if competing_delete:
                require(sorted(r["disposition"] for r in results) == ["applied", "conflict"], "Only winning delete changes identity")
            else:
                require(results[0]["disposition"] == "applied", "Concurrent editing never prevents deletion")
        passed_check("simultaneous duplicate deletions and edit/delete race preserve one winning identity")

        f, child = created(backend, epoch)
        f.apply(remove(f, child))
        other = TaskFixture(backend, epoch)
        before = state(f)
        for op in (edit(other, child, 1), remove(other, child, 2)):
            require(receipt(other, op)["fields"][0]["disposition"] == "recovery", "Foreign milestone indistinguishable from missing")
        require(state(f) == before and not children(other), "Cross-owner edits/deletes leave X unchanged")
        own = milestone(other, 4, identity=child["entity"]["key"][0])
        other.apply(other.create(3), own)
        require(receipt(other, edit(other, own, 5, base=observed(4, "Step")))["disposition"] == "applied", "Same UUID in Y has independent canonical state")
        for token in (None, f.token, other.token):
            for method, body in (("GET", None), ("POST", {}), ("PATCH", {}), ("DELETE", None)):
                code, _ = backend.request(method, "/rest/v1/milestone_deletions", token, body)
                require(code in (401, 403, 404), "No raw deletion-ledger REST bypass")
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
            f"select count(*) from sync_private.milestone_deletions where owner_id='{f.owner}'; "
            f"update sync_private.milestone_shadow set fields='{{}}' where owner_id='{f.owner}'; "
            "do $test$ begin begin insert into sync_private.milestone_deletions(owner_id,milestone_id,operation_id,revision,operation) "
            f"values ('{f.owner}','{child['entity']['key'][0]}','{uid()}',1,'{{}}'); "
            "raise exception 'Foreign ledger insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;").splitlines() == ["t", "0"] and state(f) == before, "Forced RLS blocks foreign read/update/insert")
        require(sql("select has_column_privilege('dourstuff_rpc','sync_private.milestone_shadow','fields','update') "
            "and has_column_privilege('dourstuff_rpc','sync_private.milestone_shadow','delete_operation_id','update') "
            "and not has_column_privilege('dourstuff_rpc','sync_private.milestone_shadow','task_id','update') "
            "and not has_column_privilege('dourstuff_rpc','sync_private.milestone_shadow','creation_operation','update') "
            "and not has_column_privilege('dourstuff_rpc','sync_private.milestone_shadow','owner_id','update') "
            "and not has_table_privilege('dourstuff_rpc','sync_private.milestone_deletions','update') "
            "and not has_table_privilege('dourstuff_rpc','sync_private.milestone_deletions','delete');") == "t", "Narrow column updates preserve immutable parent/owner/creation and append-only ledger")
        passed_check("X/Y same-UUID isolation, raw REST denial, forced RLS and narrow update grants")

        f, child = created(backend, epoch)
        a, d = f.op(3, "Changed task"), remove(f, child, 4)
        before = state(f)
        try:
            sql("create function sync_private.fail_milestone_commands_test() returns trigger language plpgsql as $$ "
                "begin if new.revision=4 then raise exception 'injected child deletion failure'; end if; return new; end $$; "
                "create trigger fail_milestone_commands_test before insert on sync_private.change_log "
                "for each row execute function sync_private.fail_milestone_commands_test();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(a, d)})
            require(code >= 400 and state(f) == before, "Batch fault rolls back task, child, ledger, receipts, recovery and progress")
        finally:
            sql("drop trigger if exists fail_milestone_commands_test on sync_private.change_log; drop function if exists sync_private.fail_milestone_commands_test();")
        require(all(r["disposition"] == "applied" for r in f.apply(a, d)["result"]["results"]), "Original retry succeeds after rollback")
        passed_check("mid-transaction failure rolls back every child deletion and earlier batch effect")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} milestone command integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

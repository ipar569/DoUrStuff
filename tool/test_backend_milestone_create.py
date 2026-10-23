"""Real local milestone creation, exact parent dependencies and inherited visibility."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, uid
from test_backend_foundation import Backend, require, sql
from test_backend_task_create import TaskFixture
from test_backend_task_delete import deletion
from test_backend_task_restore import restore


def milestone(f, seq=2, parent=None, dependency=None, identity=None, completion=None):
    op = f.op(seq, "Step")
    op["command"] = "milestone.create"
    op["entity"] = {"kind": "milestone", "key": [identity or uid()]}
    op["patches"] = {key: {"base": {"kind": "absent"}, "value": value}
        for key, value in {"existence": True, "title": "Step", "completion": completion,
                           "parent": parent or f.task}.items()}
    if dependency is not None:
        op["dependencies"] = [{"entity": deepcopy(dependency["entity"]), "operation_id": dependency["operation_id"],
                               "sequence": dependency["sequence"], "group": "existence"}]
    return op


def children(f):
    return json.loads(sql(f"select coalesce(jsonb_agg(to_jsonb(m) order by milestone_id),'[]') "
                         f"from sync_private.milestone_shadow m where owner_id='{f.owner}';"))


def state(f):
    return f.state(), children(f)


def visible(f, identity):
    return sql(f"begin; set local role dourstuff_rpc; "
               f"select set_config('request.jwt.claim.sub','{f.owner}',true) is not null; "
               f"select sync_private.milestone_visible('{identity}'); rollback;").splitlines()[-1] == "t"


def receipt(f, op):
    return f.apply(op)["result"]["results"][0]


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
            "test/fixtures/account-protocol-v2-milestone.json").read_text(encoding="utf-8"))
        parent, child = fixture["operations"]
        f.device, f.task = parent["device_epoch"], parent["entity"]["key"][0]
        f.register(f.device)
        result = f.apply(parent, child)
        require([r["disposition"] for r in result["result"]["results"]] == ["applied", "applied"], "Parent/child same-batch creation")
        row = children(f)[0]
        require(row["fields"] == {k: {"revision": 2, "value": p["value"]} for k, p in child["patches"].items()}, "Every child group uses one revision")
        require(row["creation_operation"] == child and row["task_id"] == f.task, "Immutable creation and parent link")
        require(len(f.history()) == 1 and f.fields()["title"]["value"] == "X", "Kind-qualified same UUID cannot overwrite task/history")
        require(visible(f, f.task), "Same-owner parent makes child visible")
        groups = f.pull()["groups"]
        require(groups[1]["records"][0]["entity"] == child["entity"], "Child downloads as its own kind")
        before = state(f)
        with ThreadPoolExecutor(max_workers=2) as pool:
            retries = list(pool.map(lambda _: f.apply(parent, child), range(2)))
        require(retries == [result, result] and state(f) == before, "Lost response/concurrent retries do not repeat creation")
        changed = deepcopy(child)
        changed["patches"]["title"]["value"] = "Changed"
        require(f.apply(changed)["code"] == "payloadMismatch" and state(f) == before, "Immutable creation mismatch")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}'; delete from sync_private.change_log where owner_id='{f.owner}';")
        before = state(f)
        require(f.apply(child)["result"]["results"][0]["kind"] == "already_processed" and state(f) == before, "Expired response never replays")
        reused = deepcopy(child)
        reused["sequence"] = 3
        require(f.apply(reused)["code"] == "payloadMismatch" and state(f) == before, "Creation identity outlives receipt/log expiry")
        passed_check("atomic parent/child batch, kind-qualified identity, exact retries and durable creation payload")

        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        collision = f.create(2, title="Other parent")
        child = milestone(f, 3, dependency=collision)
        independent = f.op(4, "Unrelated progress")
        result = f.apply(collision, child, independent)["result"]
        require([r["disposition"] for r in result["results"]] == ["conflict", "held", "applied"], "Conflicted parent holds child but advances unrelated command")
        require(not children(f) and result["device_high_water"] == 4, "No partial child or blocked sequence")
        candidates = f.pull()["groups"][2]["recovery"]
        require(len(candidates) == 4 and all(c["operation"] == child and c["disposition"] == "held" for c in candidates), "All original child groups/bases held together")
        second = milestone(f, 5, dependency=collision)
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}' and sequence=2;")
        require(all(p["disposition"] == "recovery" for p in receipt(f, second)["fields"]), "Expired parent receipt cannot be guessed from canonical state")
        passed_check("parent conflict/held/unrelated sequence and expired causal evidence")

        for reason in ("missing", "wrong_id", "wrong_sequence", "wrong_epoch", "wrong_entity", "wrong_kind", "nonexistence", "rejected", "deleted"):
            f = TaskFixture(backend, epoch)
            parent = f.create()
            if reason == "rejected": parent["patches"]["title"]["value"] = ""
            f.apply(parent)
            child = milestone(f, 2, dependency=parent)
            dep = child["dependencies"][0]
            if reason == "missing": sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
            elif reason == "wrong_id": dep["operation_id"] = uid()
            elif reason == "wrong_sequence":
                f.apply(f.op(2, "Edited"))
                child["sequence"], dep["sequence"] = 3, 2
            elif reason == "wrong_epoch":
                other = uid()
                f.register(other)
                unrelated = f.create(1, task=uid())
                unrelated["device_epoch"] = other
                f.apply(unrelated)
                child["device_epoch"] = other
            elif reason == "wrong_entity": dep["entity"]["key"] = [uid()]
            elif reason == "wrong_kind": dep["entity"]["kind"] = "tag"
            elif reason == "nonexistence":
                edit = f.op(2, "Edited")
                f.apply(edit)
                child = milestone(f, 3, dependency=edit)
            elif reason == "deleted":
                f.apply(deletion(f))
                child["sequence"] = 3
            result = receipt(f, child)
            require(result["disposition"] == "conflict" and all(p["disposition"] == "recovery" for p in result["fields"]) and not children(f), "Parent evidence fails closed: " + reason)
        passed_check("missing/rejected/deleted and wrong operation/epoch/sequence/entity/group parents")

        for mutation in ("missing_group", "bad_title", "false_existence", "observed_base", "bad_parent", "bad_completion", "duplicate_dependencies"):
            f = TaskFixture(backend, epoch)
            parent = f.create()
            f.apply(parent)
            op = milestone(f, dependency=parent)
            if mutation == "missing_group": del op["patches"]["completion"]
            elif mutation == "bad_title": op["patches"]["title"]["value"] = " "
            elif mutation == "false_existence": op["patches"]["existence"]["value"] = False
            elif mutation == "observed_base": op["patches"]["title"]["base"] = observed(1, "Step")
            elif mutation == "bad_parent": op["patches"]["parent"]["value"] = "not-a-uuid"
            elif mutation == "bad_completion": op["patches"]["completion"]["value"] = True
            else: op["dependencies"] *= 2
            require(receipt(f, op)["disposition"] == "rejected" and not children(f), "Invalid child rejected atomically: " + mutation)
            require(receipt(f, milestone(f, 3))["disposition"] == "applied", "Later valid command advances")
        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        for i, value in enumerate((None, 0, -8640000000000000, 8640000000000000, -8640000000000001, 8640000000000001, "0", {}, []), 2):
            result = receipt(f, milestone(f, i, completion=value))
            require(result["disposition"] == ("applied" if i < 6 else "rejected"), "Completion is nullable native-range epoch milliseconds")
        passed_check("all-or-nothing semantic rejection, nullable completion boundaries and repair progress")

        f = TaskFixture(backend, epoch)
        parent = f.create()
        before = state(f)
        for mutation in ("future", "same_id", "extra", "group", "entity", "not_array"):
            op = milestone(f, dependency=parent)
            dep = op["dependencies"][0]
            if mutation == "future": dep["sequence"] = 2
            elif mutation == "same_id": dep["operation_id"] = op["operation_id"]
            elif mutation == "extra": dep["extra"] = 1
            elif mutation == "group": dep["group"] = "title"
            elif mutation == "entity": dep["entity"]["key"] = []
            else: op["dependencies"] = {}
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(parent, op)})
            require(code == 400 and state(f) == before, "Malformed dependency rolls back whole batch: " + mutation)
        unsupported = milestone(f, dependency=parent)
        unsupported["command"] = "milestone.edit"
        require(f.apply(parent, unsupported)["code"] == "unsupportedProtocol" and state(f) == before, "Remaining milestone commands stay capability-gated")
        passed_check("whole-batch strict dependency preflight and unchanged unsupported-command gates")

        f = TaskFixture(backend, epoch)
        f.apply(f.create(), f.create(2, task=(other_parent := uid())))
        first = milestone(f, 3)
        f.apply(first)
        original = children(f)
        collision = milestone(f, 4, parent=other_parent, identity=first["entity"]["key"][0], completion=20)
        require(receipt(f, collision)["disposition"] == "conflict" and children(f) == original, "Collision cannot reparent or merge any field")
        rival = uid()
        f.register(rival)
        identity = uid()
        a, b = milestone(f, 5, identity=identity), milestone(f, 1, parent=other_parent, identity=identity)
        b["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda op: receipt(f, op), (a, b)))
        require(sorted(r["disposition"] for r in results) == ["applied", "conflict"], "One complete child wins competing creates")
        require(len(children(f)) == 2, "No duplicate child")
        passed_check("immutable parent relationship, whole-entity collision and simultaneous creators")

        for child_first in (True, False):
            f = TaskFixture(backend, epoch)
            f.apply(f.create())
            child = milestone(f)
            remove = deletion(f, 3 if child_first else 2)
            child["sequence"] = 2 if child_first else 3
            f.apply(*((child, remove) if child_first else (remove, child)))
            identity = child["entity"]["key"][0]
            require(not visible(f, identity), "Deleted parent hides children in both arrival orders")
            original = children(f)
            f.apply(restore(f, remove, 4, 3 if child_first else 2))
            require(visible(f, identity) == child_first and children(f) == original, "Parent restore retains child state, does not replay recovery")
            if child_first:
                sql(f"update sync_private.milestone_shadow set fields=jsonb_set(fields,'{{existence,value}}','false'),delete_operation_id='{uid()}' where owner_id='{f.owner}';")
                f.apply(deletion(f, 5, observed(4, True)))
                remove_again = json.loads(sql(f"select operation from sync_private.task_deletions where owner_id='{f.owner}' and revision=5;"))
                own_tombstone = children(f)
                f.apply(restore(f, remove_again, 6, 5))
                require(not visible(f, identity) and children(f) == own_tombstone, "Parent restore never removes an independent child tombstone fixture")
        f = TaskFixture(backend, epoch)
        f.apply(f.create())
        rival = uid()
        f.register(rival)
        child, remove = milestone(f), deletion(f, 1)
        remove["device_epoch"] = rival
        with ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(f.apply, (child, remove)))
        require(not visible(f, child["entity"]["key"][0]), "Concurrent delete/create cannot expose a child of a deleted task")
        passed_check("both parent-delete orders, concurrent deletion, restore and independent child tombstone fixture")

        f, other = TaskFixture(backend, epoch), TaskFixture(backend, epoch)
        f.apply(f.create(), milestone(f))
        before = state(f)
        foreign = milestone(other, 1, parent=f.task)
        missing = milestone(other, 2, parent=uid())
        require([receipt(other, op)["disposition"] for op in (foreign, missing)] == ["conflict", "conflict"], "Foreign parent is indistinguishable from missing")
        require(state(f) == before and not children(other), "Cross-owner create cannot affect X")
        require(not visible(other, children(f)[0]["milestone_id"]), "Visibility helper cannot read another account")
        for token in (None, f.token, other.token):
            for method, body in (("GET", None), ("POST", {}), ("PATCH", {}), ("DELETE", None)):
                code, _ = backend.request(method, "/rest/v1/milestone_shadow", token, body)
                require(code in (401, 403, 404), "No raw REST milestone bypass")
        require(sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claim.sub','{other.owner}',true) is not null; "
            f"select count(*) from sync_private.milestone_shadow where owner_id='{f.owner}'; "
            "do $test$ begin begin insert into sync_private.milestone_shadow(owner_id,milestone_id,task_id,fields,creation_operation) "
            f"values ('{f.owner}','{uid()}','{f.task}','{{}}','{{}}'); "
            "raise exception 'Foreign insert allowed'; exception when insufficient_privilege then null; end; end $test$; rollback;").splitlines() == ["t", "0"], "Forced RLS denies direct foreign read/write")
        require(sql("select has_table_privilege('dourstuff_rpc','sync_private.milestone_shadow','update') "
                    "or has_table_privilege('dourstuff_rpc','sync_private.milestone_shadow','delete') "
                    "or has_function_privilege('authenticated','sync_private.milestone_visible(uuid)','execute') "
                    "or has_function_privilege('anon','sync_private.milestone_parent_decision(jsonb)','execute');") == "f", "Creation-only grants and private helpers")
        passed_check("X/Y/anonymous isolation, forced RLS and restricted helper/table grants")

        f = TaskFixture(backend, epoch)
        parent = f.create()
        child = milestone(f, dependency=parent)
        before = state(f)
        try:
            sql("create function sync_private.fail_milestone_test() returns trigger language plpgsql as $$ "
                "begin if new.revision=2 then raise exception 'injected milestone test failure'; end if; return new; end $$; "
                "create trigger fail_milestone_test before insert on sync_private.change_log "
                "for each row execute function sync_private.fail_milestone_test();")
            code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(parent, child)})
            require(code >= 400 and state(f) == before, "Failure rolls back parent, child, history, recovery, receipts and progress")
        finally:
            sql("drop trigger if exists fail_milestone_test on sync_private.change_log; drop function if exists sync_private.fail_milestone_test();")
        require(all(r["disposition"] == "applied" for r in f.apply(parent, child)["result"]["results"]), "Exact original batch retry succeeds")
        passed_check("injected child-log failure rolls back the entire parent/child transaction")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} milestone creation integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

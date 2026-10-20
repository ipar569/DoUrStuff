"""Real local HTTP/JWT apply tests; synthetic users are removed in finally.

SQL seeds legacy canonical state for focused edit regressions. The separate
test_backend_task_create.py harness creates tasks only through HTTP.
No remote endpoint, credentials, or task content is printed.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import time
import uuid

from test_backend_foundation import Backend, DB, literal, require, sql


def uid():
    return str(uuid.uuid4())


def observed(revision, value):
    return {"kind": "observed", "revision": revision, "value": value}


def predecessor(op, value):
    return {"kind": "predecessor", "operation_id": op["operation_id"],
            "sequence": op["sequence"], "value": value}


class Fixture:
    def __init__(self, backend, epoch, device=None):
        self.backend, self.epoch = backend, epoch
        self.owner, self.token = backend.create_user()
        self.device, self.task = device or uid(), uid()
        backend.rpc("register_device", self.token, {"protocol_version": 2,
                    "device_epoch": self.device, "server_epoch": epoch})
        self.seed(self.task, "X", 1)
        sql(f"update sync_private.account_state set revision=2 where owner_id='{self.owner}';"
            f"insert into sync_private.change_log(owner_id,revision,records,recovery) "
            f"values ('{self.owner}',1,'[]','[]'),('{self.owner}',2,'[]','[]');")

    def seed(self, task, title, revision, deleted=False):
        fields = {"title": {"revision": revision, "value": title},
                  "priority": {"revision": 1, "value": "none"},
                  "existence": {"revision": 1, "value": not deleted}}
        deletion = literal(uid()) if deleted else "null"
        sql(f"insert into sync_private.task_shadow(owner_id,task_id,fields,delete_operation_id) "
            f"values ('{self.owner}','{task}',{literal(json.dumps(fields))}::jsonb,{deletion});")

    def op(self, seq, value, base=None, task=None, group="title"):
        return {"protocol_version": 2, "operation_id": uid(), "device_epoch": self.device,
                "sequence": seq, "entity": {"kind": "task", "key": [task or self.task]},
                "command": "task.edit", "patches": {group: {
                    "base": base if base is not None else observed(1, "X"), "value": value}},
                "dependencies": [], "provenance": {"occurred_at": 100 - seq}}

    def request(self, *ops):
        return {"protocol_version": 2, "server_epoch": self.epoch,
                "after_revision": 2, "operations": list(ops)}

    def apply(self, *ops):
        return self.backend.rpc("apply", self.token, self.request(*ops))

    def state(self):
        # Full synthetic state lets rollback/retry assertions detect stray rows.
        tables = ["account_state", "device_state", "task_shadow", "operation_receipts",
                  "recovery_candidates", "change_log", "task_status_history"]
        return [sql(f"select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]') "
                    f"from sync_private.{table} t where owner_id='{self.owner}';") for table in tables]

    def fields(self, task=None):
        return json.loads(sql(f"select fields from sync_private.task_shadow "
                              f"where owner_id='{self.owner}' and task_id='{task or self.task}';"))

    def pull(self, after=2):
        return self.backend.rpc("pull", self.token, {"protocol_version": 2,
            "after": {"server_epoch": self.epoch, "revision": after}, "limit": 200})["result"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--supabase", default="supabase")
    parser.add_argument("--wire-output", type=Path)
    args = parser.parse_args()
    # Verify pinned images, project identity and localhost bindings before auth.
    subprocess.run(["python", str(Path(__file__).with_name("local_backend.py"))], check=True)
    backend = Backend(args.supabase)
    epoch = sql("select server_epoch from sync_private.backend_state;")
    passed = 0

    def passed_check(label):
        nonlocal passed
        passed += 1
        print("PASS: " + label, flush=True)

    try:
        fixture_path = Path(__file__).resolve().parents[1] / "test/fixtures/account-protocol-v2-chain.json"
        chain = json.loads(fixture_path.read_text(encoding="utf-8"))
        f = Fixture(backend, epoch, chain["operations"][0]["device_epoch"])
        a, b = (chain["operations"][i]["entity"]["key"][0] for i in (0, 2))
        f.seed(a, "Z", 2)
        f.seed(b, "B1", 1)
        chain["server_epoch"] = epoch
        result = backend.rpc("apply", f.token, chain)["result"]
        require([r["disposition"] for r in result["results"]] == ["conflict", "held", "applied"],
                "Conflict/dependent/unrelated chain")
        require(result["device_high_water"] == 3 and result["cursor"]["revision"] == 5,
                "Every terminal operation consumes one contiguous sequence and revision")
        require(f.fields(a)["title"]["value"] == "Z" and f.fields(b)["title"]["value"] == "B2",
                "Conflicting title preserved and unrelated edit advances despite backwards device clocks")
        groups = f.pull()["groups"]
        require([g["revision"] for g in groups] == [3, 4, 5], "Atomic whole-revision log")
        require([g["recovery"][0]["operation"] for g in groups[:2]] == chain["operations"][:2],
                "Original conflicting and held envelopes retained without rebasing")
        passed_check("real PostgreSQL conflict/held/unrelated fixture and immutable recovery payloads")

        before = f.state()
        require(backend.rpc("apply", f.token, chain)["result"] == result, "Dropped reply retry returns original receipts")
        reordered = json.loads(json.dumps(chain, sort_keys=True))
        require(backend.rpc("apply", f.token, reordered)["result"] == result, "Object order is not payload identity")
        changed = deepcopy(chain)
        changed["operations"][0]["provenance"]["occurred_at"] += 1
        require(backend.rpc("apply", f.token, changed)["code"] == "payloadMismatch", "Changed original rejected")
        changed = deepcopy(chain)
        changed["operations"][0]["operation_id"] = uid()
        require(backend.rpc("apply", f.token, changed)["code"] == "payloadMismatch", "Consumed sequence cannot be reused")
        gap = f.apply(f.op(5, "gap"))
        require(gap["code"] == "sequenceGap" and gap["expected_sequence"] == 4, "Gap reports durable expected sequence")
        pending, unsupported = f.op(4, "valid"), f.op(5, [], group="milestone_order")
        require(f.apply(pending, unsupported)["code"] == "unsupportedProtocol", "Whole-batch capability preflight")
        require(f.state() == before, "Retries and preflight failures consume nothing")
        passed_check("lost-response retries, structural identity, payload mismatch, gap and batch preflight")

        accepted = f.op(4, "first")
        dependent = f.op(5, "second", predecessor(accepted, "first"))
        equivalent = f.op(6, "second", observed(1, "X"))
        partial = f.op(7, "conflicting", observed(1, "X"))
        partial["patches"]["priority"] = {"base": observed(1, "none"), "value": "high"}
        corrupt = f.op(8, "corrupt", observed(7, "not the actual base"))
        receipts = f.apply(accepted, dependent, equivalent, partial, corrupt)["result"]["results"]
        require([r["disposition"] for r in receipts] == ["applied", "applied", "applied", "partial", "conflict"],
                "Accepted predecessor, equivalent, partial and corrupt-base decisions")
        require(receipts[1]["fields"][0]["accepted"]["revision"] == 7 and
                receipts[2]["fields"][0]["disposition"] == "equivalent" and
                receipts[4]["fields"][0]["disposition"] == "recovery", "Actual accepted revisions bind predecessors")
        require(f.fields()["title"]["value"] == "second" and f.fields()["priority"]["value"] == "high",
                "Unrelated field survives same-operation conflict")
        passed_check("actual predecessor revision binding, equivalence, partial merge and corrupt-base recovery")

        invalid = f.op(9, " \t\n")
        after_invalid = f.op(10, "dependent", predecessor(invalid, " \t\n"))
        receipts = f.apply(invalid, after_invalid)["result"]["results"]
        require(receipts[0]["disposition"] == "rejected" and receipts[0]["rejection_code"] == "invalid_title",
                "Invalid semantic value is terminal, not endlessly retried")
        require(receipts[1]["fields"][0]["disposition"] == "recovery", "Rejected predecessor never binds")
        retained = f.state()
        f.apply(invalid, after_invalid)
        require(f.state() == retained, "Terminal rejection retry has no extra writes")
        sql(f"delete from sync_private.operation_receipts where owner_id='{f.owner}';")
        retained = f.state()
        expired = backend.rpc("apply", f.token, chain)["result"]
        require(all(r["kind"] == "already_processed" for r in expired["results"]), "Expired receipts never replay")
        require(f.state() == retained, "Expired retry leaves canonical state, log and candidates intact")
        held = f.op(11, "still held", predecessor(chain["operations"][1], "W"), task=a)
        lost_predecessor = f.op(12, "cannot bind", predecessor(dependent, "second"))
        receipts = f.apply(held, lost_predecessor)["result"]["results"]
        require(receipts[0]["fields"][0]["disposition"] == "held" and
                receipts[1]["fields"][0]["disposition"] == "recovery", "Retained held identity and expired accepted predecessor")
        passed_check("terminal rejection, receipt expiry, retained held candidates and no replay")

        deleted = uid()
        f.seed(deleted, "deleted", 1, deleted=True)
        stale = f.op(13, "resurrect", observed(1, "deleted"), task=deleted)
        require(f.apply(stale)["result"]["results"][0]["fields"][0]["disposition"] == "recovery",
                "Edit cannot resurrect deleted task")
        require(f.fields(deleted)["existence"]["value"] is False, "Deletion identity remains authoritative")
        other = Fixture(backend, epoch)
        stolen = other.op(1, "cross owner", task=a)
        receipt = other.apply(stolen)["result"]["results"][0]
        require(receipt["disposition"] == "rejected" and receipt["rejection_code"] == "entity_missing",
                "Cross-owner task is indistinguishable from missing task")
        require(other.pull()["groups"][0]["recovery"][0]["canonical"] is None, "No owner-X canonical data leaks to Y")
        claim = literal(json.dumps({"sub": other.owner, "role": "authenticated"}))
        rls = sql(f"begin; set local role dourstuff_rpc; select set_config('request.jwt.claims',{claim},true) is not null;" +
            "".join(f"select count(*) from sync_private.{table} where owner_id='{f.owner}';" for table in
                    ("task_shadow", "operation_receipts", "recovery_candidates", "change_log")) +
            f"with changed as (update sync_private.task_shadow set fields='{{}}' where owner_id='{f.owner}' returning *) "
            "select count(*) from changed; rollback;")
        require(rls.splitlines() == ["t", "0", "0", "0", "0", "0"], "RLS isolates every apply table")
        # The role can insert own records but cannot forge owner X on any table.
        for table in ("task_shadow", "operation_receipts", "recovery_candidates"):
            row = sql(f"select to_jsonb(t) from sync_private.{table} t where owner_id='{f.owner}' limit 1;")
            require(bool(row), "Cross-owner RLS fixture exists")
            sql(f"begin; set local role dourstuff_rpc; "
                f"do $test$ begin perform set_config('request.jwt.claims',{claim},true); begin "
                f"insert into sync_private.{table} select * from jsonb_populate_record("
                f"null::sync_private.{table},{literal(row)}::jsonb); "
                "raise exception 'Cross-owner insert was allowed'; "
                "exception when insufficient_privilege then null; end; end $test$; rollback;")
        require(sql("""select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
            where n.nspname='public' and p.proname='sync_apply' and p.prosecdef
            and p.proowner='dourstuff_rpc'::regrole and p.proconfig @> array['search_path=""']
            and not has_function_privilege('anon',p.oid,'execute');""") == "1",
                "Apply uses restricted function owner, fixed search path and execute grants")
        status, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", body={"request": f.request(stale)})
        require(status in (401, 403), "Anonymous apply denied")
        passed_check("delete/edit recovery, cross-owner apply isolation, real RLS and anonymous denial")

        g = Fixture(backend, epoch)
        operation = g.op(1, "atomic")
        before = g.state()
        trigger = "test_fault_" + uuid.uuid4().hex
        try:
            sql(f"create function sync_private.{trigger}() returns trigger language plpgsql as $$ "
                f"begin if new.owner_id='{g.owner}'::uuid then raise exception 'Injected test failure'; "
                "end if; return new; end $$; "
                f"create trigger {trigger} before insert on sync_private.change_log "
                f"for each row execute function sync_private.{trigger}();")
            status, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", g.token, {"request": g.request(operation)})
            require(status == 400, "Injected write failure reached HTTP boundary")
            require(g.state() == before, "Failure rolls back fields, receipts, recovery, revision and high-water")
        finally:
            sql(f"drop trigger if exists {trigger} on sync_private.change_log; "
                f"drop function if exists sync_private.{trigger}();")
        with ThreadPoolExecutor(max_workers=2) as pool:
            replies = list(pool.map(lambda _: g.apply(operation), range(2)))
        require(replies[0] == replies[1], "Concurrent identical retries return one durable receipt")
        require(len(g.pull()["groups"]) == 1, "Exactly one commit after failed transaction and concurrent retry")
        passed_check("injected mid-write rollback and concurrent duplicate HTTP apply")

        # Hold a row lock after allocating an uncommitted revision. HTTP apply
        # must wait and allocate its revision only after that writer commits.
        writer = subprocess.Popen(["docker", "exec", "-i", DB, "psql", "-XqAt", "-U", "postgres",
                                   "-d", "postgres", "-v", "ON_ERROR_STOP=1"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        pool = ThreadPoolExecutor(max_workers=1)
        try:
            writer.stdin.write(f"begin; update sync_private.account_state set revision=4 where owner_id='{g.owner}'; "
                f"insert into sync_private.change_log(owner_id,revision,records,recovery) values ('{g.owner}',4,'[]','[]');\n"
                "\\echo LOCKED\n")
            writer.stdin.flush()
            require(writer.stdout.readline().strip() == "LOCKED", "Late writer holds account lock")
            future = pool.submit(g.apply, g.op(2, "after late commit", observed(3, "atomic")))
            deadline = time.monotonic() + 10
            while sql("select count(*) from pg_stat_activity where wait_event_type='Lock' and query like '%sync_apply%';") == "0":
                require(time.monotonic() < deadline, "HTTP apply waits on real account lock")
                time.sleep(0.1)
            require(not future.done(), "Apply cannot publish past an uncommitted revision")
            require(other.pull()["committed_high_water"] == 3, "Other account stays independent")
            writer.stdin.write("commit;\n\\q\n")
            writer.stdin.flush()
            writer.wait(timeout=10)
            require(writer.returncode == 0, "Late writer commits")
            require(future.result(timeout=15)["result"]["cursor"]["revision"] == 5, "Apply follows committed revision")
        finally:
            if writer.poll() is None:
                writer.stdin.write("rollback;\n\\q\n")
                writer.stdin.flush()
                writer.wait(timeout=10)
            pool.shutdown(wait=True, cancel_futures=True)
        require([r["revision"] for r in g.pull()["groups"]] == [3, 4, 5], "No late-commit cursor gap")
        passed_check("real HTTP apply waits for late commit and preserves ordered account cursors")

        before = g.state()
        good = g.op(3, "valid", observed(5, "after late commit"))
        malformed = []
        for key in good:
            op = deepcopy(good)
            op[key] = None
            malformed.append(g.request(op))
        for value in (-1, 0, 2.0, "3", 9007199254740992):
            op = deepcopy(good)
            op["sequence"] = value
            malformed.append(g.request(op))
        for value in (None, "task", [], {}, {"kind": None, "key": [g.task]}, {"kind": "task", "key": None}):
            op = deepcopy(good)
            op["entity"] = value
            malformed.append(g.request(op))
        for value in (None, [], "base", {"kind": "observed", "revision": "invalid", "value": "X"}):
            op = deepcopy(good)
            op["patches"]["title"]["base"] = value
            malformed.append(g.request(op))
        malformed.append(g.request(g.op(3, "x" * 65536)))
        for value in (1.5, 9007199254740992, {"nested": [[[[[[[[[[[[[[[[[0]]]]]]]]]]]]]]]]]}):
            op = deepcopy(good)
            op["provenance"]["unsafe"] = value
            malformed.append(g.request(op))
        malformed.append(g.request(*[g.op(i, "valid") for i in range(3, 36)]))
        large_batch = [g.op(i, "valid") for i in range(3, 35)]
        for op in large_batch:
            op["provenance"]["padding"] = "x" * 34000
        malformed.append(g.request(*large_batch))
        for request in malformed:
            status, reply = backend.request("POST", "/rest/v1/rpc/sync_apply", g.token, {"request": request})
            require(status == 400 or (status == 200 and reply.get("code") == "unsupportedProtocol"),
                    "Malformed envelope fails without internal errors")
        require(g.state() == before, "Malformed requests consume nothing")
        for request, code in ((dict(g.request(good), server_epoch=uid()), "serverEpochChanged"),
                              (dict(g.request(good), protocol_version=1), "unsupportedProtocol")):
            require(backend.rpc("apply", g.token, request)["code"] == code, "Typed epoch/version failure")
        passed_check("strict malformed/null/type/size validation and no sequence consumption")

        # Exact canonical UTF-8 byte limit (Unicode object order is irrelevant
        # to byte count and JSONB identity). Keep original semantic values intact.
        boundary = f.op(14, "boundary", observed(7, "second"))
        boundary["provenance"] = {"😀": "e\u0301", "\ue000": "é", "padding": ""}
        encode = lambda value: json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
        boundary["provenance"]["padding"] = "x" * (65536 - len(encode(boundary)))
        require(len(encode(boundary)) == 65536, "Exact operation byte boundary fixture")
        oversized = deepcopy(boundary)
        oversized["provenance"]["padding"] += "x"
        status, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(oversized)})
        require(status == 400, "One byte over operation limit is denied before consumption")
        first = f.apply(boundary)
        require(first["result"]["results"][0]["disposition"] == "applied", "Exact byte limit accepted")
        require(f.apply(json.loads(json.dumps(boundary, sort_keys=True))) == first, "Unicode payload identity survives retry")
        passed_check("exact 64-KiB UTF-8 operation boundary and Unicode payload identity")

        # Compare shared Dart title rules: trimmed nonempty, <=500 UTF-16 units.
        unicode_values = [("😀" * 250, True), ("😀" * 250 + "a", False),
                          ("\ufeff\u0085 X \u3000", True), ("\ufeff\u0085\u3000", False),
                          ("v", True), ("\u000b", False)]
        for sequence, (title, valid) in enumerate(unicode_values, start=3):
            op = g.op(sequence, title, {"kind": "absent"}, group="title")
            receipt = g.apply(op)["result"]["results"][0]
            require((receipt["disposition"] != "rejected") == valid, "UTF-16 and whitespace semantic boundary")
        sql(f"update sync_private.account_state set retained_after=3 where owner_id='{g.owner}';")
        require(g.apply(g.op(9, "expired"))["code"] == "cursorExpired", "Expired apply cursor consumes nothing")
        sql(f"update sync_private.account_state set revoked_at=now() where owner_id='{g.owner}';")
        require(g.apply(g.op(9, "revoked"))["code"] == "accountDeleted", "Revoked account cannot apply")
        passed_check("UTF-16/Unicode title boundaries, expired cursor and revoked-account apply")

        nested = 0
        for _ in range(12):
            nested = [nested]
        deep = f.op(15, "deep conflict", observed(1, "X"))
        deep["provenance"] = {"nested": nested}
        require(f.apply(deep)["result"]["results"][0]["disposition"] == "conflict",
                "Maximum request-depth provenance can enter recovery")
        require(f.pull(16)["groups"][0]["recovery"][0]["operation"] == deep,
                "Pull retains the entire nested original operation")
        passed_check("maximum-depth accepted request retained through real conflict/pull")

        # Capture every successful apply and pull response for production Dart decoding.
        f.pull()
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{passed} apply integration groups passed; synthetic accounts will be cleaned up.")
    finally:
        backend.cleanup()


if __name__ == "__main__":
    main()

"""Real local Supabase checks. Creates/deletes only this run's synthetic users.

No credentials or response bodies are printed. No remote endpoint is accepted.
The fixture writers exercise PostgreSQL locks; test_backend_apply.py checks apply.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import secrets
import subprocess
import time
import urllib.error
import urllib.request
import uuid

DB = "supabase_db_dourstuff-local"
PROJECT = "dourstuff-local"


def command(args, source=None):
    # Docker/psql and the Supabase CLI emit UTF-8, even when Windows' Python
    # defaults to CP1252. Input SQL must use the same explicit encoding.
    result = subprocess.run(args, input=source, encoding="utf-8", capture_output=True, timeout=60)
    if result.returncode:
        # Never include subprocess output: CLI status and SQL may contain secrets.
        raise RuntimeError(f"Local command failed (exit {result.returncode})")
    return result.stdout.strip()


def sql(source):
    return command(["docker", "exec", "-i", DB, "psql", "-XqAt", "-U", "postgres",
                    "-d", "postgres", "-v", "ON_ERROR_STOP=1"], source)


def literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def require(condition, label):
    if not condition:
        raise AssertionError(label)


class RejectRedirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError("Local backend redirects are forbidden")


class Backend:
    def __init__(self, executable):
        state = json.loads(command([executable, "status", "-o", "json"]))
        self.url = state["API_URL"]
        require(self.url == "http://127.0.0.1:54321", "Only the fixed local test endpoint is allowed")
        self.anon = state["ANON_KEY"]
        self.admin = state["SERVICE_ROLE_KEY"]
        # Local credentials must never follow environment proxies or redirects.
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), RejectRedirects())
        self.users = []
        self.wire = []

    def request(self, method, path, token=None, body=None, headers=None):
        request = urllib.request.Request(
            self.url + path,
            data=None if body is None else json.dumps(body).encode(),
            headers={"apikey": self.anon, "Content-Type": "application/json",
                     **({"Authorization": "Bearer " + token} if token else {}), **(headers or {})},
            method=method,
        )
        try:
            with self.opener.open(request, timeout=20) as response:
                data = response.read()
                return response.status, json.loads(data) if data else None
        except urllib.error.HTTPError as error:
            data = error.read()
            try:
                parsed = json.loads(data)
            except ValueError:
                parsed = None
            return error.code, parsed

    def create_user(self):
        email = "foundation-" + uuid.uuid4().hex + "@example.invalid"
        password = secrets.token_urlsafe(32)
        status, user = self.request("POST", "/auth/v1/admin/users", self.admin,
                                    {"email": email, "password": password, "email_confirm": True})
        require(status == 200, "Synthetic Auth user creation")
        user_id = str(uuid.UUID(user["id"]))
        self.users.append(user_id)
        status, session = self.request("POST", "/auth/v1/token?grant_type=password", body={
            "email": email, "password": password})
        require(status == 200, "Synthetic Auth login")
        return user_id, session["access_token"]

    def rpc(self, name, token, request):
        status, reply = self.request("POST", "/rest/v1/rpc/sync_" + name, token, {"request": request})
        detail = ""
        if status != 200 and isinstance(reply, dict):
            denied = re.search(r"permission denied for (?:schema|table|function) [a-z_]+", reply.get("message", ""))
            detail = "; " + denied.group(0) if denied else ""
        require(status == 200, f"{name} HTTP success (got {status}{detail})")
        if reply.get("status") == "success":
            self.wire.append({"rpc": name, "request": request, "reply": reply})
        return reply

    def cleanup(self):
        failed = False
        for owner in self.users:
            status, _ = self.request("DELETE", "/auth/v1/admin/users/" + owner, self.admin)
            failed |= status not in (200, 404)
            sql(f"delete from sync_private.account_state where owner_id={literal(owner)}::uuid;")
        require(not failed, "Synthetic account cleanup")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--supabase", default="supabase")
    parser.add_argument("--wire-output", type=Path)
    args = parser.parse_args()
    container = json.loads(command(["docker", "inspect", DB]))[0]
    require(container["Config"]["Labels"].get("com.supabase.cli.project") == PROJECT,
            "Database project identity")
    require(container["State"]["Running"], "Local database is running")
    for name in (DB, "supabase_kong_" + PROJECT, "supabase_studio_" + PROJECT,
                 "supabase_inbucket_" + PROJECT):
        info = json.loads(command(["docker", "inspect", name]))[0]
        require(all(p["HostIp"] == "127.0.0.1" for ports in
                    info["NetworkSettings"]["Ports"].values() if ports for p in ports),
                "Every published service must be loopback-only")
    backend = Backend(args.supabase)
    passed = 0

    def passed_check(label):
        nonlocal passed
        passed += 1
        print("PASS: " + label, flush=True)

    try:
        # Rebuild only the application schema inside a rollback-only transaction.
        # The live provider auth schema and original application state survive.
        before_epoch = sql("select server_epoch from sync_private.backend_state;")
        migration_dir = Path(__file__).resolve().parents[1] / "supabase" / "migrations"
        bootstrap = (migration_dir / "20261016000100_account_foundation.sql").read_text(encoding="utf-8")
        fixture_owner, fixture_device = str(uuid.uuid4()), str(uuid.uuid4())
        fixture_task, fixture_op, expired_op = (str(uuid.uuid4()) for _ in range(3))
        original = {"protocol_version": 2, "operation_id": fixture_op, "device_epoch": fixture_device,
                    "sequence": 7, "entity": {"kind": "task", "key": [fixture_task]},
                    "command": "task.status", "patches": {"status_group": {
                        "base": {"kind": "observed", "revision": 3,
                                 "value": {"status": "todo", "completed_at": None}},
                        "value": {"status": "completed", "completed_at": 100}}},
                    "dependencies": [], "provenance": {"occurred_at": 100}}
        # Seed durable history immediately after 004, before 005 adds payload
        # retention. One old event still has its receipt; another has expired it.
        history_fixture = (
            f"insert into sync_private.task_shadow(owner_id,task_id,fields) values ('{fixture_owner}','{fixture_task}','{{}}');\n"
            f"insert into sync_private.operation_receipts(owner_id,device_epoch,sequence,operation_id,operation,receipt) "
            f"values ('{fixture_owner}','{fixture_device}',7,'{fixture_op}',{literal(json.dumps(original))}::jsonb,'{{}}');\n"
            "insert into sync_private.task_status_history(owner_id,task_id,operation_id,revision,previous_status,status,fields,provenance) values "
            f"('{fixture_owner}','{fixture_task}','{fixture_op}',7,null,'{{}}','{{}}','{{}}'),"
            f"('{fixture_owner}','{fixture_task}','{expired_op}',6,null,'{{}}','{{}}','{{}}');\n")
        upgrade = "\n".join(path.read_text(encoding="utf-8") +
                            (history_fixture if path.name == "20261018000100_task_create_status.sql" else "")
                            + (f"update sync_private.task_shadow set fields="
                               f"'{{\"due\":{{\"revision\":7,\"value\":{{\"kind\":\"date\",\"date\":\"2026-10-20\"}}}}}}'::jsonb "
                               f"where owner_id='{fixture_owner}';"
                               if path.name == "20261019074608_task_description_estimate.sql" else "")
                            for path in sorted(migration_dir.glob("*.sql"))
                            if path.name != "20261016000100_account_foundation.sql")
        migration_result = sql("begin; drop function if exists public.sync_apply(jsonb); "
            "drop function if exists public.sync_snapshot_begin(jsonb); "
            "drop function if exists public.sync_snapshot_page(jsonb); "
            "drop function public.sync_register_device(jsonb); "
            "drop function public.sync_pull(jsonb); drop schema sync_private cascade;\n" + bootstrap +
            f"insert into sync_private.account_state(owner_id) values ('{fixture_owner}');\n"
            f"insert into sync_private.device_state(owner_id,device_epoch,high_water) "
            f"values ('{fixture_owner}','{fixture_device}',7);\n" + upgrade +
            f"select high_water from sync_private.device_state where owner_id='{fixture_owner}'; "
            f"select operation={literal(json.dumps(original))}::jsonb from sync_private.task_status_history "
            f"where owner_id='{fixture_owner}' and operation_id='{fixture_op}'; "
            f"select operation is null from sync_private.task_status_history "
            f"where owner_id='{fixture_owner}' and operation_id='{expired_op}'; "
            f"select fields->'due'='{{\"revision\":7,\"value\":{{\"kind\":\"date\",\"date\":\"2026-10-20\"}}}}'::jsonb "
            f"from sync_private.task_shadow where owner_id='{fixture_owner}'; rollback;")
        require(migration_result.splitlines() == ["7", "t", "t", "t"],
                "Empty app-schema and forward upgrade preserve watermark, history and exact available original bases")
        require(sql("select server_epoch from sync_private.backend_state;") == before_epoch,
                "Migration rehearsal rolls back without replacing existing state")
        passed_check("empty application schema and retained-data forward migration, rolled back safely")

        x, xt = backend.create_user()
        y, yt = backend.create_user()
        epoch = sql("select server_epoch from sync_private.backend_state;")
        device = str(uuid.uuid4())
        register = {"protocol_version": 2, "device_epoch": device, "server_epoch": epoch}
        pull = lambda after=0, limit=200: {"protocol_version": 2,
            "after": {"server_epoch": epoch, "revision": after}, "limit": limit}
        expected = {"protocol_version": 2, "status": "success", "result": {
            "cursor": {"server_epoch": epoch, "revision": 0}, "high_water": 0}}
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: backend.rpc("register_device", xt, register), range(2)))
        require(results == [expected, expected], "Concurrent registration is idempotent")
        require(sql(f"select count(*) from sync_private.device_state where owner_id={literal(x)};") == "1",
                "Exactly one device after concurrent registration")
        require(backend.rpc("register_device", yt, register) == expected, "Device identity is owner scoped")
        passed_check("concurrent duplicate registration and account-qualified device identity")

        for token in (None,):
            for name, request in (("register_device", register), ("pull", pull())):
                status, _ = backend.request("POST", "/rest/v1/rpc/sync_" + name, token, {"request": request})
                require(status in (401, 403), "Anonymous RPC denied")
        for token in (None, xt, yt):
            for table in ("account_state", "device_state", "change_log", "backend_state",
                          "task_shadow", "operation_receipts", "recovery_candidates"):
                for method, body in (("GET", None), ("POST", {"owner_id": x}),
                                     ("PATCH", {"owner_id": y}), ("DELETE", None)):
                    status, _ = backend.request(method, "/rest/v1/" + table, token, body)
                    require(status in (401, 403, 404), "Private tables are not a raw REST bypass")
                status, _ = backend.request("GET", "/rest/v1/" + table, token,
                                            headers={"Accept-Profile": "sync_private"})
                require(status in (401, 403, 406), "Private schema is not exposed")
        passed_check("anonymous RPC and anonymous/X/Y raw REST read/write/schema bypass denial")

        for version in (1, "2", 2.0):
            changed = dict(register, protocol_version=version)
            require(backend.rpc("register_device", xt, changed)["code"] == "unsupportedProtocol",
                    "Unsupported protocol type/version")
        for changed in (dict(register, owner_id=y), {k: v for k, v in register.items() if k != "device_epoch"},
                        dict(register, device_epoch="invalid")):
            status, _ = backend.request("POST", "/rest/v1/rpc/sync_register_device", xt, {"request": changed})
            require(status == 400, "Malformed registration denied")
        require(backend.rpc("register_device", xt, dict(register, server_epoch=str(uuid.uuid4())))["code"]
                == "serverEpochChanged", "Wrong epoch denied")
        for changed in (pull(-1), pull(0, 201), pull(9007199254740992), pull(1)):
            status, _ = backend.request("POST", "/rest/v1/rpc/sync_pull", xt, {"request": changed})
            require(status == 400, "Invalid pull counters denied")
        passed_check("strict request validation and wrong-server-epoch failures")

        # Validate RLS itself under the actual non-owner, non-bypass function role.
        claim = literal(json.dumps({"sub": x, "role": "authenticated"}))
        rls = sql(f"""begin;
          set local role dourstuff_rpc;
          select set_config('request.jwt.claims', {claim}, true) is not null;
          select count(*) from sync_private.account_state where owner_id={literal(y)};
          select count(*) from sync_private.device_state where owner_id={literal(y)};
          with changed as (update sync_private.account_state set revision=1
            where owner_id={literal(y)} returning *) select count(*) from changed;
          do $test$ begin
            begin
              insert into sync_private.device_state(owner_id,device_epoch)
                values ({literal(y)},'{uuid.uuid4()}');
              raise exception 'Cross-owner insert was allowed';
            exception when insufficient_privilege then null; end;
          end $test$;
          rollback;""")
        require(rls.splitlines() == ["t", "0", "0", "0"], "RLS read/update isolation")
        require(sql("""select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
            where n.nspname='public' and p.proname in ('sync_register_device','sync_pull')
            and p.prosecdef and p.proowner='dourstuff_rpc'::regrole
            and p.proconfig @> array['search_path=""']
            and not has_function_privilege('anon',p.oid,'execute');""") == "2",
                "Restricted function owner, fixed search path and execute grants")
        require(sql("select rolcanlogin or rolsuper or rolbypassrls from pg_roles where rolname='dourstuff_rpc';")
                == "f", "RPC role cannot bypass RLS")
        passed_check("real RLS ownership and restricted SECURITY DEFINER role")

        record_id = str(uuid.uuid4())
        def records(revision):
            return json.dumps([{"entity": {"kind": "task", "key": [record_id]},
                "fields": {"title": {"revision": revision, "value": "Synthetic revision " + str(revision)}},
                "delete_operation_id": None}])

        # A fixture writer holds revision 1 uncommitted. A second writer must wait
        # on the account row; another account must remain readable meanwhile.
        first = subprocess.Popen(["docker", "exec", "-i", DB, "psql", "-XqAt", "-U", "postgres",
                                  "-d", "postgres", "-v", "ON_ERROR_STOP=1"],
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        assert first.stdin and first.stdout
        first.stdin.write(f"""begin;
          update sync_private.account_state set revision=1 where owner_id={literal(x)};
          insert into sync_private.change_log(owner_id,revision,records,recovery)
            values ({literal(x)},1,{literal(records(1))}::jsonb,'[]');
          \\echo LOCKED
        """)
        first.stdin.flush()
        require(first.stdout.readline().strip() == "LOCKED", "First writer acquired account lock")
        application = "foundation_" + uuid.uuid4().hex
        pool = ThreadPoolExecutor(max_workers=2)
        try:
            second = pool.submit(sql, f"""set application_name={literal(application)}; begin;
                  update sync_private.account_state set revision=revision+1 where owner_id={literal(x)};
                  insert into sync_private.change_log(owner_id,revision,records,recovery)
                    select owner_id,revision,{literal(records(2))}::jsonb,'[]'
                    from sync_private.account_state where owner_id={literal(x)};
                  commit;""")
            deadline = time.monotonic() + 10
            while sql(f"select count(*) from pg_stat_activity where application_name={literal(application)} and wait_event_type='Lock';") != "1":
                require(time.monotonic() < deadline, "Second writer waits on account lock")
                time.sleep(0.1)
            require(sql(f"select revision from sync_private.account_state where owner_id={literal(x)};") == "0",
                    "Uncommitted high-water invisible")
            require(backend.rpc("pull", yt, pull())["result"]["groups"] == [], "Other account remains independent")
            reader = pool.submit(backend.rpc, "pull", xt, pull())
            time.sleep(0.2)
            require(not reader.done(), "Pull cannot pass an uncommitted account writer")
            first.stdin.write("commit;\n\\q\n")
            first.stdin.flush()
            first.wait(timeout=10)
            require(first.returncode == 0, "First writer committed")
            second.result(timeout=10)
            require(reader.result(timeout=10)["status"] == "success", "Waiting pull completes after commit")
        finally:
            if first.poll() is None:
                first.stdin.write("rollback;\n\\q\n")
                first.stdin.flush()
                first.wait(timeout=10)
            pool.shutdown(wait=True, cancel_futures=True)
        page = backend.rpc("pull", xt, pull(0, 1))["result"]
        require(page["through"]["revision"] == 1 and page["has_more"] and page["committed_high_water"] == 2,
                "First whole revision page")
        page = backend.rpc("pull", xt, pull(1, 1))["result"]
        require(page["through"]["revision"] == 2 and not page["has_more"] and len(page["groups"]) == 1,
                "Second whole revision page")
        require(backend.rpc("pull", xt, pull(2))["result"]["groups"] == [], "Caught-up pull")
        require(backend.rpc("pull", yt, pull())["result"]["groups"] == [], "Y cannot pull X log")
        passed_check("real concurrent transaction ordering, whole-revision pagination and X/Y log isolation")

        sql(f"begin; update sync_private.account_state set retained_after=1 where owner_id={literal(x)}; "
            f"delete from sync_private.change_log where owner_id={literal(x)} and revision=1; commit;")
        require(backend.rpc("pull", xt, pull())["code"] == "cursorExpired", "Expired cursor requires recovery")
        require(backend.rpc("pull", xt, pull(1))["result"]["through"]["revision"] == 2, "Retention boundary remains readable")
        sql(f"delete from sync_private.change_log where owner_id={literal(x)} and revision=2;")
        require(backend.rpc("pull", xt, pull(1))["code"] == "unavailable", "Missing log cannot skip progress")
        passed_check("retention boundary and missing-log fail-closed behavior")

        sql(f"update sync_private.account_state set revoked_at=now() where owner_id={literal(x)};")
        for name, request in (("register_device", register), ("pull", pull(1))):
            require(backend.rpc(name, xt, request)["code"] == "accountDeleted", "Revoked account denied")
        status, _ = backend.request("DELETE", "/auth/v1/admin/users/" + x, backend.admin)
        require(status == 200, "Synthetic auth account deletion")
        require(backend.rpc("register_device", xt, register)["code"] == "accountDeleted", "Old JWT cannot recreate account")
        passed_check("revoked/deleted-account RPC denial, including a still-signed old JWT")

        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
        print(f"{passed} backend integration groups passed; synthetic accounts will be cleaned up.")
    finally:
        backend.cleanup()


if __name__ == "__main__":
    main()

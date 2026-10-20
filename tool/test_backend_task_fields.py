"""Real local task description/estimate command validation and concurrency."""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import subprocess

from test_backend_apply import observed, predecessor, uid
from test_backend_foundation import Backend, literal, require, sql
from test_backend_task_create import TaskFixture, status


def add_fields(op, description="", estimate=None):
    for group, value in (("description", description), ("estimate_minutes", estimate)):
        op["patches"][group] = {"base": {"kind": "absent"}, "value": value}
    return op


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
        create = add_fields(f.create(), "  first\nsecond 😀  ", 25)
        result = f.apply(create)
        require(result["result"]["results"][0]["disposition"] == "applied", "Six-group creation")
        require(f.fields()["description"]["value"] == "  first\nsecond 😀  " and
                f.fields()["estimate_minutes"]["value"] == 25, "Description is not trimmed or normalized")
        before = f.state()
        require(f.apply(create) == result and f.state() == before, "Extended creation retries immutable")
        collision = add_fields(f.create(2), "collision", 90)
        require(f.apply(collision)["result"]["results"][0]["disposition"] == "conflict", "Whole-entity create collision")
        require(f.fields()["description"]["value"] == "  first\nsecond 😀  " and
                f.fields()["estimate_minutes"]["value"] == 25, "Collision cannot replace optional fields")
        # Four-group creations remain valid; missing optional groups stay absent,
        # so the first later edit uses AbsentBase rather than fabricated defaults.
        old_shape = f.create(3, task=uid())
        f.apply(old_shape)
        op = f.op(4, "later", {"kind": "absent"}, task=old_shape["entity"]["key"][0], group="description")
        require(f.apply(op)["result"]["results"][0]["disposition"] == "applied", "Legacy core creation accepts first absent field edit")
        passed_check("optional create fields, original shape compatibility, collisions and retries")

        f = TaskFixture(backend, epoch)
        seq = 0
        for value in (0, -1, 5256001, True, "1", [], {}):
            seq += 1
            op = add_fields(f.create(seq, task=uid()), "valid description", value)
            receipt = f.apply(op)["result"]["results"][0]
            require(receipt["rejection_code"] == "invalid_estimate_minutes", "Invalid estimate rejected")
        for value in (None, True, 0, [], {}):
            seq += 1
            op = add_fields(f.create(seq, task=uid()), value, 1)
            require(f.apply(op)["result"]["results"][0]["rejection_code"] == "invalid_description", "Invalid description rejected")
        require(not f.history() and sql(f"select count(*) from sync_private.task_shadow where owner_id='{f.owner}';") == "0",
                "Invalid optional group cannot partially create core fields")
        for value in (None, 1, 5256000):
            seq += 1
            op = add_fields(f.create(seq, task=uid()), "", value)
            require(f.apply(op)["result"]["results"][0]["disposition"] == "applied", "Nullable estimate boundary accepted")
        passed_check("terminal semantic rejection and all-or-nothing extended creation")

        for completion_first in (True, False):
            f = TaskFixture(backend, epoch)
            f.apply(add_fields(f.create(), "base", 1))
            second = uid()
            f.register(second)
            completion = f.set_status(2, status("completed", 50))
            content = f.op(1, "edited", observed(1, "base"), group="description")
            content["device_epoch"] = second
            content["patches"]["estimate_minutes"] = {"base": observed(1, 1), "value": 10}
            for op in ((completion, content) if completion_first else (content, completion)):
                require(f.apply(op)["result"]["results"][0]["disposition"] == "applied", "Completion and optional fields merge")
            require(f.fields()["status_group"]["value"] == status("completed", 50) and
                    f.fields()["description"]["value"] == "edited" and f.fields()["estimate_minutes"]["value"] == 10,
                    "Independent optional edits never reopen")
            snapshot = f.history()[-1]["fields"]
            require(snapshot["description"]["value"] == ("base" if completion_first else "edited"),
                    "History snapshot uses canonical description at completion")
        passed_check("description/estimate versus completion in both server orders")

        f = TaskFixture(backend, epoch)
        f.apply(add_fields(f.create(), "base", 1))
        f.apply(f.op(2, "canonical", observed(1, "base"), group="description"))
        conflict = f.op(3, "candidate", observed(1, "base"), group="description")
        conflict["patches"]["estimate_minutes"] = {"base": observed(1, 1), "value": 5}
        held = f.op(4, "dependent", predecessor(conflict, "candidate"), group="description")
        clear = f.op(5, None, predecessor(conflict, 5), group="estimate_minutes")
        receipts = f.apply(conflict, held, clear)["result"]["results"]
        require([r["disposition"] for r in receipts] == ["partial", "held", "applied"], "Per-group conflict and predecessor binding")
        require(f.fields()["description"]["value"] == "canonical" and
                f.fields()["estimate_minutes"]["value"] is None, "Independent estimate clear survives description conflict")
        groups = f.pull()["groups"]
        require(groups[2]["recovery"][0]["operation"] == conflict and groups[3]["recovery"][0]["operation"] == held,
                "Original bases and held candidates preserved")
        before = f.state()
        changed = deepcopy(clear)
        changed["patches"]["estimate_minutes"]["value"] = 10
        require(f.apply(changed)["code"] == "payloadMismatch" and f.state() == before, "Nullable edit retry immutable")
        other = TaskFixture(backend, epoch)
        op = other.op(1, "foreign", {"kind": "absent"}, task=f.task, group="description")
        require(other.apply(op)["result"]["results"][0]["rejection_code"] == "entity_missing", "Foreign task cannot receive optional fields")
        require(other.pull()["groups"][0]["recovery"][0]["canonical"] is None and f.state() == before, "No owner data leaks or changes")
        passed_check("partial conflicts, dependent field chains, nullable clear and account isolation")

        # The domain permits more text than a single 64-KiB wire operation can
        # carry. Validate the domain limit directly without claiming it uploads.
        for text_value, valid in (("a" * 100000, True), ("a" * 100001, False),
                                  ("😀" * 50000, True), ("😀" * 50000 + "a", False)):
            result = sql(f"select sync_private.valid_description({literal(json.dumps(text_value, ensure_ascii=False))}::jsonb);")
            require(result == ("t" if valid else "f"), "SQL UTF-16 domain description limit")
        f = TaskFixture(backend, epoch)
        op = add_fields(f.create())
        used = len(json.dumps(op, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
        op["patches"]["description"]["value"] = "x" * (65536 - used)
        too_large = deepcopy(op)
        too_large["patches"]["description"]["value"] += "x"
        before = f.state()
        code, _ = backend.request("POST", "/rest/v1/rpc/sync_apply", f.token, {"request": f.request(too_large)})
        require(code == 400 and f.state() == before, "One byte over wire limit consumes nothing")
        require(f.apply(op)["result"]["results"][0]["disposition"] == "applied", "Exact 64-KiB extended create accepted")
        passed_check("UTF-16 description semantics and explicit 64-KiB transport boundary")
        if args.wire_output:
            args.wire_output.write_text(json.dumps(backend.wire, indent=2), encoding="utf-8")
    finally:
        backend.cleanup()
    print(f"{passed} task field integration groups passed; synthetic accounts removed.")


if __name__ == "__main__":
    main()

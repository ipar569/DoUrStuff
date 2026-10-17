"""Check or restart the existing, explicitly loopback-bound local Supabase stack.

Does not initialize/recreate containers, read credentials, or delete volumes.
Fresh CLI startup on the tested Windows host needs the binding repair described
in supabase/README.md before this guard will allow a restart.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time


def docker(*args):
    result = subprocess.run(["docker", *args], text=True, capture_output=True, timeout=30)
    if result.returncode:
        raise RuntimeError("Docker command failed; inspect local runtime availability.")
    return result.stdout.strip()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--start", action="store_true", help="Start only existing verified containers")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    lock = json.loads((root / "supabase/images.lock.json").read_text())
    require(lock["cli_version"] == (root / ".supabase-version").read_text().strip(), "CLI pin mismatch")
    project = lock["project_id"]
    require(int(docker("version", "--format", "{{.Server.Version}}").split(".")[0]) >= 28,
            "Docker Engine 28+ is required")
    names = [f"supabase_{service}_{project}" for service in lock["images"]]
    for service, name in zip(lock["images"], names):
        info = json.loads(docker("inspect", name))[0]
        require(info["Config"]["Labels"].get("com.supabase.cli.project") == project, "Project label mismatch")
        require(info["HostConfig"]["NetworkMode"] == project, "Unexpected container network")
        require(not info["HostConfig"]["PublishAllPorts"], "Unrestricted port publishing is forbidden")
        require(all(p["HostIp"] == "127.0.0.1" for ports in
                    (info["HostConfig"]["PortBindings"] or {}).values() if ports for p in ports),
                f"{name} needs explicit loopback binding before startup")
        require(info["Image"] == lock["images"][service]["image_id"], "Service image differs from tested pin")
        image = json.loads(docker("image", "inspect", info["Image"]))[0]
        require(set(lock["images"][service]["repo_digests"]).issubset(image["RepoDigests"]),
                "Service registry digest differs from tested pin")
    # Include unexpected/backup containers in the exposure check, not just the
    # nine main service names. Stopped originals remain available for recovery.
    running = docker("ps", "-q", "--filter", "label=com.supabase.cli.project=" + project).splitlines()
    for container in running:
        info = json.loads(docker("inspect", container))[0]
        require(all(p["HostIp"] == "127.0.0.1" for ports in
                    info["NetworkSettings"]["Ports"].values() if ports for p in ports),
                "A running project container publishes outside loopback")
    if args.start:
        docker("start", *names)
    deadline = time.monotonic() + (60 if args.start else 0)
    while True:
        states = [json.loads(docker("inspect", name))[0] for name in names]
        ready = all(info["State"]["Running"] and
                    info["State"].get("Health", {}).get("Status", "healthy") == "healthy"
                    for info in states)
        if ready or time.monotonic() >= deadline:
            break
        time.sleep(1)
    require(ready, "Some services are stopped or unhealthy")
    for info in states:
        require(all(p["HostIp"] == "127.0.0.1" for ports in
                    info["NetworkSettings"]["Ports"].values() if ports for p in ports),
                "Actual published bindings differ from the approved configuration")
    print("Nine pinned services running; eight Docker healthchecks healthy; PostgREST running.")
    print("Published ports are loopback-only. Run the integration harness to verify HTTP behavior.")


if __name__ == "__main__":
    main()

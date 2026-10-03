# Two-device test procedure

Phase 3 acceptance gate; not executed in phase 1. Use Android and Windows with
synthetic data, accounts X/Y and a real Supabase development backend.

1. Record Git/app/SDK/dependency/schema/protocol versions, signing identities,
   OS/device versions, IANA zones/tzdata, backend region and RTT.
2. Start guests offline, capture and restart. A phone cannot reach PC localhost:
   use a reachable local-stack endpoint, restricted firewall and correct OAuth
   redirects. Do not expose the development stack publicly.
3. Exercise explicit guest adoption versus keeping guest data, including retry
   after interruption. Verify stable lineage mapping and no silent upload.
4. Perform 100 alternating foreground edits/completions/milestones/priority/view
   changes. Measure local commit to second-device display using calibrated
   clocks or one monotonic harness. Healthy backend, RTT <=150ms, <=10k tasks:
   p95 <=5s; with realtime disabled, polling catch-up p95 <=35s. No refresh.
5. Disconnect both and edit unrelated/same fields, status/content, deletion/edit,
   milestone reorder/add. Reconnect A then B; repeat B then A from clean fixtures.
   Verify convergence and retained conflict alternatives.
6. Inject dropped post-commit responses, duplicates/out-of-order commands,
   interrupted pages/bootstrap, crash, expired auth/cursor, paused/read-only/
   unreachable backend. Local editing must continue; retries must be idempotent.
7. Bootstrap a new profile while creating local tasks; interrupt/restart. Switch
   X to Y with pending work and delayed X callbacks. Inspect DB/token/memory/
   notification isolation. Raw REST/RPC under Y cannot access X's data/logs/
   snapshots/conflicts; anonymous access also fails.
8. In phase 4, generate the same recurrence offline on both devices; edit future
   recurrence while completing an old slot. Verify one logical occurrence,
   retained history and visible superseded-instance recovery.
9. Snooze/complete with one device offline. Record expected stale offline alerts;
   never claim globally exactly-once notification delivery.
10. Record expected/actual results per acceptance criterion, build hashes and
    sanitized evidence. Mock transport tests do not replace this procedure.

Notifications: Android normal close/swipe-away/force-stop/reboot/Doze/battery
saver/OEM limits and denied/revoked/exact permissions; installed Windows MSIX
close/reboot/sleep beyond the five-minute delivery window/suppression/actions/
upgrade. Repeat month-end/DST gap/fold fixtures in Pacific/Auckland, UTC and a
zone with different transitions. Compile success alone is not platform support.

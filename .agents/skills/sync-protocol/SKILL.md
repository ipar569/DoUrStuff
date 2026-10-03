---
name: sync-protocol
description: Change DoUrStuff command envelopes, replication, account boundaries or conflict handling with protocol compatibility and data recovery verification.
---

Read accepted architecture sections 8–9, lib/domain/sync.dart and
docs/runbooks/two-device-testing.md. Phase 1 has guest envelopes only; do not
label their golden tests as server integration or enable guessed account bases.

Keep entity/history/outbox/dirty writes atomic. Guest adoption creates authorized
account operations from a resumable mapping, not a blind guest-journal upload.
Never reorder conflicts by device time. Preserve unrelated fields and explicit
base/local/server candidates. Delete visibility must retain recoverable edits.

Server cursors are committed under the account row lock with mutations/logs/
receipts. Do not replace them with ordinary sequences or realtime delivery.
Keep contiguous device high-water marks and deletion identities beyond log
expiry. Bootstrap pages/cursors and local apply are transactional; snapshots
must preserve pending work and original bases. Scope asynchronous callbacks
and token/notification state to profile plus generation.

Update protocol version/fixtures when wire behavior changes. Run flutter test
test/domain_test.dart test/local_database_test.dart. Once backend code exists,
also run real PostgreSQL command/RLS tests for duplicate/dropped responses,
late commits, offline conflicts, expired cursors and X/Y ownership isolation.
Use the two-device runbook for release claims. If unavailable, mark the
integration gate unverified rather than supplying a mock success.

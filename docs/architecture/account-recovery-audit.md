# Account command and recovery audit — 27 October 2026

Updated 30 October after PR #19 merged at `0818f539d6bada38bdbf685e5658ac090c99f1db`.
This audit compares `task_repository.dart`, the v2 command vocabulary, the
forward migrations and the Phase 3 delivery plan. It does not authorize
account writes or close the representation or installed-device gates.

| Area | Server coverage | Remaining boundary |
| --- | --- | --- |
| Tasks | create, independent title/description/priority/due/estimate edits, atomic status/completion, delete, explicit restore, milestone order | Account SQLite projection/outbox; full native value representation parity |
| Tags | create/edit/delete, atomic normalized name, collision recovery | Native account projection; no UUID aliasing |
| Milestones | create/edit/delete, parent dependencies, completion, independent order | Native inherited visibility and pending projection |
| Memberships | exact task/tag pair, versioned add/remove, parent dependencies | Native account relationship projection |
| Views/preferences | atomic query, independent name, deletion, versioned default reference/clear | Native account projection; view restore is deliberately outside v2 vocabulary |
| Status history | Migration 020 transports retained events via explicit history extension v1, including known/null original operations | Native history storage/projection and pending-safe installation |
| Snapshot recovery | Fixed-revision begin/page for six shadow kinds, unresolved recovery and opt-in retained history | Durable client staging/install and pending-work reconciliation |
| Retention/resolution | 021–022 provide bounded log/receipt/deleted-content cleanup; recovery v1 adds version-checked single-group replacement/discard, explicit transitive held choices and snapshot/pull closure facts | Finish current review/checks; compound create/copy repair, native recovery UX, 90-day resolved cleanup and automatic scheduling/measurement |

All **17** current v2 command names have server handlers. This is command-name
coverage, not full Phase 2 semantic or representation parity. Guest v1 envelopes
are not account operations and must never be uploaded unchanged. Local journal
transactions, bulk edits and undo still need account-aware bases/dependencies
and pending projection before the guest-only guard can change.

Representation gates remain: native descriptions allow 100,000 UTF-16 units
while an account operation is limited to 64 KiB; PostgreSQL JSONB cannot carry
embedded NUL and normalizes raw number spellings; remaining Unicode/value/depth
parity and historical/future timezone rules need explicit evidence. Never
truncate text, invent original bases or silently normalize payload identity.

## Delivered snapshot boundary

`sync_snapshot_begin` holds the same account row lock as apply/registration,
captures revision R and device watermarks, and materializes all current task,
tag, milestone, view, exact-pair membership and default-preference shadows plus
every unresolved recovery candidate. Hidden/deleted shadows, winning deletion
operation IDs, original candidate operations and their original bases survive.
Private append-only pages and their manifest commit together. Migration 020
adds explicit `history_version: 1` negotiation to all three download RPCs. These
captures include retained status events; legacy captures retain their original
shape and cannot be relabeled as history-enabled tokens. Private identity ledgers
remain on the server. This is not native bootstrap/install acceptance.

Pages contain at most 200 shadows, 200 candidates and 200 history events, with a conservative 3 MiB
JSONB payload budget inside the 4 MiB reply limit. Even an empty account has one
page. The combined count includes all three kinds when history is requested. Tokens expire after 24 hours;
owner/epoch/page/liveness checks apply on every read. Later edits cannot change
captured pages, and pull resumes strictly after R.

Three unexpired captures per owner and 64 MiB of serialized record content per
capture are provisional local server safeguards, not measured free-tier capacity
or production sizing. Repeated begin at the same epoch/revision/watermarks reuses
the existing capture of the same history version. Both versions share the quota.
A fourth distinct active capture or oversized capture
returns `rateLimited`; it never evicts an active download or leaves partial pages.
Begin removes that owner's expired captures and cascades only their pages.
Global scheduled cleanup and storage/lock-duration measurements remain open.
Future retention/resolution writers must use the account lock and invalidate or
advance captured state consistently; they must not mutate shadows/recovery at
the same revision while reusing an older capture.

## Earliest unfinished recovery work

The bounded 180-day log/receipt increment is implemented locally in 021. Its
operator runner commits one account batch at a time. Automatic scheduling and
capacity/lock-duration measurements remain open. Exact cutoff, concurrent
apply/pull/snapshot and predecessor recovery evidence belongs in the latest
verification handoff and PR timeline.

The locally applied 30-day cleanup distinguishes minimal permanent identities from
purgeable shadow/ledger payloads, preserves retained status history and unresolved
original candidates, and keeps task restore fail-closed after expiry. Changed
shadows receive new log revisions; frozen captures survive and pull continuation
delivers compaction. Logs/receipts, historical originals and immutable captures
keep their independent retention policies; this is not account erasure. PR19's
final timeline closes its regression, review and merge work. The current recovery
increment implements explicit resolution/held choices while preserving originals;
see the protocol contract and latest verification evidence. Next design the
90-day resolved-candidate lifecycle cleanup, retaining permanent decision/dedup
proof and consistent capture/pull behavior. Compound create/copy-as-new repair
and native recovery/export UX remain activation prerequisites. Do not
prune canonical/history content merely to reduce storage. Keep 3.1 partial and
3.2–3.6, all external/native acceptance and Phase 4 open.

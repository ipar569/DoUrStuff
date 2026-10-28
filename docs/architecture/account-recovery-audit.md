# Account command and recovery audit — 27 October 2026

Updated 28 October after PR #16 merged at `b885fda4d09ad9f48cbf2528d427d2e84e03a1df`.
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
| Retention/resolution | Watermarks/deletion identities retained; expiry failure contracts and recovery candidates exist | Scheduled 180-day log/receipt, 30-day deleted-content, 90-day resolved-conflict cleanup; explicit version-checked resolution RPC and lifecycle |

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

Next implement a bounded local server retention increment, starting with the
180-day log/receipt cutoff under the account lock. Preserve device watermarks,
deletion/operation identities, status history and unresolved candidates; prove
expired-cursor bootstrap and missing-predecessor recovery at exact boundaries.
Do not prune dependent canonical/history content to make storage appear smaller.
Deleted-content and resolved-conflict cleanup must honor their separate policies
and unresolved recovery, with explicit resolution and held-successor choices
still required before pending-safe native recovery. Keep 3.1 partial and
3.2–3.6, all external/native acceptance and Phase 4 open.

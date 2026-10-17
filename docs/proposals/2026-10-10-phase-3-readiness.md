# Phase 3 readiness review — 10 October 2026

Status: planning only, before milestone 3.0 implementation. The user confirmed
that Android acceptance has not been completed and requested that the entry
gate stay open. This review does not change that gate or the accepted design.

Historical status above. On 12 October the user accepted emulator evidence for
local Phase 3 entry. The [v2 contract foundation](../architecture/account-protocol-v2.md)
and [latest verification](../verification/phase-3.md) supersede this inventory's
implementation status; its gaps remain useful until individually verified.

Reviewed baseline: `894766a27e7a241e5f8c8dc260e523d209220f84`, initially clean.
The accepted proposal, ADRs, delivery plan, both architecture diagrams, runbooks,
verification reports and current repository/schema/domain/UI tests were reviewed.
See [verification](../verification/phase-3.md) for executed checks.

## Existing code and contract work

| Current implementation | Required milestone 3.0 decision/fixture |
| --- | --- |
| `lib/domain/sync.dart`: protocol v1, versions and operation-wide dependencies, untyped apply result | Add original base values, group-specific predecessor bindings and typed versioned RPC outcomes; retain the guest v1 fixture |
| `LocalTaskRepository._record`: account guard, transactionally assigned sequences, latest operation per entity | Keep the guard until account bases/projection exist; prove dependent conflicts do not stall unrelated work |
| Task create/edit/status/delete/restore | Independent fields, atomic due/status groups, both edit/delete orderings, exact tombstone restore precondition |
| Tags and task/tag memberships | Owner-qualified composite identity; normalized-name collisions preserve candidates without silently merging UUIDs |
| Milestone create/edit/delete and task order | Independent text/completion; order group conflicts; retained independent additions; parent deletion visibility |
| View create/edit/delete and default preference | Atomic versioned query spec; deleted default falls back to All; deletion must not clear a concurrently selected different default |
| Guest `saveTask` can emit task, membership, milestone and order commands in one local commit | Inventory dependency edges by field/group and parent existence, including partial acceptance; do not translate the entire guest journal into uploads |
| `AppDatabase`: schema v1, backup boundary and unsupported-upgrade rejection | Design explicit retained-data v1→v2 steps and failure fixtures before changing the schema version |

No provider package, backend implementation or account worker exists. The
current file-reopen and account-guard tests establish local behavior only.

## Queue decision to prove after the entry gate

The existing immediate sequence allocation means simply leaving a dependent
operation unsent blocks all later operations on that device. Skipping its
sequence, changing its payload on retry, or substituting the latest server base
would violate the accepted protocol.

A candidate for the 3.0 fixture is **durable server-held processing**: receive
each contiguous immutable operation and durably record a held dependency as
processed transport, with its candidate and original bases retained separately
from canonical application. This would permit the next unrelated sequence.
It is a design candidate, not an implemented or proven protocol change.

Required three-operation fixture and observable assertions:

1. Sequence N changes task A's title from original base X to Y. A remote title Z
   already won. Preserve X/Y/Z; acknowledge the conflict and advance to N.
2. Sequence N+1 changes Y to W and references N's title result, not its wall
   clock or an invented revision. Durably hold W without applying it to Z;
   acknowledge storage separately from application and advance to N+1.
3. Sequence N+2 changes an unrelated task B. Apply it normally and advance to
   N+2. A remains conflicted and its successor remains visibly unresolved.

Duplicate each request, drop each response, restart both sides and expire the
detailed receipts. Watermarks alone must never discard a held candidate.
Snapshots must carry held dependency/recovery state, and unresolved state must
outlive receipt retention. Resolve N under version checks; explicitly decide
whether the successor may bind to the accepted Y result or requires another
recovery choice if Y was rejected/edited. Never silently apply W on top of Z.
Test rejection, partial-group acceptance, dependency cycles and account deletion.
Only executable fixtures can establish this choice for the final wire contract.

## Minimal upgrade inventory to validate

Preserve guest entities, v1 envelopes, sequences, history, tombstones and profile
identity unchanged. Do not upload guest journals or fabricate server shadows.
Account storage will need original base values and predecessor results, explicit
held/recovery states, entity-kind/composite keys for shadow/conflict/deletion
records, snapshot staging/checkpoints and stable adoption lineage mappings.
Current `sync_shadow` keys only by entity ID; current outbox states have no held
state; reserved `import_journal` keys do not include entity kind. Specify their
durable semantics before using or rebuilding them. Keep schema snapshots and
generated v1 helpers; add v2 separately when implementation is authorized by the
entry gate. Recovery tests must preserve both visible data and pending metadata.

Next executable action: connect an authorized Android test device and follow
the Phase 2 offline/restart checklist. Once its evidence passes, implement 3.0
typed fixtures and finalize the queue contract before server/schema changes.

# Account protocol v2 — milestone 3.0

12 October 2026. Contract foundation and executable field-chain model, **not a
server implementation**. The guest app still uses protocol v1 and schema v1;
account commands still fail closed. The user accepted Android emulator evidence
as the Phase 3 entry gate on this date, retaining physical-device acceptance.

`lib/domain/account_sync.dart` supplies immutable account operations, original
bases, entity identities and field comparison. `account_sync_rpc.dart` supplies
typed provider-free apply/pull/device/snapshot/resolution contracts. As of
13 October, `account_sync_codec.dart` encodes/decodes all six RPCs with golden
fixtures and strict validation; `account_sync_policy.dart` specifies pure
relationship, deletion, restore and resolution decisions. These are not server
command validators or database transactions. No production adapter imports them.

## Identity and immutable payloads

Wire version 2 is separate from local schema version. Operations contain a
lowercase UUID operation ID, device epoch, positive sequence, entity identity,
command, group patches, parent dependencies and provenance. Owner is always
derived from the authenticated account, never accepted from the envelope.

Entity keys are `{kind, key}`: task/tag/milestone/view each use one UUID;
membership uses the ordered pair `[task UUID, tag UUID]`; preference uses the
literal key `default_view`. Kind is part of shadow/conflict/tombstone identity.
Every server reference is also account-qualified. IDs from different kinds and
reversed membership pairs cannot collide. Recurrence/reminder commands remain
reserved for a later protocol extension and are rejected by this vocabulary.

Payload identity is exact canonical UTF-8 JSON: object keys sorted by Dart's
UTF-16 string ordering, unchanged array order, no float/NaN, integers within
±(2^53−1), depth at most 16 for values, operations and requests. RPC reply
envelopes allow depth 24 for revision/recovery/result wrappers; each embedded
operation and accepted value still receives its own depth-16 validation. This
keeps accepted operations readable when returned as recovery data. Strings are
not normalized during payload comparison. The
constructor defensively freezes nested maps/lists. Compare canonical payloads
for retained operation identities, not client-provided hashes. A server may index
a digest, but must retain/compare the authoritative payload while its identity
is retained. Never mutate even an unsent allocated operation to repair its base.

Limits: 64 KiB per operation, 1 MiB per apply request, 1–32 contiguous operations
from one device epoch per batch. Local validation happens before allocating the
sequence. The backend must enforce the same limits and command validators.
Oversized/unparseable envelopes without trustworthy identity cannot consume a
sequence; preserve the local work for explicit repair. A valid identified
envelope with a semantic command error receives a terminal consumed rejection.

## Bases, groups and predecessor binding

Each patch is `{base, value}`. Base is one of:

- `absent`: the field/entity did not exist; distinct from an existing null value.
- `observed`: original accepted revision **and value**.
- `predecessor`: earlier operation UUID/sequence and the original locally
  observed value produced by that predecessor. The entity/group and device epoch
  are inherited from this patch; a different entity/group cannot supply its base.

A predecessor must have a smaller sequence, preventing forward edges/cycles.
The server validates epoch/sequence/operation/entity/group together. An accepted
or equivalent predecessor binds to its actual accepted revision, without
rewriting the successor. If that revision has since changed, ordinary conflict
comparison still applies. Missing/expired predecessor evidence is recovery,
never permission to guess. Provenance timestamps do not select a winner.

At equal observed revisions, verify the supplied original value too. A mismatch
is corrupt-base recovery. At different revisions, an already-equal proposed
value is equivalent; otherwise preserve the original base/local/canonical
candidate. Unrelated groups can apply in the same command only if the resulting
entity and relationship constraints are valid. A conflicted predecessor is
checked **before** equivalence, so matching the current value cannot bypass it.

| Entity | Atomic groups and required server policies |
| --- | --- |
| Task | title, description, priority, estimate_minutes independently; due contains the entire none/date/timed value including zone/wall time; status_group contains status/completed_at; existence protects deletion/restore; milestone_order contains the ordered IDs |
| Tag | name contains display/normalized name together; existence protects deletion; derive normalization using matching pinned client/server rules, not ambient SQL locale |
| Milestone | title and completion independently; immutable parent relationship; existence controls deletion; task order remains separate |
| Membership | membership add/remove for the exact task/tag pair; both parents must exist and be visible |
| View | name independently; query contains a complete validated versioned TaskQuery; existence controls deletion |
| Preference | one value per key; default_view references an active view or null |

Create requires absent identity plus all mandatory valid groups atomically; it
must not populate pieces of an existing different entity. Creation yields an
accepted `existence` result for child dependencies. Parent-existence dependencies
carry the parent identity and preceding operation UUID/sequence separately from
field bases. `checkParentDependency` now checks same-owner evidence, exact causal
identity, the actual task/tag pair or milestone parent, and accepted visible
existence. Conflicted parents hold children; missing/expired/deleted evidence
requires recovery. This pure check must run under real ownership/transaction
controls in 3.1; it is not an RLS test. Canonical `existence` is boolean (true
means present); minimal deletion operation identity is stored separately.

## Contiguous processing with held dependent work

**Chosen representation to carry into server fixtures:** durable server-held
processing. Receipt/sequence acknowledgement means the command and any recovery
candidates are durably stored; it does not mean every field applied canonically.
The future account row lock covers this storage, log revision, receipt and
watermark in the same transaction.

| Incoming work | Result | Sequence | Canonical state |
| --- | --- | --- | --- |
| Applicable independent group | applied/equivalent | Consumed | Accepted version returned |
| Concurrent same-group change | conflict | Consumed | Keep canonical and base/local/server recovery |
| Successor of conflict/held group | held | Consumed | Preserve immutable candidate; do not apply |
| Bad semantic command or invalid dependency | rejected/recovery | Consumed once identity is valid | Preserve repair data |
| Sequence gap, wrong epoch, auth/preflight failure | Typed failure | No new consumption | Unchanged |
| Lost response/connection | Unknown outcome | Retry original identity | Receipt reconciles any committed work |
| Sequence ≤ watermark, detailed receipt expired | already processed | Never reapplied | Require snapshot reconciliation |

The three-operation fixture starts with canonical task A title Z at revision 2:
N proposes X→Y from revision 1 and conflicts; N+1 proposes Y→W dependent on N and
is held; N+2 independently changes B1→B2 on task B and applies. Watermark reaches
N+2, A remains Z, and X/Y/Z plus the held W remain recoverable. The fixture also
exercises backwards timestamps, duplicate/lost responses, partial groups,
accepted predecessor binding, sequence/identity violations, and representation
snapshot/reload after receipt expiry. This is **not** PostgreSQL, RLS, transport,
physical crash or installed two-device evidence.

17 October implementation evidence: `tool/test_backend_apply.py` now reproduces
the committed three-operation fixture through real local HTTP/JWT/PostgreSQL,
with production Dart decoding of its replies. This covers existing-task title
and priority edits only. The original in-memory fixture remains a protocol test;
snapshot/reload and installed-device claims still require their own evidence.

Unresolved conflict/held payloads outlive the 180-day detailed receipt retention
and must be included in consistent snapshots. They remain pending recovery in
the UI even after transport acknowledgement; never display fully Synced. A later
resolution uses a fresh sequenced operation and expected conflict revision,
with an explicit preview of affected dependent candidates. Do not replay the
old held sequence or auto-rebase it. If the user selects/edits/discards the
predecessor candidate, require an explicit choice for any incompatible successor.
Resolution races must compare the current field and recovery revisions again.

## Identity edge cases and recovery

- **Normalized tag collision:** the first accepted active name remains canonical.
  Preserve the other UUID/name candidate in conflict recovery; never alias UUIDs
  or silently attach its memberships to the first tag. Dependent membership
  operations are held. Resolution explicitly renames, maps with consent or copies.
  Unicode/whitespace parity fixtures are required before server implementation.
- **Deleted default view:** in the view deletion transaction, clear the default
  only if it still equals that view ID. Give that preference change the same
  logical revision group. Do not clear a concurrently selected different view.
  A stale selection of a deleted view is a consumed rejection with recovery.
  The local projection falls back to All whenever its selected view is hidden.
- **Delete/edit, either order:** deletion dominates visibility. Retain edits
  arriving after deletion in recovery, or the latest accepted deleted content
  when deletion arrives second. Children inherit parent invisibility; unrelated
  child tombstones are not removed on a parent restore.
- **Restore:** require the exact deletion operation ID and current deletion
  revision, plus currently deleted state and retained content. A subsequent
  delete/restore invalidates old undo. After 30-day content expiry offer explicit
  copy/recovery, never reconstruct a stale whole entity implicitly. Minimal
  deletion identity remains even when visibility is explicitly restored.

Pure fixtures now exercise both delete/edit orderings, conditional default
clearing, cross-owner parent/default rejection, exact restore identity and its
30-day content boundary, tag collisions and resolution races. Restore operations
must include `restore: {delete_operation_id, revision}` and an `existence` patch
from the observed deleted value `false` to `true`; a restore cannot bundle
unrelated edits. Deleted timestamps/retention decisions use trusted server time.
The field-chain model additionally proves an invalid-title terminal rejection
consumes its sequence once, preserves repair candidates and permits unrelated
later work. This is not complete command validation or transactional evidence.

Tag policy retains the existing pinned Dart `trim`/`toLowerCase`/whitespace
collapse behavior. Fixtures cover ASCII whitespace/case, accented uppercase,
Turkish dotted I and composed versus decomposed accents (which remain distinct).
Do not infer PostgreSQL/Unicode parity from these client fixtures; that is an
explicit 3.1 integration requirement before account writes can be enabled.

## RPC and minimal local-upgrade plan

All RPCs are versioned and authenticated. Apply takes the immutable operations
and the client's server epoch/cursor; preflight expired cursors before uploads.
Replies distinguish receipts (including fields/recovery IDs) from already
processed operations and expose the committed account cursor/device watermark.
Typed failures distinguish auth, deleted account, protocol/epoch changes,
expired cursor/snapshot, sequence gaps, identity mismatch, retry limits and outage.

Pull takes epoch/after/limit; returns whole revision groups, through cursor,
committed high-water and has-more. Snapshot begin returns token, revision,
24-hour expiry, page/record counts and device watermarks. Page reads bind token,
epoch and page; pages include shadow/deletion and unresolved recovery records.
Registration is idempotent for a new random installation epoch and cannot create
a deleted account. Resolution carries a new replacement operation and expected
conflict revision through the same ordered apply path. Adapters must strictly
validate wire schemas, ownership, bounds and supported versions before local apply.

### Executable wire boundary

Each request includes integer `protocol_version: 2`. Replies are either
`{protocol_version, status: "success", result}` or
`{protocol_version, status: "failure", code, expected_sequence, retry_after_seconds}`.
The committed `account-protocol-v2-rpc.json` locks exact request/result keys and
enum spellings. Optional reply properties are explicit nulls. The restore
precondition is present only for `task.restore`; it is part of immutable identity.

Codecs reject missing/unknown keys, wrong types/versions, noncanonical UUIDs,
unsafe counters, impossible receipt combinations, duplicate identities/groups,
future revisions and inconsistent pagination. Apply acknowledgements must match
the requested operation IDs/sequences/groups and proposed accepted values.
Resolution acknowledgements use the same correlation check. Pull cannot move
backward, switch epoch or advance an empty page. Snapshot pages bind token,
epoch, fixed revision, page number, terminal flag and expiry to their manifest.
Expiry strings use canonical UTC ISO timestamps with Dart's millisecond format.
Registration and snapshot creation replies must also match the requested server
epoch; snapshot creation rejects an already-expired manifest before staging.
These checks do not replace the adapter's active profile/generation guard.

Every request is at most 1 MiB; replies at most 4 MiB. Pull requests allow 1–200
whole revision groups; each group is bounded to 1,000 changed shadow records and
1,000 recovery records. A snapshot page allows 200 of each; manifest record count
counts both kinds, and even an empty snapshot has one page. The transport must
cap raw response size before JSON parsing. Backend transactions must respect
whole-group bounds rather than split a revision. The future durable staging
installer must still check global counts/duplicates and install atomically;
individual page validation does not implement resumable storage.

Plan v2 SQLite as an explicit retained-data upgrade, not a new guest database:

1. Preserve the existing v1 guest envelope bytes, IDs, history, sequences and
   profile metadata. Never fabricate accepted revisions or upload guest journals.
2. Add kind/composite keys to account shadow/conflict/tombstone identity. Backfill
   existing guest task tombstones as task identities; reject ambiguous unknown
   data rather than discarding it. Preserve every supported v1 schema fixture.
3. Store original bases/immutable v2 payload identity and per-group apply/recovery
   state separately from upload attempts. Add a held state and durable accepted
   predecessor results; acknowledged transport is not completed recovery.
4. Add snapshot staging keyed by epoch/token/page with durable counts/checkpoints;
   install only after validation in one transaction, retaining pending work.
5. Expand adoption mapping identity to source lineage + entity kind + source key
   in an account-specific destination, with resumable manifest/progress. Guest
   source and destination commits are coordinated by the manifest, not one file
   transaction. Preserve existing import-journal rows during migration.
6. Back up with VACUUM INTO before migration; fail closed on backup/upgrade error.
   Verify retained entities, tombstones, journals/history, metadata and dirty
   intents, including rollback/downgrade fixtures. Schema v2 implementation is 3.2.

No local schema version or retained schema snapshot changed in this milestone.

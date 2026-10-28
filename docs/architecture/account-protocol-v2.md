# Account protocol v2 — milestone 3.0

## Bounded log/receipt retention — 28 October 2026

Migration 021 implements the existing 180-day policy without changing v2 wire
shapes or history negotiation. `sync_private.prune_log_receipts(owner, batch_size)`
is a private operator-only invoker function. No API role, including the service
role or `dourstuff_rpc`, can execute it. It acquires the account row lock, then
samples trusted `clock_timestamp()`. Rows expire at age **4320 elapsed hours or
greater**; an exact cutoff is eligible regardless of session timezone/DST.

Each transaction removes at most 1–1000 whole log revisions and the same maximum
number of detailed receipts (default 200 each). Logs are removed only as a
contiguous expired prefix starting at `retained_after + 1`. A gap or a newer row
stops that prefix, even when a later legacy timestamp is older. Floor advancement
and deletions commit together; they do not change the account revision. Receipt
cleanup uses an owner/time index and proceeds independently of that prefix.
Future log/receipt timestamps use insertion time after the apply account lock;
existing recording times remain unchanged.

Compact `operation_identities` stores account/device/sequence/operation ID plus a
32-byte SHA-256 of the accepted JSONB payload. All available receipts are
backfilled before pruning is possible. A receipt-insert trigger commits identity
with the command; whole-batch preflight rejects identity or payload reassignment
before consuming any entry. The hash follows existing accepted JSONB equality;
it does not close raw JSON/native representation gaps. Previously missing
receipts cannot be reconstructed. Existing history/deletion/creation/mutation
ledgers still protect their known originals and unknown historical identities.
Missing or inconsistent compact proof aborts a pruning batch, preserving receipts.

Identical consumed retries return `already_processed` after receipt expiry and
must reconcile from a snapshot. Stale cursors still return `cursorExpired` before
upload can proceed. Compact identity proves no accepted field revision: an
expired accepted predecessor or parent receipt requires recovery, while existing
unresolved conflict/held records retain original candidates and keep successors
held. The runner never removes those records, device watermarks, deletion keys,
canonical content, status history or snapshot captures. At unchanged revision
and watermarks an in-flight snapshot remains valid and reusable; pull resumes
after its fixed R. Native pending-safe staging/install remains unfinished.

`tool/run_backend_retention.py` offers bounded local operator passes with separate
transactions and lock/statement timeouts; it installs no automatic schedule.
Deleted-content and resolved-conflict cleanup are separate increments. Permanent
identity metadata grows until account deletion; no unbounded log is substituted.

## Status-history extension v1 — 28 October 2026

Migration 020 adds opt-in `history_version: 1` to `sync_pull`,
`sync_snapshot_begin` and `sync_snapshot_page` requests. Their successful results
echo `history_version: 1`; pull groups and snapshot pages add a required `history`
array. Omitted negotiation preserves legacy v2 shapes exactly. Unsupported
extension versions fail with `unsupportedProtocol`. Commands/receipts and embedded
original operations remain v2; the extension has independent versioned codecs and
the shared `account-history-v1.json` fixture. Legacy codecs reject the extra keys.

Each event has exactly `version: 1`, `operation_id`, `task_id`, `revision`,
`previous_status` (nullable accepted field), `status` (accepted field), `fields`
(historical accepted task fields), `provenance`, `recorded_at_utc` and `operation`
(original immutable envelope or null when unknown). Identity is owner plus
operation ID, not a synthesized UUID or device timestamp. Recorded server time
is serialized as canonical UTC milliseconds; stored microseconds are untouched.
Revision orders events. No original operation is fabricated from current status.
Decoders validate task/operation identity, field/status revisions and known
operation values/provenance, preserving unknown originals explicitly.

Pull joins retained events at each whole committed revision under the account
lock, with at most 1,000 events per group and the existing 4 MiB response cap.
An oversized indivisible group fails closed. History-enabled captures freeze all
retained events at R alongside shadows/recovery; page limits are 200 of each and
3 MiB combined serialized content. Manifest `record_count` counts all three lists.
Capture version is immutable and checked on reads/reuse; legacy tokens cannot
claim history completeness. Both versions share the three-capture/64 MiB limits
and 24-hour expiry. Client staging must still validate global counts/duplicates
and install accepted data atomically while preserving pending work.

Status no-ops, equivalent changes and receipt retries do not create extra events;
conflicting status candidates stay in recovery. Deleted task shadows and retained
events remain downloadable until the separate content-retention policy is
implemented. History transport does not enable native account mode or scheduled
pruning, and does not close representation/external/native acceptance gates.

27 October implementation update: migration 019 adds `sync_snapshot_begin` and
`sync_snapshot_page` for the existing v2 manifest/shadow/recovery contract. See
the [command and recovery audit](account-recovery-audit.md) for exact coverage,
capture bounds and remaining history/retention/resolution gaps. Native staging
and account writes remain disabled; the dated milestones below remain history.

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
| Membership | boolean membership for the exact task/tag pair; additions require live parents; explicit removals may persist while a retained parent is hidden |
| View | name independently; query contains a complete validated versioned TaskQuery; existence controls deletion |
| Preference | one value per key; default_view references an active view or null |

### Saved views and preferences — server increment, 26 October 2026

Migrations 017–018 implement the existing v2 `view.create`, `view.edit`,
`view.delete` and `preference.set` shapes. No wire version or SQLite version
changes. Create requires exactly name/query/existence with absent bases and
`existence: true`; all groups commit together. Edit permits name and/or query,
with independent original bases. The full query is indivisible; competing
filters never produce a hybrid specification. Same-name views may coexist.

Name is cleaned display text with 1–80 UTF-16 units, using the frozen whitespace
policy already shared with guest names. Query is exactly `TaskQuery.toJson()`
version 1: all keys present, sorted unique status/priority/tag arrays, canonical
UUID tag filters, valid civil dates and consistent undated/date filters. Search
has the existing 2,000-UTF-16-unit limit. No defaults or normalization are applied
to received values or original bases. Tag filters are retained UUID predicates,
not parent mutations or aliases; missing/deleted tags need not destroy a view.
Account projection must always query only its own task/tag data.

View deletion uses the observed/predecessor true existence base and retains
content, creation identity and an append-only deletion ledger. It cannot restore
or recreate a UUID. Late edits remain in recovery. A default selection is the
`value` group of preference key `default_view`, either a live same-owner view
UUID or null. An optional existence dependency must bind that exact view's
operation/sequence/device. Conflicted creates hold the selection; missing,
expired or mismatched evidence requires recovery. Field predecessors bind only
the same preference entity/group. No ledger is used to guess an expired receipt.

Under the account lock, deletion clears the default only when it still equals
the deleted UUID. The clear receives the deletion's revision and a second record
in the same pull group. Its ledger retains the source deletion operation; the
deletion cannot masquerade as a preference-field predecessor. A subsequent
selection needs the newly observed null revision. A stale competing selection
remains a conflict; a stale reference to a deleted/missing/foreign view is a
consumed rejection with the immutable candidate retained. Selecting another view
before deletion leaves that preference intact. Explicit clears are normal
versioned commands; absence and an accepted null remain distinct.

Private forced-RLS tables, owner-qualified keys and narrow column grants retain
identity boundaries. Entity/default/ledger/recovery/receipt/log/watermark writes
are atomic. Account writes, native projection, view restoration, physical content
purging, snapshots and explicit resolution remain disabled or unfinished.

Create requires absent identity plus all mandatory valid groups atomically; it
must not populate pieces of an existing different entity. Creation yields an
accepted `existence` result for child dependencies. Parent-existence dependencies
carry the parent identity and preceding operation UUID/sequence separately from
field bases. `checkParentDependency` now checks same-owner evidence, exact causal
identity, the actual task/tag pair or milestone parent, and accepted visible
existence (explicit membership removal permits a retained hidden parent).
Conflicted parents hold children; missing/expired evidence and additions to
deleted parents require recovery. This pure check must run under real ownership/transaction
controls in 3.1; it is not an RLS test. Canonical `existence` is boolean (true
means present); minimal deletion operation identity is stored separately.

## Contiguous processing with held dependent work

18 October server slice: `task.create` requires exactly `existence: true`,
`title`, `priority` and `status_group`, each with an absent base. This deliberately
limited core shape is not full Phase 2 draft creation. Other groups/dependencies
fail whole-batch capability preflight. A missing/invalid core group receives a
consumed rejection without an entity; an existing identity conflicts as a whole,
even for equivalent field values. Deleted identities require recovery. Neither
case can populate missing fields of an existing shadow.

`task.status` requires only `status_group`; `task.edit` may combine that group
with title/priority. The group contains exactly `status` and `completed_at`.
Status is todo/in_progress/completed/cancelled; only completed has a non-null
UTC epoch-millisecond integer, within native Dart DateTime's inclusive
±8,640,000,000,000,000 range. Negative times are valid provenance. The server and
`validAccountStatusGroup` share real HTTP boundary fixtures. Status transitions
retain previous/current groups, canonical fields and provenance in private
`task_status_history`, atomically with the receipt/log/watermark. Equivalent
outcomes and retries add no history; reopening retains earlier events. History
download/snapshot and retention/deletion integration remain unfinished.
Review migration 005 also excludes current-base unchanged values from history
even when they receive a fresh accepted field revision. History retains the
immutable original operation so its ID cannot be reused after receipt expiry.
Older history is backfilled only from available receipts; unknown originals stay
unknown, preventing new-sequence reuse while allowing consumed-sequence
reconciliation without replay.

19 October extends `task.create` with optional description and estimate_minutes
groups, and `task.edit` with independent patches for both. Supplied create groups
still require absent bases and commit all-or-nothing. Earlier four-group creates
remain compatible; their missing optional fields stay absent, so a later first
edit uses AbsentBase rather than inventing an accepted empty/null revision.
Description is an untrimmed string of at most 100,000 UTF-16 units; estimate is
null or an integer from 1 to 5,256,000 inclusive, matching `TaskDraft.validate()`.

The whole-operation 64 KiB limit still applies. Some valid Phase 2 descriptions
cannot fit that envelope. Tests prove the semantic limit directly and the wire
limit through HTTP; this is an explicit representation gap to resolve before
account activation/adoption, alongside NUL/raw-number/other normalization gaps.
Do not truncate content or advertise full draft replication while it remains open.

20 October adds the already-reserved v2 `due` group to optional creation and
`task.edit`. No envelope/version change is needed. Shapes are exactly
`{kind: "none"}`, `{kind: "date", date: "YYYY-MM-DD"}`, or
`{kind: "timed", instant: <UTC epoch milliseconds>, zone: <IANA name>,
wall_time: "YYYY-MM-DDTHH:mm"}`. Civil years are 1–9999. Mixed, missing or extra
members and impossible dates/times receive terminal `invalid_due` rejection;
no other field in that command applies. An absent due field stays absent until
explicitly supplied; clearing writes `{kind: "none"}` with its original base.

The timed tuple is indivisible and retains its fixed instant and original
wall/zone. The server accepts either fold instant and advances gaps by their
size, including half-hour/full-day gaps. Its zone vocabulary is pinned to the
342 names exposed by the current `TimePolicy.zones` (timezone 0.11.1/default
data). `tool/export_due_fixtures.dart` generates real HTTP parity cases from
that resolver; the production wire checker validates replies against it.
PostgreSQL and Dart still use separate timezone datasets. The tested current
dates and selected historical/boundary cases are not exhaustive historical or
future parity: resolve/pin that compatibility policy before account activation
and never reinterpret or truncate an existing guest deadline to upload it.

21 October independent review correction: migration 008 only permits a gap
shift when the requested wall time has no exact occurrence. Ordinary times
immediately after a transition must use their exact instant. Added fixtures
cover both transition boundaries and later ordinary times for one-hour,
half-hour and full-day gaps; the original migration remains immutable.

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

22 October server slice: `task.delete` permits only an `existence` patch from
observed/predecessor `true` to `false`. Existing field-base checks still apply;
invalid shapes are consumed rejections. Deleted tasks stay hidden, retain their
latest content and recover later edits without replacing their original bases.
A second deletion of an already-deleted task goes to recovery and cannot
replace the winning deletion identity. A private, RLS-protected append-only
`task_deletions` ledger stores the exact operation, revision and trusted server
timestamp in the same account transaction as visibility, receipt, log and
watermark. Its identity survives detailed receipt/log expiry; operation IDs
cannot be reassigned. No content is purged in this slice. Restore, the 30-day
expiry policy, child visibility and relationship commands remain unsupported.

The subsequent 22 October restore slice (migration 010) supports `task.restore`
with the exact deletion operation ID/revision and an observed false-to-true
existence patch only. The current shadow and same-owner deletion ledger must
agree. Invalid commands receive `invalid_restore_command`; stale identity or
visible state receives `stale_deletion`; missing retained core content or a
closed time window receives `restore_content_expired`. Malformed preconditions
fail preflight without consuming a sequence. The recovery window is strictly
less than 720 elapsed hours, independent of session timezone/DST, using current
server time after acquiring the account lock; future deletion timestamps fail
closed. No client clock affects the decision.

Restoration changes only visibility, retaining the last deletion ID and all
unresolved late-edit candidates. It does not replay those candidates or invent
status history. Private forced-RLS `task_restorations` records exact immutable
restore operations/revisions in the same transaction. Both lifecycle ledgers
outlive detailed receipts/logs; old successful retries cannot revive a newer
deletion and operation IDs cannot be reassigned. Physical content purging and
child visibility remain unimplemented; this is not account UI/undo support.

Tag policy v1 freezes native Dart 3.13.5 `trim`/`toLowerCase`/whitespace behavior
in `tag_normalization_data.dart` and migration 014. The 1,023 lowercase mappings,
26 trim characters and 25 collapsing whitespace characters are explicit; SQL
does not use locale-dependent `lower` or a Unicode whitespace class. U+0085 is
trimmed only at the ends. Dotted I becomes i, sigma always becomes ordinary
sigma, and composed/decomposed accents and sharp-s/ss remain distinct. There is
no NFC, NFKC, case folding or locale tailoring. SDK upgrades must preserve these
persisted keys; changing the policy requires a compatibility/migration decision.

The atomic `name` group's value is exactly `{name, normalized_name}`. Display
name must already equal `cleanTagName(name)`, contain 1–80 UTF-16 units and have
the exact derived normalized key. Validation never rewrites the original payload.
PostgreSQL parity covers all 1,112,063 nonzero, nonsurrogate scalars, whitespace
boundaries, casing contexts and length fixtures. NUL/unpaired-surrogate names
cannot be represented by JSONB; the account validator rejects them while guest
data remains untouched. Broader JSON/description/timezone representation gates
remain open. No server tag command is enabled by this prerequisite increment.

Guest capture retains its existing equivalent-name reuse behavior. Account
collisions between different tag UUIDs must instead retain both original
candidates for explicit recovery: never alias UUIDs, redirect memberships, or
rewrite bases. That server behavior is implemented by migration 015 below.

### Server tag commands — 25 October 2026

Migration 015 supports `tag.create` with exactly `name` and `existence: true`,
both with absent bases; `tag.edit` with only the atomic name group; and
`tag.delete` with an observed/predecessor true-to-false existence patch. The
account lock covers name lookup, canonical writes, recovery candidates, receipts,
log and contiguous watermark. A partial unique index on active owner/name keys
uses byte-exact C collation. Dependencies are unsupported for these standalone
tag commands; memberships will supply their own exact parent dependencies.

A create collision by UUID or by active normalized name retains both original
groups without creating a partial tag. Recovery stays keyed to the proposed
UUID; it never points at another tag's canonical field or rewrites membership
references. Renames preserve the existing name on either a name collision or a
concurrent field conflict. Both display and normalized name remain one group.
Exact predecessor binding happens before name availability/equivalence: dependent
edits/deletes of conflicted creates remain held even without a canonical tag row,
and freeing a name never silently retries those candidates. Unrelated work can
continue through later contiguous sequences. Resolution remains future work.

Deletion retains the tag content and original creation envelope. The private
append-only `tag_deletions` ledger stores the winning deletion operation/revision
and server time beyond receipt/log expiry; stale edits cannot restore visibility.
A new UUID may reuse a deleted tag's name, but cannot reuse its identity. The
future membership projection must suppress deleted tags without redirecting old
memberships to the replacement UUID. No tag restore, purge, membership command
or account client projection is implemented by this increment.

### Task/tag memberships — 25 October

Migration 016 enables the existing v2 `task.tag` command with exactly one boolean
`membership` patch and the ordered identity `[task UUID, tag UUID]`. True adds,
false removes; an absent pair and an accepted false record are different bases.
An observed base contains its original boolean/revision. A predecessor binds the
exact same pair/group, device epoch, operation UUID and earlier sequence before
equivalence. Conflicted/held predecessors stay held, including through retained
recovery data after receipt expiry. Unrelated pairs merge independently; opposite
concurrent values preserve the losing immutable candidate. No device time orders
these decisions, and no name-based alias or membership redirect exists.

Up to two optional parent-existence dependencies bind the exact task and/or tag.
Already observed parents need no invented dependency. Every supplied dependency
is validated: another entity/kind, duplicate parent, wrong operation/sequence/device,
missing/expired receipt, rejected result or nonexistence outcome needs recovery.
Conflicted/held parent evidence holds the complete membership even without a
canonical tag. Invalid evidence takes precedence over held evidence regardless
of dependency array order. More than two dependencies or nonboolean proposed/base
values receive a consumed semantic rejection; malformed envelopes fail preflight.

Both parents must exist under the caller's account. Additions also require both
parents live. Explicit removal may write false under a retained parent tombstone,
so restoring a task cannot undo an independently removed relationship. The private
`membership_visible` helper combines the membership boolean and both parent
existence values. Parent deletion/restoration never rewrites the pair's value or
revision; a same-name replacement tag requires a new, explicit pair command.
Canonical hidden/removed pairs remain in pull records for future local projection.

`membership_shadow` uses owner/task/tag keys and composite ownership foreign keys.
Forced RLS and narrow column grants prohibit pair/owner mutation. The append-only
`membership_changes` ledger retains exact accepted add/remove envelopes and IDs
beyond receipt/log expiry; equivalent values create no extra mutation event.
The existing account lock covers pair changes, ledger, recovery, receipts, log
and device watermark atomically. The shared Dart/SQL fixture pins same-UUID
kind separation, parent dependencies and add/remove/re-add bases without changing
protocol version. There is no new public RPC, SQLite schema or account UI. Ledger
retention/storage measurement, snapshots and native projection remain unfinished.

### Milestone creation and parent dependencies — 23 October

Migration 011 supports `milestone.create` with exactly four mandatory groups:
`existence: true`, `title`, `parent` (task UUID) and `completion` (null or signed
UTC epoch milliseconds within Dart's inclusive ±8,640,000,000,000,000 range).
Every base is absent. Title uses the same trimmed 1–500 UTF-16-unit validation
as local milestones; accepted strings and timestamps are retained unchanged.
The shared `account-protocol-v2-milestone.json` fixture runs through both Dart
and real HTTP/PostgreSQL. No wire version changes: these commands/groups were
already reserved by v2. Milestone edit/delete and task ordering stay gated.

An already accepted parent needs no dependency. A child of locally pending work
must carry its exact parent-existence dependency. At most one is allowed for
this single-parent command; multiple entries receive a consumed
`invalid_parent_dependencies` rejection. Malformed identities, unsupported
dependency groups or forward edges fail batch preflight without writes.
The server verifies the actual parent UUID/kind, same device epoch, operation
UUID, earlier sequence and retained receipt's accepted existence. Conflicted/
held parent evidence holds every child group before equivalence; missing,
expired, rejected or deleted evidence sends all groups to recovery. The
account-qualified lookup treats foreign parents as unavailable without exposing
their existence. Neither recovery nor held work creates part of a child.

Creation locks the same account row as task mutations. It writes the child,
receipt, log and watermark atomically; a collision cannot merge content or
change the parent. Private forced-RLS `milestone_shadow` has an owner-qualified
parent foreign key and index. It retains the original creation envelope beyond
receipt/log expiry, protecting that operation ID from reassignment. The RPC
role has only select/insert permission for this creation-only increment.

Canonical child `existence` is independent of inherited visibility. The private
`milestone_visible` helper requires both child and parent existence, scoped to
the authenticated owner. Parent delete/restore therefore needs no child fan-out
or fabricated child revisions. Pull retains original canonical records, including
hidden content; future client projection must join parent and child visibility
atomically when applying a page. This is not an implemented account UI/projection.
Parent restoration never removes an independent child tombstone or replays a
rejected/held child creation. Child deletion is tested only with an explicit
SQL tombstone fixture here; its command remains unimplemented.

### Milestone edits and deletion — 23 October

Migration 012 enables `milestone.edit` for title and completion only. Both use
the existing validators and original observed/predecessor bases. Distinct groups
can merge independently; same-group collisions retain original candidates.
Parent/existence patches in an edit receive consumed `invalid_milestone_edit`
rejections with no partial mutation. Parent links and original creation payloads
are immutable. Edit/delete parent-dependency arrays remain capability-gated;
same-child field predecessors carry dependencies on pending child creation.

An edit hidden by either the child's own deletion or its parent's deletion goes
to recovery before equivalence. If a held child create has no canonical row,
its edit/delete successors can still bind exact held predecessor evidence.
Missing/expired/mismatched evidence goes to recovery, never a fabricated row.
The original bases/payloads remain unchanged and unrelated sequences advance.

`milestone.delete` allows only an existence patch from observed/predecessor true
to false; malformed semantic shapes receive `invalid_delete_command`. It checks
the child's own existence even when its parent is hidden. This preserves an
independent offline child deletion if the parent is later restored. Both
parent/child deletion orders leave the child's own tombstone intact. Repeated
deletion cannot replace the winner; late edits and colliding creates cannot
revive it. Child restore is not part of the current command vocabulary.

Private forced-RLS `milestone_deletions` retains the original operation,
revision and server timestamp atomically with canonical fields, receipt, recovery,
log and watermark. Its identities survive receipt/log expiry. The RPC role has
select/insert access to this ledger, and column-scoped update access only to
milestone fields/deletion ID; parent, owner and creation payload are not writable.
The shared `account-protocol-v2-milestone-commands.json` fixture exercises a
parent/child create, edit and delete batch in Dart and real HTTP/PostgreSQL.
Ordering, physical purging, snapshots and native account projection remain open.

### Atomic milestone ordering — 24 October

Migration 013 enables `task.milestone_order` with exactly one `milestone_order`
patch whose value is `{ordered_ids: [UUID, ...]}`. IDs must be unique canonical
lowercase UUIDs. An empty list is valid. Initial ordering uses an absent base;
later edits retain observed revision/value or exact same-task/group predecessors.
Ordering cannot be bundled with task create/edit/status or other fields. Invalid
list shapes receive consumed `invalid_milestone_order`; command mixtures receive
`invalid_order_command`. No wire version change: the command/group were reserved.

The canonical list is independent of child membership. A same-account,
same-parent child tombstone remains a valid reference, allowing concurrent delete
and reorder in either arrival order. Unknown, foreign or other-parent references
send the whole order to recovery. Subsets are valid: the reference projection
filters invisible children and appends live children absent from the list by UUID.
It never rewrites the accepted list, field revision or original operation.
Parent deletion hides the whole projection; parent restore preserves independent
child tombstones and never replays late order candidates. Competing reorders use
the ordinary atomic field conflict/equivalence policy, without partial lists.

Optional existence dependencies identify this task or listed milestone creates.
They bind exact same-owner/device/operation/sequence/entity receipt evidence.
For a held child without a canonical row, the immutable create supplies its parent;
the entire order is held, and later unrelated sequences continue. Missing/expired,
rejected, mismatched, duplicate or unlisted dependency evidence requires recovery.
Dependencies are checked before equivalence. A deleted listed child does not
invalidate a previously accepted creation dependency; projection still hides it.

`visible_milestone_order` is a private ownership-scoped reference helper, not a
new public endpoint. `projectMilestoneOrder` is a pure Dart policy with shared
validator/projection fixtures; no native account projection is enabled. Canonical
order changes are included in ordinary pull records. A future account projection
must recompute when parent, child or order records change in the same local page
transaction. Existing operation/request limits still apply without truncation.

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

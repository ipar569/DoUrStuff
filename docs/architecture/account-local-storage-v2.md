# Account SQLite storage — updated 21 November 2026

SQLite v2 adds separate account tables alongside every unchanged guest v1 table.
SQLite v3 adds local account command history and reminder-dirty intent. The
bounded command API supports task create/edit/status/delete/restore and milestone
create/edit/delete, milestone ordering, tags, task/tag memberships, saved
views and the shared default view. App activation, auth, transport, adoption and worker remain
disabled/unimplemented. The filename is retained to preserve existing links.

## Local command transactions (v3)

`commitCommand` receives a caller-allocated operation UUID, explicit original
field bases, exact parent dependencies and UTC provenance. It allocates the
contiguous device sequence in a guarded SQLite transaction, retains the exact
envelope/original identity, records before/after projection values in
`account_command_history`, and increments `account_notification_dirty` for the
kind-qualified entity and a milestone's task. The projection is derived from
durable accepted records and original proposals; no native task row is fabricated.
Local intent history is distinct from server-accepted status history and never
claims acceptance. Dirty intent does not schedule notifications.

Retrying the same UUID and arguments returns the original without another
history/dirty/sequence write. Changed intent or a low-level retained operation
without command history cannot reuse that UUID. Unsupported/invalid command
shapes, NUL and unpaired Unicode are rejected without consuming a sequence or
truncating content. Valid stale bases remain preserved with conflict/recovery
projection decisions. The API does not infer bases from current values or
translate guest journals. Receipt outcomes remain separate and immutable.

Complete task/milestone creates project atomically only at an absent identity.
Collisions never merge individual fields. Parent dependencies bind the exact
earlier local device/sequence/entity/operation and a successful existence proposal
or correlated receipt; uncertain, conflicted and closed work cannot authorize a
child. Parent pending operations are evaluated before the child's sequence,
while final visibility uses the current parent. Thus a later pending parent
delete hides the child without undoing its earlier create or independent delete.
Accepted downloads still dominate hidden-parent edits. Unrelated commands can
continue when a dependency needs recovery.

Observed bases can bind receipt values while pull is behind. An intervening
pending field cannot be overwritten through an older observed/predecessor base;
same-field chains must refer to their actual predecessor. No preview invents a
server revision.
Native auth/secure persistence feasibility and representation gates
remain prerequisites for enabling the app account path.

### Bulk task status, delete and undo

`commitBulk` takes a caller-owned batch UUID, UTC provenance and the ordered
selection. Each task supplies its own observed or predecessor base. Identical
appearances in grouped views collapse to the first position. Contradictory
targets for one task reject the selection. One SQLite transaction records
all operations, original payloads, contiguous sequences, before/after history
and reminder invalidations. Retry with the same selection, timestamp and UUID.
The first operation uses the batch UUID. Subsequent UUIDs derive from the batch
and index. The existing v2 provenance object carries `bulk_id`, `bulk_index`
and `bulk_count` so a shorter, extended or reordered retry fails atomically.

PostgreSQL processes ordinary per-task commands. Receipt dispositions, recovery
and bounded upload pages remain per the existing protocol. To undo an applied
status change, `undoTarget` proposes that task's original status/completion
pair against the accepted transition's own revision. If the original pair
already matched, even an applied receipt produces no inverse. A pending or equivalent
status change supplies no evidence that this operation changed the field.
For delete undo, the caller needs the winning deletion UUID and revision from
its applied receipt or matching downloaded tombstone. A locally pending delete
alone cannot supply a revision. Capture the eligible inverse targets once and
submit them with a fresh batch UUID. Later peer edits or replacement deletions
can put individual inverses into conflict or recovery while others succeed.

### Exact-deletion task restore

`task.restore` takes the original deletion UUID and its accepted revision. Its
single existence patch observes false at that same revision and proposes true.
The transaction preserves both parts of the target across retry and reopen.
A current downloaded tombstone or a correlated applied delete receipt can prove
the target. A pending delete has no accepted revision. A different deletion,
visible task or compacted core yields recovery in the preview.

For a matching tombstone with retained core fields, SQLite previews visibility
and evaluates subsequent milestone, order and membership dependencies. An
acknowledged restore proves a milestone's parent even while pull is behind.
A locally pending restore requires the milestone create to name its exact
parent dependency. An independent child deletion or membership removal still applies. Restoration
never replays a rejected edit. Only PostgreSQL has the deletion ledger and
trusted clock for the 720-hour limit. An expiry rejection withdraws the preview
and preserves the restore and its dependents for recovery. A downloaded newer
deletion withdraws the stale preview even before its receipt arrives.

Equivalence against accepted state does not create a pending field revision;
equivalence against an existing pending value preserves that pending source.
The displayed latest source and internal causal identity are separate. Equivalent
operations share a causal identity so either may be named as predecessor; a later
applied write invalidates both old references. Internal identities never become
wire/server revisions, and receipts bind actual accepted revisions separately.
Known conflicted/held predecessors keep descendants held, including edits/deletes
of a milestone whose held create has no shadow yet. Missing children still cannot
be manufactured by an absent-base edit. These previews are checked against real
PostgreSQL outcomes before receipt application in the regression harness.

`task.milestone_order` uses this same atomic command transaction. Its only patch
is the validated ordered-ID group; dependencies can name this task and listed
milestones once each. Child dependencies must prove the exact same-parent create.
Missing proof takes precedence over a held dependency. A source receipt remains
evidence after recovery closure: the closed proposal no longer replays, but its
retained conflict receipt still holds a new dependent reorder, matching PostgreSQL.
Closure alone never supplies proof. An independent child tombstone remains a
valid order reference; no live child is invented from a held
create. Causal cutoffs prevent later local operations from authorizing earlier
orders, and per-read memoization avoids repeatedly evaluating those prefixes.

`visibleMilestoneOrder` reads the task and its effective children transactionally,
filters deleted/hidden children and appends unlisted live children by UUID.
It leaves the accepted/proposed ordered list, original bases, history and receipts
unchanged. Receipt values bridge pull lag and yield to newer accepted revisions.
No schema, protocol version, migration or native account UI change is needed.

### Tags and memberships

`tag.create`, `tag.edit`, `tag.delete` and `task.tag` use the same atomic
original/sequence/history/dirty transaction. Names must already match the frozen
display/normalized-name group; invalid input is rejected without rewriting it.
The membership key remains the exact ordered task/tag UUID pair. Its dirty intent
also invalidates the task. Neither command path writes guest rows.

Tag collision previews compare live accepted and earlier effective pending tags,
including receipt values while pull lags. Whole creates cannot partially merge;
rename collisions preserve the old complete name. Strict sequence cutoffs and
per-read memoization keep cross-tag checks causal. Later deletion frees the name
for a distinct UUID but does not replay an earlier failed create or redirect its
memberships. Same-field successors bind original evidence before name availability.

Membership dependencies validate exact parent entity, operation, device and
sequence. Missing proof wins over a held parent; retained conflict receipts remain
evidence after closure, but closure alone supplies no proof. Both parents must
exist, and additions require live parents at the command's causal cutoff.
Explicit false removals survive parent tombstones. Final visibility additionally
uses current parent state without changing the pair's value or original base.
Absent and accepted false pairs are distinct. No implicit rebase or UUID alias is
introduced. Real PostgreSQL verification is required before delivering this increment.

### Saved views and shared defaults

`view.create` requires an absent identity, a valid display name and a complete
canonical query. `view.edit` compares name and query independently. A query
conflict retains the entire filter specification. `preference.set` targets
`default_view` and accepts a view UUID or an explicit null. An optional
dependency binds the exact view existence operation at the selection's sequence.
A collision holds the selection and its successors. References to missing or
deleted views retain their originals for recovery.

Deleting the selected view projects a null default before comparing subsequent
preference operations. The deletion and preference dirty marker commit with the
view's history, envelope and sequence. Deleting another view preserves the
selection. The implicit clear has a local source for display, but supplies no
same-field preference predecessor. A later pull installs both accepted shadows
at the server's deletion revision. Explicit preference commands still carry
their own immutable bases and receipts.

## Upgrade and ownership

The additive v1→v3 and v2→v3 paths retain all old tables and bytes, including
account originals, outcomes, archives, accepted records and in-progress snapshots.
The v1 path includes the established nine v2 tables, then both new v3 tables;
the v2 path creates only those two. DDL and `user_version = 3` commit together
after the same pre-transaction WAL backup. Unexpected tables fail closed with
rollback. The v1/v2 snapshots/helpers stay unchanged; v3 has its own snapshot
and helper. The following v1→v2 description records the previous increment.

The explicit v1→v2 migration creates nine tables and writes `user_version = 2`
in the same transaction, so a failure after commit remains safely reopenable.
Before it,
`prepareSqlite` uses `VACUUM INTO` to include committed WAL contents. Backup
failure, unexpected account schema or upgrade failure stops opening without
recreating the database. The retained v1 snapshot/helper remain unchanged. Every
legacy row survives, including opaque envelope bytes, IDs, sequences, metadata,
tombstones, history, reminder intent, reserved sync tables and import mappings.

An account store requires profile ID `account-<owner UUID>`. Each open increments
a persisted generation; every read/write checks profile/owner/generation inside
its transaction. This rejects delayed callbacks from earlier instances, but is
not authentication or restored-backup detection. Fresh account binding refuses
populated legacy tables/nonempty checkpoints rather than guessing their account
meaning. Guest tombstone kinds remain in the guest table; no account revisions
or identities are inferred from them.

## Originals and projection

`account_operations` keeps the first envelope's exact bytes, canonical payload
identity and originating server epoch. Operation UUID and device-epoch/sequence
are independently unique. Retaining an explicit account operation requires an
installed snapshot and contiguous local identity; insertion/sequence advancement
nest inside the future entity/history/dirty transaction. The app does not call
this API and its existing guest-only command guard remains in place.

Correlated receipts retain per-field outcomes and accepted predecessor values
separately from transport acknowledgement and original bases. Upload replies do
not advance the download cursor. An expired receipt requires reconciliation;
watermarks cannot invent accepted fields. Original payload proofs and the first
recovery record are archived independently of current accepted state, without
local pruning. Snapshots cannot substitute payloads under existing identities.

The projection read model returns an accepted shadow, ordered original local
proposals with outcome/transport/reconciliation state, and effective values with
explicit pending operation sources. It does not fabricate server revisions or
flatten account values into guest/native task rows. Independent original-base
patches and proven same-field local predecessor chains can project; downloaded
conflicts/held/recovery, uncertain receipts and closed groups cannot. Accepted
receipt values bridge download lag only while the applied cursor and shadow are
behind their revision; removed compacted fields cannot revive old receipts.
Later accepted values supersede them without changing the original receipt.
Unacknowledged task/milestone creates and their exact parent dependencies now use
the bounded command rules above, including the exact-deletion restore checks.
This remains partial pending replay, not full account command/representation parity.

Visibility combines effective existence with a milestone's exact parent or both
exact membership parents. A default-view reference is usable only while its view
is visible (or the reference is null); the original reference is retained.
Independent child deletion/removal survives parent restoration. Native resolved-
group presentation, command binding, recovery/export and copy-mapping presentation
remain later work.
History and closure records are stored but have no native presentation yet.

## Durable snapshots

This path requires negotiated history v1 + resolution v1. Existing production
codecs validate manifests/pages and bind epoch, token, fixed revision, page,
terminal flag and expiry. A page, canonical retry identity, globally unique
records and next-page/count/byte checkpoint commit together. Identical retries
are idempotent; substituted pages, gaps and cross-page duplicates fail atomically.

One capture is staged per profile. Replacing its token resets staging only.
Local bounds are 10,000 pages, 1,000,000 records and 64 MiB of canonical page
envelopes, in addition to codec limits. These conservative bounds are not
capacity evidence or a promise to accept every server-sized snapshot.

Installation checks complete exact counts, expiry, non-regressing same-epoch
cursor/watermarks, matching candidate/closure versions and original operations
beyond device watermarks. Snapshots intentionally retain originals alongside
closure facts: projection subtracts closed IDs and exposes closed local groups
without rewriting their outcomes or originals. Accepted records, archives, checkpoint and
staging cleanup commit atomically. Pending work created during download survives.
Shadows use kind-qualified canonical entity keys, including ordered membership
pairs and deleted identities. No UUID alias is created.

Server-epoch replacement or a local sequence behind the server watermark latches
`requires_recovery`, preserving originals and preventing new envelope retention.
It has no automatic clear path. Restored-profile/new-device recovery and export
decisions require later lifecycle work; restoring an entire backup cannot be
detected merely by the generation counter.

## Incremental downloads

`applyPull` accepts negotiated history v1 + resolution v1 pages, requiring the
installed epoch/cursor and current profile generation. A page contains at most
200 whole contiguous revisions, 10,000 total records and the codec's 4 MiB reply
bound. Empty committed revisions advance normally; an empty terminal reply does
not advance. The advertised committed high-water is not the applied cursor.

All shadow/history/recovery/closure writes, original identity proofs, first
recovery archives and cursor advancement share one SQLite transaction. No network
call, receipt acknowledgement or device watermark is inferred inside it. Shadow
field revisions cannot regress or substitute values at the same revision. Deleted
content can compact to identity fields, including live milestones beneath deleted
parents; parent validation uses accepted state and the complete incoming revision,
not local pending visibility or record order. Deletion identities survive restoration.
History and closure facts are immutable; candidate closure versions and operation/
device/sequence proofs are checked. A downloaded original or closure from this
device at or beyond its next local sequence atomically latches explicit recovery;
it does not advance that sequence or invent field outcomes. Original envelopes
and receipts stay untouched.

A rolled-back page can retry; an already committed or otherwise stale request is
rejected without writes, and the caller must refetch from `checkpoint()`. There
is no durable last-page retry ledger or automatic worker. In-progress snapshot
staging survives pull; an older capture cannot install over a newer checkpoint.
Projection reads accepted state and current proposals in one guarded transaction.
Neither SQLite v1/v2 snapshots nor backend migrations change in this increment.

Native materialized projection, remaining account commands,
auth/secure storage, adoption and the worker remain unfinished. Representation,
external/native acceptance and Phase 4 gates stay open. No backend migration or
production action is introduced. See the verification handoff for actual results.

# Account SQLite storage — updated 12 November 2026

SQLite v2 adds separate account tables alongside every unchanged guest v1 table.
SQLite v3 adds local account command history and reminder-dirty intent. The
bounded command API supports task create/edit/status/delete and milestone
create/edit/delete. App activation, auth, transport, adoption and worker remain
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
server revision. Restore, ordering, tags, memberships, views/preferences, bulk
commands and undo are outside this bounded command API. Their existing retained
originals remain readable; unimplemented whole creates/restores/dependencies
remain held. Native auth/secure persistence feasibility and representation gates
remain prerequisites for enabling the app account path.

Equivalence against accepted state does not create a pending field revision;
equivalence against an existing pending value preserves that pending source.
Known conflicted/held predecessors keep descendants held, including edits/deletes
of a milestone whose held create has no shadow yet. Missing children still cannot
be manufactured by an absent-base edit. These previews are checked against real
PostgreSQL outcomes before receipt application in the regression harness.

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
the bounded command rules above. Other creates/restores/dependencies stay held.
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

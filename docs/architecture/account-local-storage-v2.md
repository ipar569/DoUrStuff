# Account SQLite foundation — 4 November 2026

This is the first bounded delivery-plan 3.2 increment. SQLite v2 adds separate
account tables alongside every unchanged guest v1 table. Account commands, auth,
transport, adoption and the worker remain disabled/unimplemented.

## Upgrade and ownership

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

The projection read model returns an accepted shadow and ordered original local
proposals with outcome/transport/reconciliation state. It does not flatten them
into native task rows or blindly overlay acknowledged/conflicting patches. Full
pending replay, relationship visibility, native resolved-group presentation, command
binding, recovery/export and copy-mapping presentation remain later work.
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

Incremental pull apply, native materialized projection, account-aware commands,
auth/secure storage, adoption and the worker remain unfinished. Representation,
external/native acceptance and Phase 4 gates stay open. No backend migration or
production action is introduced. See the verification handoff for actual results.

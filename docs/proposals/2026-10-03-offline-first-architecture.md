# DoUrStuff architecture and delivery proposal

Status: ACCEPTED — user approved the design on 3 October 2026.
Prepared: 3 October 2026, Pacific/Auckland.

This document describes intended behavior. The original review audit below is historical. Current implementation and verification are tracked in docs/verification/phase-1.md; design acceptance alone does not establish runtime support.

## 1. Recommendation and decisions for review

Build a Flutter application with Drift/SQLite as the authoritative local store. Add optional Supabase Auth/PostgreSQL through an explicit sync protocol, and use OS-local notifications. Start with Android and Windows; iOS, macOS and Linux remain planned until verified.

Supabase supplies authentication, transactions, access controls and realtime transport. It does not supply this application's SQLite replication, conflict policy, recurrence reconciliation or account isolation. Correct sync and recovery are the largest engineering investment.

Proposed decisions:

1. Adopt Flutter/Drift as a fresh implementation driven by the current product specification.
2. Accept occasional free-backend interruption while maintaining full local operation. Continuously available cloud sync would require reconsidering the recurring-cost target.
3. Use per-field optimistic concurrency and visible conflict recovery, not whole-task last-write-wins.
4. Keep date-only values as calendar dates; fixed instants for timed one-off tasks; named-zone wall-clock schedules for recurrence.
5. Target personally signed Android APKs and locally trusted Windows MSIX packages first; public stores are separate release channels.
6. Assume GitHub OAuth for initial personal sync, avoiding production email delivery. Another provider can be selected before phase 3.
7. Gate recurrence/reminders on a working, tested two-device sync foundation.

Assumptions: single-owner accounts; no attachments, sharing, AI services, web release, calendar time-block scheduling or always-running background service in v1. The OS user profile is trusted for task-file access. Application account isolation is not protection against an OS administrator.

## 2. Fresh-start scope

The user has directed us to ignore the previous project. Its code, architecture, UI, tests and workflows impose no compatibility or reuse requirements on this design. No legacy data migration or PWA maintenance is planned.

The proposal is saved in the discovered D:\Projects\DoUrStuff checkout. The supplied C:\Projects\DoUrStuff path was absent during inspection. This path discrepancy does not affect architecture review.

Create a single Flutter application at the repository root, alongside its optional backend, documentation and automation. There is no need for a multi-app layout. Ignoring the previous product does not require deleting Git history or restoring deleted files; this proposal leaves both untouched. The only review gate remains the requested architecture review before implementation.

## 3. Stack evaluation and operating costs

Facts were checked against official platform/framework/service or package-maintainer documentation on the preparation date. Pin exact SDK/package versions after a phase-1 compatibility build.

| Approach | Persistence/platforms | Notifications and sync | Assessment |
| --- | --- | --- | --- |
| Flutter + Drift/SQLite + optional Supabase | Shared Dart UI/domain; native SQLite across intended platforms | OS adapters; custom sync needed | Recommended: consistent storage and UI, limited provider dependencies |
| Web PWA + IndexedDB | Browser-local storage/cached shell across mobile and desktop browsers | Browser APIs lack reliable offline scheduled notifications; custom sync needed | Simple web distribution, fails the native reminder requirement |
| React + Tauri 2 + SQLite | Shared web UI; official native SQL plugin | Platform notification integration and custom sync | Credible alternative; adds Rust/webview and platform integration work |
| React Native + SQLite | Mobile core; separate Windows/macOS platform projects | Desktop package compatibility and custom sync | More integration risk for Windows-first personal use |
| .NET MAUI + SQLite | Android/Windows/iOS/Mac Catalyst; Linux outside primary supported set | Native notification work and custom sync | Reasonable with a C# preference; weaker later Linux fit |
| Flutter + Firebase/Firestore | Built-in offline cache on documented supported clients | Document last-write-wins; offline support documented for Android/Apple/web | Does not meet the Windows local-storage and conflict requirements by itself |

Sources: [Flutter platforms](https://docs.flutter.dev/reference/supported-platforms), [Drift platforms](https://drift.simonbinder.eu/platforms/), [Tauri SQL](https://tauri.app/plugin/sql/), [Tauri notifications](https://tauri.app/plugin/notification/), [React Native platforms](https://reactnative.dev/docs/out-of-tree-platforms), [MAUI platforms](https://learn.microsoft.com/en-us/dotnet/maui/supported-platforms?view=net-maui-10.0), [Firestore offline policy](https://firebase.google.com/docs/firestore/manage-data/enable-offline), [notification plugin](https://pub.dev/packages/flutter_local_notifications).

Flutter supports the target platform families; that does not prove DoUrStuff supports them. Initial release architectures: Android arm64 and Windows x64. Record minimum OS versions after dependency/build validation. Windows builds require Windows; iOS/macOS builds require macOS and Apple tooling. [Flutter setup](https://docs.flutter.dev/platform-integration)

Proposed dependencies: Flutter stable/Dart, Material 3 theme tokens, Drift native database isolate, a small Riverpod state layer, supabase_flutter only inside adapters, explicit secure-storage-backed auth persistence, flutter_local_notifications behind a capability-aware interface, bundled timezone data and device-zone discovery. Verify licenses and maintenance before pinning. No paid sync dependency. [Supabase Dart](https://supabase.com/docs/reference/dart/introduction), [secure-storage maintainer docs](https://pub.dev/packages/flutter_secure_storage)

| Service/cost | Verified position | Consequence |
| --- | --- | --- |
| Supabase Free | $0, 500 MB database, 5 GB egress, 50,000 MAU; two active free projects | Target small text-only use; monitor history/index growth |
| Realtime Free | 2 million messages, 200 peak connections | One account channel per active device; coalesce hints |
| Inactivity | Free projects may pause after a week | Local editing remains usable; explain restore/retry; no artificial keepalive traffic |
| Capacity | Free database exceeding 500 MB can become read-only | Warn early and retain pending uploads locally |
| Backups | No automatic backups on Free | Local exports and operator dumps needed |
| Optional upgrade | Pro starts at US$25/month; extra resources/add-ons can add cost | Paid tier only by explicit choice |
| Auth email | Default SMTP is restricted; currently two messages/hour | OAuth initially; production SMTP is another dependency if selected |

Sources: [pricing](https://supabase.com/pricing), [billing quotas](https://supabase.com/docs/guides/platform/billing-on-supabase), [database limit](https://supabase.com/docs/guides/platform/database-size), [pausing](https://supabase.com/docs/guides/platform/free-project-pausing), [backups](https://supabase.com/docs/guides/platform/backups), [SMTP](https://supabase.com/docs/guides/auth/auth-smtp).

Zero recurring backend cost is a target, not an availability promise. Use local Supabase development instead of paid staging. No hosted UI, file storage or always-on custom server is needed. Managed SQL/RPC code still requires maintenance. Budget for retained conflict/history data, not just task rows.

Build/signing/distribution costs are separate:

- Personal Android APKs use a private signing keystore. Play registration is US$25 once, with verification/testing prerequisites. Recheck evolving off-store Android verification before wider distribution. [Play registration](https://support.google.com/googleplay/android-developer/answer/6112435), [Android verification](https://developer.android.com/developer-verification)
- Windows personal MSIX can use a self-signed certificate explicitly trusted on the device. Public trust/signing can cost money; current Microsoft Store individual registration is free. Stable identity/certificate continuity matters for upgrades. [Flutter Windows release](https://docs.flutter.dev/deployment/windows), [Microsoft registration](https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-individual-developer)
- Apple Developer Program distribution is US$99/year plus macOS hardware/CI access. [Apple membership](https://developer.apple.com/support/compare-memberships/)
- Standard public-repository GitHub Actions runners are free; private GitHub Free currently includes 2,000 minutes/month and 500 MB artifact storage, with OS-dependent charging. Use short retention and spending controls. [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)

## 4. Components, data flow and durability

    Flutter views/controllers
              |
       application commands
              |
       domain rules / queries
              |
    local transaction -------- durable outbox
              |                       |
       SQLite query streams      sync coordinator
              |                       |
       immediate UI update      SyncTransport
                                      |
                           Supabase RPC + Auth/RLS

    committed local changes -> reminder planner -> OS adapter
    OS action -> validated application command -> same transaction path

Keep interfaces at real boundaries: TaskRepository, SyncTransport, AuthSessionStore, NotificationScheduler, Clock/TimeZoneProvider and BackupCodec. Domain code imports neither Flutter plugins nor Supabase. Avoid a generic persistence framework or abstractions for hypothetical providers.

Every command atomically writes entities, history, a durable change operation and a notification-dirty marker. Guest operations remain local and are not uploaded. UI Saved means local commit; Synced means acknowledged by the server. Network calls never run inside the local transaction. Read and write through SQLite even when online.

Use app-data storage, foreign keys, WAL, short transactions and a durable synchronous configuration (proposed FULL). A failed/disk-full commit retains the draft and does not display Saved. Test crash recovery; hardware/filesystem guarantees cannot be assumed.

Use monotonically versioned migrations, committed schema snapshots and upgrade fixtures. Before an upgrade, create a consistent SQLite backup, not a raw copy of a live WAL database. Never recreate the database on migration failure. Preserve the original, report recovery options and refuse downgrades that cannot read the newer schema.

## 5. Schema and account boundaries

Use separate SQLite files for guest and each account, with immutable profile metadata and a database-lineage ID. Switching profiles closes the connection, listeners and jobs, cancels old-profile notifications, clears memory and opens the selected database. Server rows also carry owner_id; references include ownership where required.

| Entity | Key fields/invariants |
| --- | --- |
| tasks | Stable UUID; nonblank title; description; due kind none/date/timed; civil due_date OR UTC due_instant + IANA zone/original wall time; optional positive estimate_minutes; priority none/low/medium/high; status todo/in_progress/completed/cancelled; created/updated/completed timestamps; optional occurrence link; deletion marker |
| tags / task_tags | Reusable UUID tags; name/normalized name; independently versioned task-tag membership and removal records |
| milestones | UUID, task, text, ordered position, independent completion/time, deletion marker |
| reminder_rules | UUID, parent task/template, offset kind/value, date-only reference time/zone; up to five rules per task initially |
| snoozes | Task/occurrence, replacement instant, generation, revision, suppressed-reminder cutoff |
| recurrence_series / segments | Template and immutable schedule segments; named zone, frequency/interval/weekdays/month-day, end/count, cutoffs, engine version |
| occurrence_state | Deterministic ID, segment/ordinal, original scheduled date/time, overrides, status, skip reason and history |
| saved_views | UUID, name, versioned search/filter/group/sort specification |
| shared_preferences | Default saved view, date-only reminder defaults, shared theme; versioned by key |
| device_preferences | Reminder enablement, permission observations, layout, device theme override and notification privacy |
| sync_shadow | Last accepted server values and per-field versions |
| outbox | Operation UUID, device epoch/sequence, command, base versions/dependencies, payload, attempt/retry/state |
| sync_checkpoint | Server epoch/cursor, bootstrap token/page, last success and protocol version |
| conflicts / history | Base/local/server alternatives, command provenance, resolution and completion history |
| device_notifications | Local OS ID, profile/logical reminder key, instant, generation/fingerprint, registration state |
| import_journal | Source lineage/ID mapping, import batch/progress, guest adoption manifest |

Offline timestamps retain device provenance; server receipt/revision metadata is separate. Clock timestamps never order conflicts. Status/completed_at form one atomic group: completing creates a history event; reopening clears current completed_at without deleting earlier history. Checking all milestones does not auto-complete the task; completing a task does not auto-check milestones.

Server adds account_state, device_state, change_log, operation_receipts, tombstones, conflicts and temporary bootstrap snapshots. Task deletion hides dependent objects atomically. Index status, due fields, priority, normalized title, parent keys and sync revision. Start with parameterized local substring queries; add FTS only if measured data warrants it.

## 6. Time and recurrence rules

Date-only values are YYYY-MM-DD, never UTC midnight. They remain the same date during travel. They become overdue when the device's current civil date passes them; devices in different zones can temporarily disagree about whether that day has ended.

Timed one-off tasks capture wall time and IANA zone, resolve to a fixed UTC instant, and display in the device zone with the original zone available. Date-only reminders use a named reminder zone (default configuration-time zone) and a configurable 09:00 default. Travel does not silently move that reminder instant.

For DST gaps, advance by the gap (02:30 becomes 03:30 for a one-hour jump). For repeated wall times, select the earlier instant by default; explain the choice and allow the other instant for one-off entries. Calendar-day offsets preserve wall time in the reference zone; hour/minute offsets use elapsed time. Label “one calendar day before” distinctly from “24 hours before”.

Store engine/tzdata version; pin common recurrence fixtures across clients/server. A timezone-data update reconciles future instants without changing occurrence identity or past history. Clock/zone changes recalculate views and schedules.

Recurrence supports daily, weekly, selected weekdays and monthly, positive intervals, and optional inclusive end date OR total count. Weeks start Monday and interval weeks anchor to the start week. Monthly days clamp to month-end while retaining the original day: Jan 31 -> Feb 28/29 -> Mar 31.

Rules are schedule-based, not completion-relative. Early completion never shifts the series. Counts include skipped slots. Missed occurrences remain open/overdue; skip is cancellation with a recurrence skip reason. Ending the series stops future generation while retaining history. Timed recurrence preserves wall time in the named zone across DST; date-only recurrence produces civil dates.

### Bounded generation and deduplication

Occurrence ID = UUIDv5(fixed namespace, canonical encoding of series_id + segment_id + ordinal). Identity never depends on device clock, current zone or resolved UTC offset. Server uniqueness covers owner/series/segment/ordinal.

Cache the visible range plus the next 90 days, at most 500 new occurrences per transaction. Larger ranges load in pages. Untouched projections need no server row; editing/completing/skipping produces durable occurrence state. Explicit history is never evicted. Past untouched occurrences remain queryable from the rule; Overdue/All paginate them rather than silently skipping missed days. Notification scheduling has a separate, smaller bound.

A create-if-absent command includes identity, rule/engine version and explicit overrides. The server validates the key and derives base values from accepted rules. Two devices generating the same occurrence produce one logical item; duplicate generation must never overwrite an edited instance.

### Series edits while offline

Offer This occurrence and This and future occurrences; series settings may apply to all uncompleted occurrences from an explicit displayed boundary. Completed history is immutable. One-occurrence edits are overrides, retaining identity.

A schedule edit atomically cuts the previous segment at a selected ordinal and introduces an immutable replacement segment whose ID derives from the edit command. Preview effects on remaining count/end date. Previously elapsed slots count toward an unchanged total limit.

Concurrent schedule edits compare against the series schedule revision. The first accepted branch remains active; the other is recoverable conflict data, not another active series. Template field edits preserve explicit overrides and completed snapshots.

After replacement, discard untouched obsolete projections and regenerate. Preserve offline edits to superseded occurrences in recovery; retain completed work as history. Let the user detach the old task or explicitly map it to a replacement; never map by nearest date. The same rule applies when stale changes arrive after truncation. Dependent occurrence operations wait for their series command; unresolved series conflicts hold dependent work.

## 7. Navigation, task queries and calendar

Mobile uses Tasks/Calendar/Settings, a persistent quick-add action and a full-screen editor. Desktop uses a sidebar, task list and optional detail pane with keyboard shortcuts. Quick capture requires only title. Use dark semantic theme tokens, labelled priority indicators, generous touch targets, scalable text, screen-reader labels, visible focus and keyboard reordering alternatives.

- Filter dimensions AND together; selected statuses/priorities OR within their dimension. Tags default to any selected, with an explicit all-selected toggle.
- Search ANDs normalized whitespace-separated tokens across title/description/tag labels. Grouping never changes membership.
- Date ranges are inclusive civil-day bounds; timed tasks use their displayed date. Undated and due-range filters are mutually exclusive; invalid imported combinations are explained.
- Today = open tasks due today; Upcoming = open tasks after today; Overdue = open tasks past deadline; All = every nondeleted status, including undated.
- Default sort: due ascending, priority descending, created_at ascending, immutable ID. User-selected sorts retain created_at/ID tie-breakers. Null dates/estimates sort last in either direction. Title uses a stable normalized key.
- Due ordering uses displayed day, date-only before timed entries on that day. Date-only entries are deadlines, not midnight appointments.
- Tag grouping repeats multi-tag tasks in matching groups; include Untagged. Counts and bulk selections deduplicate IDs. Due-day grouping ends with No due date; status/priority have defined fixed order.
- Recurring occurrences are individual rows with a repeat indicator; templates do not appear as duplicate tasks. Cancelled/skipped instances follow the status filter.
- Saved views persist name, search, filters, grouping and sorts locally and sync. Support edit/delete/default; a deleted default falls back to All. Scroll position and panel width stay local.

Month/agenda views use the same query and occurrence rules. Distinguish date-only/timed and overdue/completed with labels/icons, not just color. Select a date to prefill capture; open task details from either view. Estimates never imply occupied calendar blocks. An Undated link keeps those tasks accessible.

Retain drafts on save failure; provide clear empty/error states and accessible save feedback. Confirm destructive bulk actions. Undo a synced delete through an explicit restore command with a tombstone precondition, never through an ordinary stale update.

## 8. Concrete sync protocol

### Local operations

Generate ordinary entity/operation IDs with client UUIDs. Assign every account installation a random device epoch and strictly increasing operation sequence, allocated in the same SQLite transaction as the local change. Persist field patches, their observed field versions, base values and any predecessor-operation dependencies. Never send whole stale task snapshots as updates.

Maintain accepted server state separately from pending local changes. On downloads, update the shadow, then replay pending operations to form the visible local projection. Preserve the original causal base: replay must not silently rebase a conflicting patch onto the latest server version. Several local edits to the same field refer to the preceding local operation; bind the next command to its predecessor's accepted version. If that predecessor conflicts, retain and hold the dependent command. Unrelated entities continue syncing.

One worker owns the outbox per profile. Coalesce only unsent independent changes with a proven equivalent result. Never change an operation payload after it has possibly been transmitted.

### Server ordering and apply operation

Expose versioned apply_operations, pull_changes, begin_snapshot, read_snapshot_page and resolve_conflict RPCs. Derive owner from authenticated identity, never from a trusted client owner_id. Validate command shape, size, schema, cross-owner references and bases. Ordinary clients have no direct domain-table write path bypassing this protocol.

For each small transaction, lock that account's account_state row. Allocate its next revision using a transactional counter, not an independent SQL sequence. Apply entity patches, field versions, conflicts, idempotency receipt, device sequence and change-log entry in the same commit. Hold the account lock through commit. This serialization means a client cannot advance past a lower revision whose transaction has not committed yet. It is a deliberate small-personal-account tradeoff.

Each log revision contains a complete logical change group, including related rows/tombstones/conflicts. Paginate between revisions, never halfway through a group. Pull returns revisions greater than cursor in ascending order plus a committed high-water mark; local application of each page and cursor advancement is atomic. Retry an interrupted page safely.

Only accept the next contiguous sequence for a device epoch. The unique owner/epoch/sequence and operation UUID prevent duplicate application. Keep detailed receipts for 180 days and compact accepted-sequence watermarks indefinitely. Old replay returns already_processed and forces catch-up/snapshot if its detailed receipt has expired; it never reapplies the mutation. Reject a reused retained operation identity with a different payload.

If an operation is invalid, record an explicit terminal rejection/consumed sequence (without modifying domain data) so later work is not permanently blocked. Preserve the rejected edit for repair. Authentication/network errors consume nothing. Conflicts are acknowledged processed commands with recovery records; dependent edits wait for resolution.

### Downloads, reconnect and retry

Trigger automatic sync on local commit, launch, resume, successful auth, network return and remote hints. Connectivity indicators are hints; actual request success determines connection health.

Use one owner-filtered Realtime subscription to account revision changes as a wake-up signal, with no task content in the hint. Realtime is not the durable log. Pull on subscription/reconnection and poll the revision endpoint every 30 seconds while foreground-active as a missed-event fallback. Coalesce bursts and disable continuous polling when suspended. [Supabase Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes)

Target: p95 local-commit-to-visible-on-second-device <=5 seconds over 100 edits with two foreground authenticated devices, same healthy region, RTT <=150 ms, no injected loss and 10,000 tasks. Record actual measurements. With realtime intentionally disabled, target <=35 seconds for at least 95% of trials under the same conditions. Neither target applies while OS-suspended, offline or backend-paused.

Use exponential backoff with jitter (roughly 1 second to 5 minutes), respect Retry-After, and reset on a new successful connection. Resume promptly on foreground/network return without generating parallel retry loops. On auth expiry attempt refresh once; if unavailable, pause transport and offer reauthentication. Continue local edits indefinitely. Manual retry is troubleshooting, not the normal workflow.

UI states: Local only, Offline with N pending, Syncing, Synced with last successful time, Sign-in needed, and actionable error. Acknowledged upload and complete download are separate progress values. Keep normal status subtle; surface conflicts and persistent failures in a details panel. Never say Synced when unresolved pending commands remain.

### Initial snapshots and devices offline a long time

begin_snapshot takes a short account lock and captures a consistent immutable snapshot plus revision S and device watermarks in one transaction. Store paged temporary snapshot records with owner, token and 24-hour expiry. Start with 200 records/page and a measured payload cap. Limit simultaneous snapshots per account; account for their temporary storage in quota monitoring. This is simpler for personal scale than implementing arbitrary temporal queries.

Download into staging tables with a durable token/page checkpoint. An interruption resumes the same snapshot; expiry restarts staging only. Existing local entities and outbox remain untouched. After validation, atomically install the accepted shadow, preserve/replay local pending work, set cursor S, then pull all revisions >S. The UI may show existing local tasks throughout and clearly mark initial download progress. New local creations during download remain pending and cannot be overwritten.

Retain change log and detailed receipts for 180 days; retain minimal deletion keys and accepted-sequence watermarks until account deletion. Keep unresolved conflicts until explicitly resolved; retain resolved conflicts 90 days and deleted content 30 days for recovery, then only deletion keys. Completed occurrence history remains until user deletion. These are proposed product policies, not Supabase guarantees.

If a cursor predates log retention, require a fresh snapshot before uploading stale commands. Compare their original field bases against current versions; missing bases become recovery/conflicts, never blind overwrites. Tombstones reject stale edits. A stale device may restore meaningful content only through explicit restore/copy decisions.

Expired receipt plus already-processed sequence means reconcile from snapshot rather than replay. Restoring a local backup registers a new installation epoch and imports content through the import policy; it does not reuse old queue/sequence state. A restored/replaced backend must bump server epoch; clients detect this and retain pending data for recovery instead of treating a reverted cursor as current.

No indefinite operation log is required, but minimal deletion/deduplication metadata grows. Monitor capacity and offer export/archive choices. Never automatically delete tombstones to save quota while old devices could replay.

### Conflict policy

For each field/group, apply when its supplied base version equals current version. If it changed but the proposed value already equals current value, accept as equivalent. Otherwise keep current canonical value and save both alternatives/base in a conflict record. This is first-accepted on a genuinely concurrent same-field conflict, followed by explicit resolution; device timestamps do not select winners. Distinct uncontested fields in the command can apply while conflicting fields are retained for review.

Treat due kind/date/instant/zone as one atomic group, status/completion as another, and each recurrence rule as another. Validate the resulting entity and relationship invariants before committing any accepted group. Never combine individually valid fields into an invalid mixed date model. A command that depends on another conflicted group is held rather than partially applied incorrectly.

| Conflict | Rule |
| --- | --- |
| Different fields | Merge independently; title from A and priority from B both survive |
| Same field | Keep accepted canonical value; retain candidate/base; resolution offers either version, edited value or copy |
| Completion vs ordinary edit | Preserve completion and content edit; editing does not reopen; status/completed_at are one group |
| Completion vs reopening/cancellation | Conflict on status group; retain history; canonical terminal state cancels local reminders |
| Deletion vs editing | Deletion dominates visibility. Preserve unsynced concurrent content in recovery; stale update never resurrects |
| Milestones | Separate entities: independent steps merge; completion/text independent; same-step field collision recoverable; deleted step wins visibility |
| Milestone ordering | Version the ordered-ID list as a group; concurrent reorder conflicts. Independent added steps remain, appended deterministically by ID if absent from accepted order |
| Tags | Membership operations per task/tag; independent tags merge; same membership add/remove uses version preconditions; tag deletion suppresses membership |
| Recurrence | Schedule is an atomic group; competing future segments conflict; preserve overrides/history as described above |
| Reminder rules | Separate rule IDs; concurrent additions coexist subject to cap; same-rule changes conflict; parent completion/deletion suppresses scheduling |
| Snooze | One versioned task/occurrence snooze group; concurrent different snoozes retain alternatives, canonical value wins scheduling |
| Saved views/preferences | Per-field/key conflict handling; query specification is one validated group to prevent invalid hybrid queries |

Conflict UI must show that a local change was preserved but not accepted. Resolution is another version-checked command, so a second concurrent resolution cannot silently overwrite the first. A deletion arriving after an accepted edit keeps the deleted content in recovery for the retention period; unresolved conflicting payloads are retained longer.

## 9. Guest adoption, sessions and security

Initial installation opens the guest database immediately. No backend configuration or signup is required for any core feature. Signing in opens an account profile and does not imply consent to upload guest content.

Offer “Keep guest tasks on this device” and an explicit “Copy guest tasks into this account” with count/preview. Copy using a crash-resumable adoption manifest and stable identity mapping; retain the guest source until transfer is verified. Guest and account DBs are separate, so do not pretend cross-file writes are one transaction: destination writes and its outbox are atomic, and the manifest makes replay idempotent. Mark the source adopted only after verifying the destination. Disable duplicate guest-profile notifications when account profile is active.

Use preserved IDs where safe; the account's existing entity/tombstone takes precedence and collisions are presented for merge/copy. The same guest lineage imported again into the same account reuses its mapping, including across devices. No deduplication by title. Existing account tasks are never replaced by an initial download.

Default sign-out retains that account's local cache and pending edits, makes it inaccessible through other app profiles, removes active session credentials, cancels its scheduled notifications and opens guest mode. Explain the pending count and offer Sync first, Keep on this device, or Export then remove local data. Discarding unsynced edits requires explicit destructive confirmation. Reopening a signed-out profile requires authentication for that same account; an expired session within an already open profile still permits offline work. Document this distinction in the UI.

Switching accounts freezes the old worker, checks account identity on every asynchronous response, clears UI caches and notifications, and activates only the new profile. Notification callbacks carry profile plus generation and are rejected if inactive/stale. Theme defaults to shared account value; a local “Use a different theme on this device” toggle overrides it. Device reminder enablement, permissions, OS IDs and layout never sync.

Use PKCE and the system browser, strict redirect allowlists, secure token storage keyed by account, and no OAuth client secret in the application. GitHub OAuth setup stores its secret only in Supabase configuration. [Supabase GitHub OAuth](https://supabase.com/docs/guides/auth/social-login/auth-github)

Enable RLS for every exposed account-owned table and snapshot/log/conflict endpoint. Include owner checks in read/update/insert policies; deny anonymous access. Protocol RPCs with elevated privileges need a fixed search_path, least-privilege role, explicit auth.uid ownership checks and restricted execute grants. Test raw REST and RPC bypass attempts, not just UI paths. Publishable client keys are not authorization. Service-role credentials never ship in app binaries. [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)

Use platform secure storage for tokens; validate Android backup/restore and Windows account behavior. SQLite task data is OS-profile protected, not automatically application-encrypted or end-to-end encrypted. The backend operator can access cloud data. Add an encryption ADR before implementation if that threat model changes. Logs exclude task contents, OAuth codes and credentials by default; diagnostics use error categories/counts, with explicit opt-in for any richer export.

Account/data deletion: provide export first, explicit confirmation and recent authentication. A narrowly scoped server function can delete the caller's owned data and auth account using server-only admin credentials; keep a resumable deletion job because auth deletion and database cleanup may span APIs. Immediately revoke access, then verify cleanup. Inactive clients must not recreate deleted accounts; subsequent sync enters recovery/export-only state. Explain that an offline device cannot be remotely wiped until it reconnects and local retained copies need device removal. Until the in-app path ships, document the operator Dashboard deletion procedure; do not claim a nonexistent endpoint.

## 10. Reminders, snooze and platform verification

Persist reminder intent separately from device registrations. Offer none, at due reference time, one hour before, one calendar day before and custom offset; up to five per task. Undated tasks cannot use due-relative reminders until a due value exists. Request OS permission only when enabling reminders and explain denied/disabled permissions with a settings link.

Device reminders are off until the user enables them on that installation. Thereafter schedule every eligible reminder on each enabled device by default; settings explain possible duplicate alerts. Completion/snooze sync promptly between active connected devices. An offline device can still show its previous schedule. No globally exactly-once notification claim.

Planner reconciliation computes desired reminders from local tasks/occurrences, rules, status and snooze, then diffs against durable device registrations. Edits, completion/cancellation/deletion, sync, import, launch/resume, clock/zone changes, permission changes and supported reboot/package-update hooks mark it dirty. OS registration is outside SQLite's transaction: use a persistent dirty flag, idempotent logical keys, registration generation and retry. Startup repair handles a crash between database commit and OS scheduling.

For due-time edits, cancel old registrations before installing replacements; report scheduling errors independently from a successful task save. Notify actions re-read local status/generation before completion/snooze so stale callbacks cannot reopen tasks. Never put account credentials in notification payloads. Offer hidden task titles on the lock screen.

Snooze presets: 10 minutes, 1 hour, tomorrow at the configured time; custom future date/time. It changes only snooze state. For that task/occurrence, suppress scheduled reminders up to the snooze instant, replace them with one snooze notification, retain later reminders and coalesce an equal-time reminder. A second snooze replaces the first. Completion/cancellation/deletion cancels all. Reopening clears obsolete snooze and schedules future rules; other occurrences are unaffected. Notification action buttons are enabled only where tested; in-app snooze always exists.

Queue strategy: schedule the nearest 48 reminders within 30 days initially, reserving capacity for snoozes. Refill on all reconciliation triggers; show coverage-through time when truncated. More than 48 reminders or long inactivity can exhaust coverage: do not imply unlimited unattended scheduling. Android background replenishment is best effort. Missed reminders surface in-app on next open without a burst of stale notifications. Test whether a longer horizon is useful before changing this conservative bound.

Verified platform constraints and required evidence:

| Platform | Documented constraints | Release evidence needed |
| --- | --- | --- |
| Android | Runtime notification permission; exact alarm access is separate; reboot requires rescheduling; OEM restrictions may interfere | Physical-device permission denial/revocation, normal close, force-stop, reboot, Doze/battery saver, clock/zone change, upgrade and actions |
| Windows | Scheduled notifications can fire with app closed; Microsoft documents a five-minute delivery window when the PC is off. Plugin lacks repeating notifications and package identity matters for notification management | Installed MSIX scheduling/cancellation, closed-app actions, reboot, sleep/offline, disabled notifications, update and certificate continuity |
| iOS, planned | Plugin documents 64 pending notifications | Physical-device scheduling/actions/background tests before support claim |
| macOS, planned | Separate permissions/packaging behavior | Signed app tests before support claim |
| Linux, planned | Plugin has no scheduled/pending-notification API | Separate scheduler proposal required; do not label reminders supported |

Sources: [Android alarms](https://developer.android.com/develop/background-work/services/alarms), [notification plugin limits](https://pub.dev/packages/flutter_local_notifications), [Windows plugin](https://pub.dev/packages/flutter_local_notifications_windows), [Windows scheduling](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/app-notifications-scheduled).

Default Android scheduling should disclose potential delay when exact access is unavailable; request special access only for an explicitly selected exact reminder mode, within platform policy. Never report exact delivery without permission. Force-stop, powered-off devices and OS restrictions prevent uniform reliability. Windows uses one-shot schedules for recurrence and a tested package identity; a loose executable is not sufficient evidence of release notification behavior.

All behavior in the release-evidence column is currently unverified.

## 11. Backup, import and recovery

Use a documented UTF-8 JSON format with format/version, export ID, source lineage, UTC export time, counts and canonical checksum, plus tasks/tags/milestones/relations, priorities, recurrence segments/overrides/history, reminders/snoozes, saved views and portable preferences. Credentials, device IDs, permissions, OS registrations and transport cursors/outbox sequences are excluded. Include unsynced current values and unresolved user recovery data so an export does not lose work.

Validate version, size/depth limits, types/enums, IDs, dates/zones, foreign keys, recurrence bounds and checksum before writing. Unknown future versions fail safely. Preview counts, collisions and conflicts. No partial destructive import; use staging, an import journal and a local backup, then atomic installation of validated changes. Large imports can stage in batches without exposing incomplete data.

Merge is default. Repeated source-lineage/entity identities resolve through a persistent mapping; identical data is skipped, differing same-ID content is previewed/conflicted, unrelated IDs are new. Never deduplicate by title. A cloud tombstone is not silently overwritten by an older export; restoration requires an explicit restore or copy-as-new decision.

Replace is available only with explicit scope, backup and destructive confirmation. In guest mode it replaces the selected guest workspace. With sync enabled, default to a new guest workspace; an explicit account replacement is a batch of normal versioned deletions/import commands with a clear cross-device warning, never a raw database overwrite or server truncate. Imported changes use fresh operation identities and current account authorization; never import sync receipts/cursors as trusted state.

Reconcile reminders only after import commits, with notification preview for large batches. File exports contain private plaintext unless the user chooses an encrypted destination; state this clearly. Local auto-backups and manual exports complement cloud sync, which is not a backup. Provide recovery fixtures for crash mid-import, migration failure, disk-full and a restored old database.

## 12. Repository, CI, configuration and releases

Proposed structure after review; do not treat these paths as already delivered:

    lib/{app,domain,application,data,features,platform}/
    test/  integration_test/  drift_schemas/
    android/  windows/
    pubspec.yaml  pubspec.lock
    supabase/{migrations,tests,functions}/
    docs/{architecture,adr,runbooks,verification,proposals}/
    .agents/skills/{database-migrations,sync-protocol,release-verification}/SKILL.md
    .github/{workflows,ISSUE_TEMPLATE}/
    README.md  AGENTS.md  CHANGELOG.md

Build and document only the new native application and its optional backend. Legacy restoration, compatibility bridges and history rewriting are outside the implementation plan.

Root README will distinguish implemented, tested, planned and configuration-blocked features; include purpose, platform matrix, setup/run commands and screenshots once the UI exists. Root AGENTS will document layout, conventions, commands, meaningful verification, data-preservation boundaries and release authorization requirements for the new application.

Create substantive skills for: (1) local/server migration invariants and fixture recovery, (2) protocol compatibility/conflict/RLS/two-device verification, (3) signing, installed-app checks and release evidence. Each should reference real commands and artifacts, not repeat AGENTS or contain empty placeholders. Add issue templates for bug/platform evidence and features, plus a PR template for scope, migrations, tests, screenshots and limitations.

Decision records, initially Proposed:

| ADR | Choice and principal tradeoff |
| --- | --- |
| 001 Native stack | Flutter/Drift vs PWA/Tauri/RN/MAUI; shared native persistence/UI with platform-specific notification adapters |
| 002 Optional backend | Supabase Free + RPC protocol; low hosting maintenance, application-owned sync complexity, possible pauses |
| 003 Sync consistency | Transactional per-account cursor + field versions; serialization suits personal scale |
| 004 Account isolation | Separate profiles/databases; explicit guest adoption; secure tokens but no promised task E2EE |
| 005 Temporal semantics | Civil dates, fixed one-off instants, zone-bound recurrence and stable ordinal identities |
| 006 Notifications | OS-local, per-device enablement, bounded queue and explicit reliability limits |
| 007 Distribution | Android APK/Windows MSIX first; signed artifacts and public publication are separate |

Setup runbook will pin Flutter/Dart, Java/Android SDK/Gradle, Windows C++ build tools/SDK, Supabase CLI and local container prerequisites. Use flutter doctor to capture actual readiness; do not install tooling merely to complete this proposal. Local Supabase/container development must not be represented as production hosting.

Configuration example will contain only SYNC_ENABLED, SUPABASE_URL and publishable client key; missing sync config boots guest mode normally. OAuth redirects and server provider secrets are separate operator setup. Signing keys, database passwords, service-role keys and access tokens never go in source or app configuration examples.

Planned app commands from the repository root: flutter pub get; dart format --output=none --set-exit-if-changed .; flutter analyze; flutter test; flutter test integration_test -d <device>; flutter run -d windows or <android-device>; flutter build windows --release; flutter build apk/appbundle --release. Pin code-generation and local backend test commands once real packages/configuration exist. These commands were not run in this review.

### Workflows and gates

| Workflow | Trigger/host | Scope and permissions |
| --- | --- | --- |
| PR quality | PR; standard Linux/Windows jobs as needed | Formatting, analysis, domain/widget/migration tests; contents:read; no production/signing secrets |
| Native build | PR/default branch; Linux Android + Windows native host | Compile initial targets; label debug/unsigned artifacts accurately; short retention; no store claim |
| Backend tests | PR/local Supabase | Apply migrations to empty DB and upgrade fixture; SQL/RLS/protocol integration tests with synthetic accounts |
| Versioned release | Approved v* tag; target build hosts | Verify tag matches pubspec/changelog, rerun gates, generate checksums, publish artifacts; contents:write only for publication job |
| Signing | Protected release environment | Android keystore or Windows certificate; fail closed if missing; never substitute debug signing |
| Backend deploy | Manual protected-environment dispatch for reviewed commit | Plan/diff, backup verification, migration lock, apply, smoke/RLS checks; restricted backend credentials |
| Store distribution | Separate explicit protected job when accounts exist | Upload signed packages only after prerequisites/test evidence; missing accounts remain documented blockers |

Pin third-party Actions by reviewed commit SHA; use ephemeral runners, minimal permissions, timeouts and concurrency groups. Do not use pull_request_target to execute untrusted changes with secrets. Public config is not a production secret, but no real credentials/data enter PR tests.

Backend deployment uses expand/contract migrations and a supported client protocol range, because offline clients may be old. Take an operator dump/verified backup before consequential changes. Prefer tested forward fixes. Restoration is a documented incident action, not an automatic down migration; after restoring older state, bump backend epoch and reconcile clients. Migration deployment serializes by environment. Never let production migration failure pass as success.

Artifact distinctions: a Windows ZIP of build outputs is not an installed/signed MSIX; an APK is not a Play listing; an AAB is an upload artifact, not a direct installer. Installed behavior must be tested with the actual release package. Store publication, signing and backend deployments remain blocked until their external setup exists. No placeholder deployment workflow will be advertised as working.

## 13. Phased delivery and acceptance gates

Every implementation phase should end with a runnable build or preserved usable baseline, reviewed changes, exact commands/results, screenshots where useful, platform matrix and updated backlog. Phase 1 establishes a runnable foundation, not a completed task manager; phase 2 is the first usable native task application. Subsequent phases preserve local usability.

| Phase | Deliverable and change | Verification gate | Remaining limits |
| --- | --- | --- | --- |
| 1 Foundation | Approve ADRs; initialize fresh Flutter application; pin toolchain; native shell/theme; schema/migrations and command/outbox skeleton; protocol/recurrence/notification contracts; repository docs/CI | Android/Windows compilation and local launch; real SQLite atomic rollback/restart/migration fixtures; protocol golden fixtures; CI reports real status | No working cloud sync, recurrence or notifications claimed; small notification/secure-storage feasibility spikes validate architecture risks only |
| 2 Offline app | Task CRUD, tags, milestones, priority, search/filter/group/sort, saved views, persistent preferences, responsive dark UI | Offline fresh-install and process-restart integration tests; widget/keyboard/text-scaling checks; actual database persistence | Calendar/recurrence/reminders and cloud sync remain pending; retain basic recovery/export tooling during development |
| 3 Accounts and sync | Real Auth/RLS/RPC deployment, secure session storage, guest adoption, bootstrap, outbox retries, conflicts, automatic foreground sync, account isolation | Two installed devices, real staging/local backend, network/auth fault injection, measured latency, RLS adversarial tests and restart-safe retries | No two-device claim based on mocks; blocked hosted tests explicitly reported; reminders/recurrence wait for this gate |
| 4 Recurrence/calendar/reminders | Deterministic recurrence/history, scope edits, month/agenda, local scheduling/snooze/reconciliation | Two-device recurrence races and stale-rule edits; DST/month-end cases; installed Android/Windows closed/reboot/permission tests | OEM/power-off/OS limits remain documented; Apple/Linux still planned |
| 5 Backup/hardening/releases | Full portable import/export, recovery, accessibility audit, complete migration coverage, packaged release/signing workflows, documentation/screenshots | Full acceptance matrix, historical upgrade/import fixtures, installed signed artifact tests; release evidence tied to commit/version | Public publication/backend release only with configured accounts/secrets and explicit release authorization |

Phase boundaries are usable vertical slices, not excuses to leave silent data risks. Schema/protocol design is phase 1; prove sync in phase 3 before building recurrence/reminders on it. Full export/import UX is phase 5, but keep internal backup/recovery tools and pre-migration backups earlier.

### Acceptance coverage (all currently not run)

| # | Required evidence | Phase |
| --- | --- | --- |
| 1 | Install with network disabled; create/edit/complete/reopen/delete without account | 2 |
| 2 | Kill/restart process and verify tasks/settings on disk | 2 |
| 3 | Offline filter/sort/priority/milestones/saved-view fixtures; month/agenda consistency | 2,4 |
| 4 | Offline scheduled reminder; edit cancels old and schedules replacement | 4 |
| 5 | Snooze modifies reminder state; assert byte-equivalent due fields | 4 |
| 6 | Guest consent flow, crash/retry adoption, no lost/duplicate tasks | 3 |
| 7 | Create on A visible on B without refresh; record 100-edit latency distribution | 3 |
| 8 | Completion and independent milestone changes propagate | 3 |
| 9 | Two offline devices: different-field merge, same-field recovery, order-independent convergence | 3 |
| 10 | Offline delete vs stale edit/expired cursor; no resurrection | 3 |
| 11 | Drop response after server commit; crash before local ACK; retry once logically | 3 |
| 12 | Both devices generate identical occurrence interval; unique keys/counts converge | 4 |
| 13 | Complete/skip/end series; history retained and later schedule correct | 4 |
| 14 | Priority and saved views sync; snooze conflicts/reconciliation tested | 3,4 |
| 15 | Bootstrap into profile with local pending tasks; no overwrite | 3 |
| 16 | Interrupt pages/expire snapshot/expire JWT; resume safely with local edits intact | 3 |
| 17 | Sign out with pending work; switch accounts; reject stale callbacks/responses | 3,4 |
| 18 | Date-only travel, spring gaps, fall folds, leap years and Jan 31 monthly rules | 1,4 |
| 19 | Old schema upgrade, migration failure recovery, versioned export/import and duplicate handling | 1,5 |
| 20 | Simulated backend down/read-only/auth failure while all local task actions continue | 3,4 |
| 21 | Account B cannot read/write A via tables, RPCs, snapshots, log, conflicts or realtime subscription | 3 |

Use meaningful unit/property tests for pure rules; real SQLite tests for atomicity/migrations; real PostgreSQL transactions for cursor ordering/deduplication/RLS; widgets for interaction/accessibility; installed-device checks for plugin/OS behavior. Mock transports are fault-injection aids, not proof of real multi-device integration.

### Repeatable two-device workflow

1. Record commit, app/protocol/schema versions, package identity, OS/build, device models, timezone/tzdata and backend region. Use a synthetic account X on Windows and Android, plus account Y for isolation tests. Never production task data.
2. Use local Supabase through a documented development network endpoint (not localhost from the phone), or a separately configured test project. Keep debug network exceptions out of release builds. Register valid OAuth redirects and stable app identities.
3. Start both online with seeded synthetic data, subscribe and catch up. Create/edit/complete/milestone/tag/priority/saved-view changes; measure local commit to second-device display without manual refresh. Document instrumentation overhead and clock calibration.
4. Disconnect both. Edit different fields, the same field, competing status values, different milestones, reorder/add steps and delete-vs-edit. Reconnect A then B; repeat from clean fixtures B then A. Assert convergence and preserved conflict payloads.
5. Inject a dropped post-commit response, duplicate operation, out-of-order sequence, interrupted page, app crash, expired token, lost realtime, read-only backend and expired cursor. Assert no duplicate changes/cursor gaps and responsive local UI.
6. Bootstrap a third clean profile while creating local tasks; interrupt/restart. Exercise guest adoption twice, sign-out with pending edits, account switch and stale notification callback. Check database/profile/notification separation.
7. In phase 4, generate the same recurrence on both offline devices, edit a future series on one and complete an old occurrence on the other, then reconcile. Test snooze/completion with one device offline and explicitly record any expected stale alert.
8. Record pass/fail/unverified per acceptance row with expected/actual state, logs stripped of content, exact build hashes and reminder delivery timestamps. Restore only synthetic test profiles. Attach evidence to the phase report.

Additional notification matrix: Android normal close vs swipe-away vs force-stop, reboot before trigger, permission denial/revocation, exact permission denied/granted, Doze/battery saver and an OEM device; Windows installed MSIX closed, reboot, sleep beyond delivery window, notification suppression, package upgrade and action activation. Repeat DST/date-only tests in Pacific/Auckland and another zone with a different transition, plus UTC. No platform is marked supported solely from emulator or compile success.

### Deferred backlog

iOS/macOS build/signing and physical verification; Linux scheduling adapter; light theme implementation; additional OAuth/email providers; encrypted task database/E2EE if required; optional background sync improvements within OS constraints. Sharing, attachments, AI and calendar scheduling stay out of scope. Do not add paid sync services without a separate necessity/alternatives decision.

## 14. Review status and verification record

This delivery is a proposed architecture and phased plan, not phase-1 implementation. Only this new proposal document is intended to change the repository. Existing deletions, commits and release files are preserved.

Performed: filesystem/path discovery; Git status/log/tree inspection; read committed AGENTS/README/architecture/planning source; inspected task model, database, helpers, repository, selected UI/tests and CI definitions; checked tool availability; browsed the linked official documentation. Node/npm and Docker commands were found; Flutter/Dart/adb were not found on PATH. Their absence from PATH is not proof that no installation exists elsewhere.

Not performed: npm install/tests/build, Flutter installation/build/tests, Supabase provisioning/migrations/auth, device execution, CI runs, packaging/signing, notification tests, latency measurement or any of the 21 application acceptance checks. No runtime capability has passed in this review.

Document/state verification: 14 numbered sections and all 21 acceptance rows found (pass). Git reports 54 existing tracked deletions and zero tracked modifications, plus this new proposal directory. git diff --check passed for tracked changes; it does not validate the untracked proposal. The proposal was read from disk for the structure check. Opening it in the app was requested; the app returned queued.

Fresh-start amendment: removed prior-product reuse, legacy migration and restoration prerequisites; simplified the app layout to the repository root. Existing architecture research and all 21 acceptance requirements remain applicable. This amendment changes the proposal only.

Review completed: the user accepted the proposed decisions with “they look good.” Phase 1 implementation is authorized. Subsequent reports distinguish implemented behavior from remaining verification gates.

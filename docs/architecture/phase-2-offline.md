# Phase 2 offline behavior and local command contract

## Using the app

Quick capture keeps the title, optional due date and Add task together. The date
button offers Today, Tomorrow, Choose date and (when set) No due date. Saving
commits title and date in one command; success clears both and failure keeps both.
Open a task title to edit it. Title and due date appear first; optional time
controls appear after Add time. More details expands the remaining fields and
retains their draft values when collapsed. There is no separate Add with details
flow. Task actions provide deletion; Select tasks enables deduplicated
bulk deletion with confirmation. A local snackbar offers Undo for deletion and
status changes. Delete undo restores retained children and checks the original
delete operation; a newer deletion or stale status snapshot is rejected.
Undo is a short-lived in-session action, not a persistent trash/history browser.

The editor supports all four statuses, all priorities, description, a positive
whole-minute effort estimate, multiple reusable tags and ordered checklist steps.
Steps have explicit move-up/down buttons for touch and keyboard use. Completing
a task does not complete its steps, and completing all steps does not complete
the task. Manage tags renames/deletes labels across tasks; deleting a tag keeps
the tasks and retained membership records. A renamed tag cannot collide with
another active normalized name; capture reuses a case/whitespace-equivalent tag.

Save feedback means SQLite committed locally. Editor, capture and name-dialog
failures keep inputs for retry. A task changed/deleted since opening is rejected
instead of overwriting newer data. Closing an editor requires draft-discard
confirmation. Ctrl+N focuses capture, Ctrl+F opens filters, Ctrl+S saves details.
Desktop uses a sidebar and a centred full editor; narrow/large-text layouts use
a navigation drawer and scrolling editor. There is no adjustable split pane.

## Dates

Date-only values remain YYYY-MM-DD across travel. They become overdue only after
the device's civil day passes them. Timed one-off tasks capture a date, HH:mm and
an explicitly selected IANA zone (the input starts at UTC; it does not guess the
OS zone). The stored deadline is a fixed UTC instant; cards display device-local
time, while task details retain the original wall time and named zone.

DST gaps advance by the gap. Folds use the earlier instant unless the user checks
Use later instant. The editor previews the resulting deadline. Bundled timezone
0.11.1 data resolves entries offline; no timezone service is contacted. The
[package's official documentation](https://pub.dev/packages/timezone) describes
its embedded IANA data and APIs. No OS zone-discovery plugin is required.
Estimates never create calendar bookings. Due values do not schedule reminders.

Views recalculate every minute while open and immediately on app resume; an
exact deadline or midnight transition can therefore take up to one minute to
change its visible overdue state. Native clock/zone-change behavior still needs
installed-target verification.

## Query and saved-view rules

- Status and priority selections OR within each dimension; dimensions AND
  together. Tags use any selected by default, with an explicit all-selected switch.
- Search lowercases and normalizes whitespace; every token must occur somewhere
  in title, description or active tag labels. Search is literal, not SQL syntax.
- Due ranges are inclusive displayed civil days. Undated cannot combine with
  ranges, overdue, Today or Upcoming. Invalid combinations retain filter inputs.
- Today includes open tasks due today; Upcoming includes open tasks after today;
  Overdue uses passed deadlines on open tasks. All includes every nondeleted
  status and undated tasks. Completion/cancellation suppress overdue.
- Default order is due ascending, priority descending, created ascending, ID.
  Other sorts are priority (highest first), created, normalized title and effort.
  Reversal keeps null dates/estimates last and keeps created/ID tie-breakers.
  Date-only tasks precede timed entries on the same day in either direction.
- Grouping preserves membership. Status and priority have fixed orders; due-day
  groups end with No due date. Tag groups repeat multi-tag tasks and include
  Untagged. Tag headings use a # prefix to distinguish a tag named Untagged.
  Overall counts and bulk selection deduplicate immutable task IDs.
- Save view stores current search, filters, built-in scope, group and sort.
  Change controls, then choose Update name and current settings to edit it.
  Choose Use as startup default to persist the default across restarts. Deleting
  the default returns to All Tasks. A malformed/unsupported view is identified in
  navigation and can be deleted; it never blocks access to task data.

SQLite is authoritative. A transaction reads a consistent workspace snapshot;
Dart applies deterministic query/group rules to that snapshot, including injected
display-zone rules in tests. This keeps civil/timed ordering consistent across
platforms. Search/filter execution is currently an in-process projection, not
SQL pushdown/FTS; all active tasks are loaded. No large-workspace performance
claim is made. Future pagination/query pushdown must preserve the tested rules.

## Transactions and compatibility

No schema structure changed: existing v1 files open without migration, reset or
snapshot replacement. Existing foundation commands and data remain usable.
Every logical command writes its entity changes, outbox sequence, history and
notification-dirty intent in one transaction. Bulk deletion is all-or-nothing.
Task deletion writes a tombstone and hides children through parent visibility;
explicit restore requires the expected deletion operation and removes it.

Protocol envelope version remains 1 (no header changes). The guest command
vocabulary is expanded; Phase 3 must implement/validate these commands before
account operations can be enabled. Guest journals are never uploaded blindly.
Task creation now uses the same atomic status_group as editing/status commands.
Changes contain field patches, not a complete stale editor snapshot.

| Commands | Changes / grouping |
| --- | --- |
| task.create, task.edit | changed title/description/priority/estimate_minutes; atomic due object; atomic status_group; provenance timestamps |
| task.status | status_group with status/completed_at, updated_at |
| task.delete | deleted_at; tombstone and hidden parent visibility |
| task.restore | expected_delete_operation, deleted_at=null, updated_at |
| task.tag | independent task_id/tag_id/removed membership; predecessors include parent task and tag |
| milestone.create/edit/delete | separate ID; changed text/completion or deletion; create includes task_id |
| task.milestone_order | complete ordered_ids group; independent milestone entities retained |
| tag.create/edit/delete | name/normalized_name or deletion marker |
| view.create/edit/delete | name, spec_version=1, versioned query spec or deletion |
| preference.set | shared default_view key/value; independent preference entity |

Milestone completion timestamps are set by the command clock on a completion
transition; existing completion history is retained. Device timestamps remain
provenance, never conflict ordering. Account mutations still fail atomically
until Phase 3 supplies shadow-aware revisions. No provider adapters, auth,
transport, recurrence, calendar or OS notification calls are exposed.

Implement phase 2 of DoUrStuff: a usable, complete offline task-management app.
Use the repository opened in this session. Start by reading root AGENTS.md,
README.md, docs/backlog.md, docs/architecture/README.md, the accepted architecture
in docs/proposals/2026-10-03-offline-first-architecture.md, ADRs and the latest
docs/verification reports. Apply relevant .agents/skills workflows when changing
the schema, command protocol or release verification. Inspect code and Git status
before editing; preserve useful work and unrelated changes.

The architecture is approved: Flutter with Drift/SQLite, Android and Windows
first, optional Supabase later, no account required for core features. Do not
restore the old web application or repeat stack selection. At the 9 October
review, core Phase 2 features are implemented and host checks pass, while Android
installed offline/restart acceptance remains open. Read the latest dated evidence
and resume remaining fixes/acceptance rather than rebuilding the feature list.
Preserve the title/due-date capture flow, collapsed More details editor and
collapsible search refinements unless new requirements justify changing them.
Reserved tables and domain interfaces do not imply complete later-phase features.
Proceed with implementation and testing without
another architecture approval; ask only focused questions that materially affect
the design. Verify new dependencies/capabilities with official documentation.

Deliver these usable features:

- Full task viewing/editing/deletion and reopening; title, description, priority
  none/low/medium/high, todo/in-progress/completed/cancelled, optional date-only
  or timed due value, estimated duration and accurate timestamps. Keep overdue
  derived. Preserve civil days across zones and follow the accepted timed-task
  policy; an estimate is not a scheduled calendar block.
- Fast capture, reusable multiple tags and ordered checklist milestones with
  independent completion. Provide validation, failed-save draft retention,
  sensible empty/error states, practical undo and destructive bulk confirmation.
- Search and filters for status, tags, priority, due range, overdue and undated
  tasks; grouping by status/due day/tag/priority; sorting by due date/priority/
  created/title/duration. Implement the accepted AND-between-dimensions and
  within-filter semantics, tag-group duplication/count rules, null placement
  and deterministic tie breaking. Make behavior clear in UI and tests.
- Today, Upcoming, Overdue and All Tasks, plus named saved views containing
  search/filter/group/sort settings. Create/edit/delete/select a default saved
  view, and persist preferences across restarts. All operations work offline.
- Responsive dark navigation and task details for touch and keyboard/mouse;
  shared theme tokens ready for later light mode, explicit priority labels/icons,
  screen-reader labels, text scaling, visible focus and useful save feedback.

All UI reads and writes go through local SQLite. Every domain mutation must
atomically persist its journal operation, sequence, history and notification
reconciliation intent. Keep guest/profile isolation and the existing account
command guard until phase 3 adds real shadow-aware account operations. Do not
invent fake sync states or provider adapters. Shared saved views must be ready
for future sync; device layout settings remain local. Keep provider code out of
the domain. Add state-management dependencies only where they solve actual
shared-state needs.

Treat existing schema-v1 installations as real: preserve data, use explicit
versioned migrations if structure changes, retain old snapshots and test upgrade
paths. Do not reset databases on errors. Implement query/domain validation for
reserved fields rather than assuming their presence is sufficient.

Verify meaningful repository/query/widget behavior using real SQLite: restart
persistence, atomic rollback, edit/delete/undo, tags and milestone ordering,
filter combinations and stable ordering, saved-view defaults and malformed input,
date-only/time-zone boundaries, empty results and failed-save recovery. Run the
pinned formatting, analysis and full test suite; build available native targets.
Exercise large text and narrow/wide layouts and update real UI previews. Record
native-device gaps honestly; passing host tests is not installed-device evidence.

Keep phase 1 platform gates visible while completing independent phase 2 work.
Do not implement cloud sync, recurrence, calendar or notifications in this phase;
their accepted boundaries must remain compatible. Update README, backlog and
docs/verification/phase-2.md with exact checks, results, remaining acceptance
gates and next actions. Do not push, deploy or publish unless separately
authorized. Finish with what changed, how it was verified and any limitations.
Keep a dated next-session handoff in docs/verification/phase-2.md with remaining
acceptance, exact device/setup prerequisites and the next executable action.

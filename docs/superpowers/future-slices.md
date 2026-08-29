# Future Slice Plans

This document preserves the intended post-Planning-Views roadmap for future Codex sessions. It is a planning handoff, not an implementation-ready spec. Each slice should still get its own design spec and implementation plan before code changes begin.

Start with:

1. `docs/superpowers/README.md`
2. `docs/superpowers/specs/2026-07-14-planning-views-design.md`
3. `docs/superpowers/plans/2026-07-14-planning-views.md`
4. this file

## Roadmap Order

1. Planning Views
2. Reminder Basics
3. Recurring Tasks
4. Natural Date Entry
5. Local Reliability
6. Sync/Auth
7. AI Capture
8. Sharing

Planning Views already has an approved design and an implementation plan. The remaining sections describe the slices after that.

## Shared Constraints

- Keep `Next.js` App Router, React, Dexie, Tailwind CSS, and Vitest unless a later spec explicitly changes that decision.
- Keep the app useful offline.
- Prefer vertical slices: each release should deliver one complete user-facing workflow.
- Avoid backend/auth work until Sync/Auth.
- Avoid native mobile packaging until the web/PWA reminder limits are proven painful.
- Keep AI optional, user-invoked, and review-before-save.
- Use small feature modules rather than growing `task-helpers.ts` and `useTasks.ts` indefinitely.
- Run verification before completing implementation work:

```powershell
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

## Slice 2: Reminder Basics

### Purpose

Let users attach simple reminder intent to a task and see which tasks have reminders. This slice should make reminders visible and editable before trying to guarantee perfect background delivery on every platform.

### User-Facing Outcome

A user can open a task, choose a reminder such as `At due time`, `1 hour before`, or `1 day before`, save it, and later see reminder indicators in the task list/calendar. The app can ask for browser notification permission and show local/in-app reminder state.

### Likely Scope

- Add reminder fields to the task model.
- Add reminder controls to the task editor.
- Show reminder indicators on task cards.
- Add notification permission UI.
- Add in-app reminder due/ready indicators.
- Keep notification behavior best-effort for PWA/browser limitations.

### Likely Out Of Scope

- Push notification infrastructure.
- Server scheduling.
- Guaranteed mobile background notifications.
- Recurring reminder repeats.
- Syncing reminders across devices.

### Likely Files And Modules

- `src/features/tasks/types.ts`: add reminder fields to `Task` and `TaskDraft`.
- `src/db/app-db.ts`: add a Dexie schema migration.
- `src/features/reminders/reminder-types.ts`: reminder option types and constants.
- `src/features/reminders/reminder-helpers.ts`: reminder timestamp calculation.
- `src/features/reminders/reminder-permissions.ts`: browser notification permission helpers.
- `src/features/tasks/components/task-editor.tsx`: reminder controls.
- `src/features/tasks/components/task-list.tsx`: reminder indicators.
- Tests under `src/features/reminders/` and affected task component tests.

### Data Model Direction

Candidate task fields:

```ts
reminderOffsetMinutes: number | null;
reminderAt: string | null;
reminderDismissedAt: string | null;
notificationsEnabled: boolean;
```

`reminderAt` should be derived from `dueAt` plus the selected offset. Tasks without due dates can either disable reminder selection or allow an explicit reminder datetime. Prefer disabling reminders for undated tasks in the first reminder slice.

### Testing Focus

- reminder timestamp calculations for date-only and date-time tasks
- reminder disabled when no due date exists
- editing a due date recalculates reminder time
- completed/cancelled tasks do not show active reminder warnings
- notification permission helper handles unsupported browsers

### Open Decisions

- Should reminders require a due date in the first version?
- Which reminder presets should ship first?
- Should the app display a global notification permission prompt, or only ask when the user first chooses a reminder?
- Should date-only tasks remind at a default local time, such as 9:00 AM?

### Suggested First Spec Question

Should Reminder Basics require a due date before reminders can be enabled, or should users be allowed to set a standalone reminder date/time?

## Slice 3: Recurring Tasks

### Purpose

Let users create simple repeating tasks without turning the app into a complex scheduling system.

### User-Facing Outcome

A user can mark a task as repeating daily, weekly, monthly, or never. When the current occurrence is completed, the app creates or schedules the next occurrence while keeping the completed one in history.

### Likely Scope

- Add simple recurrence presets.
- Add recurrence controls to the task editor.
- Display recurrence metadata on task cards.
- Generate the next occurrence when a recurring task is completed.
- Keep recurrence local-only.

### Likely Out Of Scope

- Arbitrary RRULE editing.
- Complex exceptions/skips.
- Shared recurring tasks.
- Server-side recurrence processing.
- Recurrence notifications beyond what Reminder Basics already supports.

### Likely Files And Modules

- `src/features/tasks/types.ts`: add recurrence fields.
- `src/db/app-db.ts`: add a Dexie schema migration.
- `src/features/recurrence/recurrence-types.ts`: recurrence preset types.
- `src/features/recurrence/recurrence-helpers.ts`: next occurrence calculation.
- `src/features/tasks/task-repository.ts`: create next occurrence on completion.
- `src/features/tasks/components/task-editor.tsx`: recurrence controls.
- `src/features/tasks/components/task-list.tsx`: recurrence labels.
- Tests under `src/features/recurrence/` and task repository tests.

### Data Model Direction

Candidate task fields:

```ts
recurrencePreset: "none" | "daily" | "weekly" | "monthly";
recurrenceAnchorAt: string | null;
recurrenceParentId: string | null;
```

For the first version, avoid a full recurrence engine. Use local helper functions that add days, weeks, or months based on the existing due date.

### Testing Focus

- daily, weekly, and monthly next occurrence generation
- date-only recurrence stays date-only
- date-time recurrence preserves local time
- completing a non-recurring task does not create a new task
- completing an already-completed recurring task does not create duplicates

### Open Decisions

- Should recurring completion immediately create a new task, or update the same task to the next due date?
- Should monthly recurrence clamp to the last valid day if a month is shorter?
- Should generated occurrences inherit tags, description, reminders, and status?

### Suggested First Spec Question

When a recurring task is completed, should DoUrStuff create a separate completed history item and a new open task, or simply move the same task forward to the next due date?

## Slice 4: Natural Date Entry

### Purpose

Make task capture faster by allowing users to type common relative due dates instead of using only date/time inputs.

### User-Facing Outcome

A user can type a date phrase such as `tomorrow 6pm`, `in 4 hours`, or `next Friday` while creating/editing a task, preview the interpreted due date, and save it as the task due date/time.

### Likely Scope

- Add a small natural date input to the task editor.
- Parse a limited set of common phrases.
- Show an editable preview before saving.
- Store the parsed result in existing `dueAt` and `dueDateOnly` fields.
- Keep parsing deterministic and local.

### Likely Out Of Scope

- AI-powered parsing.
- Locale-wide natural language support.
- Ambiguous phrase handling beyond clear fallback.
- Voice input.
- Recurrence phrase parsing.

### Likely Files And Modules

- `src/features/dates/natural-date-parser.ts`: deterministic parser.
- `src/features/dates/natural-date-parser.test.ts`: parser tests.
- `src/features/tasks/types.ts`: optionally add `relativeDeadlineInput` if preserving original text is useful.
- `src/features/tasks/task-helpers.ts`: integrate parsed due values into draft handling if needed.
- `src/features/tasks/components/task-editor.tsx`: natural date input and preview.

### Data Model Direction

Prefer storing only structured due fields at first:

```ts
dueAt: string | null;
dueDateOnly: boolean;
```

Add this optional field only if the UI needs to display the original phrase later:

```ts
relativeDeadlineInput: string | null;
```

### Testing Focus

- `today`, `tomorrow`, and `next Friday`
- `in 4 hours` and `in 2 days`
- AM/PM and 24-hour times if supported
- date-only versus date-time output
- invalid/ambiguous input returns a clear non-match result
- timezone and daylight saving edge cases where practical

### Open Decisions

- Which exact phrases should be supported in v1?
- Should natural date input replace date/time inputs or sit beside them?
- Should unsupported text block save or simply be ignored?
- Should parsed values overwrite manually selected date/time fields?

### Suggested First Spec Question

Should natural date entry be a separate quick input beside the normal date/time fields, or should it be part of a single smart task title field?

## Slice 5: Local Reliability

### Purpose

Give users confidence that local-first data is recoverable and understandable before adding account sync.

### User-Facing Outcome

A user can export their tasks, import a backup, recover recently deleted tasks, and see a clear explanation of where their data lives.

### Likely Scope

- Add JSON export.
- Add JSON import with validation.
- Add a trash/recovery view for soft-deleted tasks.
- Add permanent delete from trash.
- Add local data status copy.
- Keep all behavior browser-local.

### Likely Out Of Scope

- Cloud backups.
- Scheduled backups.
- CSV export unless specifically requested.
- Account-level restore.
- Version history.

### Likely Files And Modules

- `src/features/backup/backup-types.ts`: export/import payload types.
- `src/features/backup/export-tasks.ts`: build downloadable JSON.
- `src/features/backup/import-tasks.ts`: validate and import JSON.
- `src/features/backup/backup-validation.ts`: runtime validation helpers.
- `src/features/tasks/task-repository.ts`: list deleted tasks, restore tasks, permanently delete tasks.
- `src/features/tasks/components/trash-view.tsx`: trash/recovery UI.
- `src/features/settings/local-data-panel.tsx`: export/import/status UI.

### Data Model Direction

The current soft-delete fields are enough for an initial trash view:

```ts
deletedAt: string | null;
updatedAt: string;
```

Export payloads should include an app/schema version:

```ts
{
  app: "DoUrStuff",
  version: 1,
  exportedAt: string,
  tasks: Task[]
}
```

### Testing Focus

- export includes active and soft-deleted tasks
- import rejects malformed payloads
- import avoids duplicate IDs or overwrites by clear policy
- restore clears `deletedAt`
- permanent delete removes a task from IndexedDB

### Open Decisions

- Should import merge with existing tasks or replace all local tasks?
- Should export include soft-deleted tasks?
- Should there be a visible settings panel, or a small local data section on the main page?
- Should CSV export be part of this slice?

### Suggested First Spec Question

Should import merge into existing local data, or should it replace the local database after a clear confirmation?

## Slice 6: Sync/Auth

### Purpose

Allow users to sign in and keep tasks consistent across devices while preserving local-first offline behavior.

### User-Facing Outcome

A user can sign in, continue using the app offline, and have task changes sync across signed-in devices when online.

### Likely Scope

- Choose auth/backend provider.
- Add sign-in/sign-out UI.
- Add server-backed task persistence.
- Add local mutation queue.
- Add sync status indicators.
- Reconcile local and server task records.
- Keep existing local-only use available if feasible.

### Likely Out Of Scope

- Sharing and permissions.
- Complex conflict resolution UI.
- Enterprise auth.
- Background sync workers beyond what the web platform supports.
- Native mobile push.

### Likely Files And Modules

Provider choice affects files. Current recommended low-maintenance direction is Supabase, but this must be confirmed before implementation.

Possible Supabase-oriented modules:

- `src/lib/supabase/client.ts`
- `src/lib/supabase/server.ts`
- `src/features/auth/auth-provider.tsx`
- `src/features/auth/sign-in-panel.tsx`
- `src/features/sync/sync-types.ts`
- `src/features/sync/sync-queue.ts`
- `src/features/sync/sync-engine.ts`
- `src/features/sync/sync-status.tsx`
- `src/app/api/sync/route.ts` if using Next route handlers instead of direct Supabase client writes
- migrations/schema files depending on the chosen backend tooling

### Data Model Direction

Tasks will likely need:

```ts
userId: string | null;
version: number;
lastSyncedAt: string | null;
```

The local database will likely need a sync queue table:

```ts
syncQueue: {
  id: string;
  operation: "create" | "update" | "delete";
  entityType: "task";
  entityId: string;
  payload: unknown;
  createdAt: string;
  attemptCount: number;
  lastError: string | null;
}
```

### Testing Focus

- local mutations enqueue sync work
- sync sends queued changes when online
- server changes hydrate into Dexie
- soft deletes sync correctly
- sign-out behavior is explicit and safe
- failed sync attempts preserve local data

### Open Decisions

- Supabase Auth/PostgreSQL or Auth.js plus a separate PostgreSQL host?
- Should local-only usage remain fully supported after auth is added?
- What conflict policy should v1 use?
- What happens to existing local tasks the first time a user signs in?
- Should sync write directly to Supabase from the client or through Next route handlers?

### Suggested First Spec Question

When a user signs in for the first time, should existing local tasks automatically upload to their account, or should the app ask for confirmation first?

## Slice 7: AI Capture

### Purpose

Help users turn messy natural language into structured task drafts while keeping every saved change under user control.

### User-Facing Outcome

A user can describe a task in plain language, review an editable structured preview, and save it only after confirming the title, due date, tags, reminders, or recurrence fields.

### Likely Scope

- Add an AI capture input.
- Add a server-side AI parsing endpoint.
- Convert model output into a typed task draft.
- Show editable preview before save.
- Add clear fallback when AI is unavailable.
- Keep AI opt-in and bounded.

### Likely Out Of Scope

- Autonomous task modification.
- Background task planning.
- Multi-step project decomposition unless explicitly requested later.
- AI prioritization.
- Sharing-aware AI behavior.

### Likely Files And Modules

- `src/features/ai/ai-task-draft-schema.ts`: structured output schema/types.
- `src/features/ai/parse-task-description.ts`: client helper for endpoint calls.
- `src/app/api/ai/task-draft/route.ts`: AI parsing endpoint.
- `src/features/tasks/components/ai-task-capture.tsx`: capture UI.
- `src/features/tasks/components/task-editor.tsx`: preview/edit integration.
- Tests for schema validation and endpoint fallback behavior.

### Data Model Direction

Prefer no database schema change at first. AI should produce an editable draft matching existing task/reminder/recurrence draft structures.

Candidate structured draft shape:

```ts
{
  title: string;
  description: string;
  tags: string[];
  dueAt: string | null;
  dueDateOnly: boolean;
  reminderOffsetMinutes?: number | null;
  recurrencePreset?: "none" | "daily" | "weekly" | "monthly";
}
```

### Testing Focus

- schema accepts valid AI output
- schema rejects invalid or unsafe output
- endpoint returns a user-friendly error when no API key exists
- preview does not save until user confirms
- manual edits override AI suggestions

### Open Decisions

- Which OpenAI model should be used?
- Should AI capture require sign-in?
- Should AI be available before sync/auth if an API key exists on the server?
- Should AI use existing tags as context?
- What monthly budget or usage limit should be enforced?

### Suggested First Spec Question

Should AI Capture be available to local-only users through a server API key, or only after Sync/Auth introduces accounts?

## Slice 8: Sharing

### Purpose

Allow users to share lists/workspaces with other people after authentication and sync are stable.

### User-Facing Outcome

A user can create a list/workspace, invite another user, assign a simple role, and see shared tasks in the app.

### Likely Scope

- Add list/workspace model.
- Add membership model.
- Add owner/editor/viewer roles.
- Add invite flow.
- Add shared task views.
- Apply server-side authorization.

### Likely Out Of Scope

- Per-field permissions.
- Public anonymous sharing.
- Comments/chat.
- Team analytics.
- Organization billing.

### Likely Files And Modules

Exact files depend on Sync/Auth backend choices.

Likely modules:

- `src/features/lists/list-types.ts`
- `src/features/lists/list-repository.ts`
- `src/features/lists/components/list-switcher.tsx`
- `src/features/sharing/share-types.ts`
- `src/features/sharing/invite-member.ts`
- `src/features/sharing/components/share-dialog.tsx`
- backend database migrations for lists, memberships, and task ownership
- API routes or backend policies for role enforcement

### Data Model Direction

Tasks likely need:

```ts
listId: string | null;
```

New server-backed entities:

```ts
ListWorkspace {
  id: string;
  name: string;
  ownerUserId: string;
  color: string | null;
  createdAt: string;
  updatedAt: string;
}

ShareMembership {
  id: string;
  listId: string;
  userId: string;
  role: "owner" | "editor" | "viewer";
  createdAt: string;
}
```

### Testing Focus

- owner can invite members
- editor can create and update tasks
- viewer cannot mutate tasks
- revoked members lose access
- local cache does not expose stale shared data after sign-out or revocation
- list filtering does not hide personal tasks unexpectedly

### Open Decisions

- Should sharing be list-based only?
- Should invites require an existing account or allow pending email invites?
- Should shared lists sync offline for invited users?
- Should personal tasks live in a default private list?
- How should role enforcement be tested locally?

### Suggested First Spec Question

Should Sharing start with list/workspace sharing only, with no individual task sharing?

## Resume Guidance

When starting any future slice:

1. Read `docs/superpowers/README.md`.
2. Read this file.
3. Read the completed specs/plans for all earlier slices.
4. Inspect the current code because earlier implementations may have changed file names or boundaries.
5. Use `superpowers:brainstorming` to write a slice-specific design spec.
6. Use `superpowers:writing-plans` only after the user approves that spec.

Suggested resume prompt:

```text
Please resume DoUrStuff roadmap work. Start by reading docs/superpowers/README.md and docs/superpowers/future-slices.md, then inspect current code and completed earlier slice docs. Choose the next unfinished slice in roadmap order, use brainstorming to create or confirm its design spec, and only then write an implementation plan.
```

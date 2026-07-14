# Planning Views Design

## Purpose

DoUrStuff is currently a local-first task manager with task creation, editing, completion, soft deletion, due dates, tags, a task board, and a calendar. The next roadmap direction is to build the remaining work as vertical slices, where each release delivers a complete user-facing workflow with its own domain logic, UI, tests, and documentation.

The first slice is Planning Views. Its goal is to help users quickly answer what needs attention now or soon without introducing reminders, recurrence, sync, or new backend infrastructure.

## Roadmap Structure

The remaining work will be organized as vertical slices in this order:

1. Planning Views: add `All`, `Today`, `Upcoming`, `Overdue`, and `Done` views.
2. Reminder Basics: add reminder fields, reminder UI, notification permission, and in-app indicators.
3. Recurring Tasks: add repeat rules, next occurrence generation, and recurrence display/editing.
4. Natural Date Entry: parse quick date phrases such as `tomorrow 6pm` and `in 4 hours`.
5. Local Reliability: add export/import, trash/recovery, and clearer local/offline data safety affordances.
6. Sync/Auth: add sign-in, backend persistence, a mutation queue, reconciliation, and cross-device sync.
7. AI Capture: add optional AI-assisted task creation with an editable structured preview.
8. Sharing: add lists/workspaces, invites, roles, and shared task views after sync is stable.

Only the Planning Views slice is in scope for this design.

## Scope

Planning Views will replace the current `Everything`, `Open`, and `Done` filter set with:

- `All`
- `Today`
- `Upcoming`
- `Overdue`
- `Done`

The current task board and calendar remain on the same page. The task editor, floating create button, task repository, Dexie storage, and service worker setup remain functionally unchanged.

This slice uses existing task fields only:

- `status`
- `dueAt`
- `dueDateOnly`
- `completedAt`
- `deletedAt`

This slice does not include:

- reminders
- recurring tasks
- natural language date parsing
- schema changes
- backend work
- account sync
- tag filtering
- release/version bump

## Architecture

No framework change is needed. The app should keep:

- `Next.js` App Router
- React client components for the interactive task UI
- Dexie and `useLiveQuery` for local-first storage
- Tailwind CSS for styling
- Vitest and Testing Library for tests

The slice should add one small domain boundary:

```text
src/features/tasks/task-planning.ts
```

This module owns:

- planning view IDs
- planning tab labels and ordering
- per-view filtering
- per-view counts
- date bucket helpers for today, upcoming, and overdue

The hook `useTasks` remains the state coordinator. It should track the selected planning view and expose:

- `planningViews`
- `currentPlanningView`
- `visibleTasks`
- `planningViewCounts`
- `setPlanningView`

The existing `TaskFilters` component should be replaced or adapted into `TaskPlanningTabs`. `TaskBoard` should remain mostly presentational and receive the selected view, tab data, counts, and visible tasks as props. `TaskList` should continue to render task rows and actions. `TaskCalendar` should receive the same `visibleTasks` so the calendar reflects the selected planning tab.

This structure keeps date bucket rules out of UI components and creates a reusable domain layer for future reminders, recurrence, and natural date work.

## Data Rules

Planning calculations use the user's local browser time.

### All

Includes every active non-deleted task returned by the repository, including tasks with `todo`, `in_progress`, `done`, and `cancelled` statuses.

### Today

Includes open tasks due today. Open means `todo` or `in_progress`.

Date-only tasks count as today when their `dueAt` date equals today's local date. Date-time tasks count as today when their local calendar date equals today's local date.

### Upcoming

Includes open tasks due after today. Tasks with no due date are excluded.

Both date-only and date-time tasks use their local calendar date for upcoming classification.

### Overdue

Includes open tasks whose due date or due time has passed.

Date-only tasks become overdue after the end of their local due date. Date-time tasks become overdue after their exact local due time.

### Done

Includes tasks with status `done`. Cancelled tasks are excluded.

### Cancelled Tasks

Cancelled tasks do not get a separate tab in this slice. They are visible only in `All`.

## Sorting

Keep the current repository ordering: newest updated first.

This slice will not add per-view custom sorting. A later slice can revisit sorting if users need due-date-first ordering inside planning views.

## Empty States

The task list should use view-aware empty states:

- `All`: keep the existing general empty state.
- `Today`: `Nothing due today`.
- `Upcoming`: `Nothing coming up`.
- `Overdue`: `Nothing overdue`.
- `Done`: `No completed tasks yet`.

The exact supporting copy can be adjusted during implementation, but it should stay concise and user-facing.

## UI Behavior

The planning tabs replace the current filter control in the task board header. Each tab shows a count based on the same rules used for visible tasks.

Selecting a tab updates both:

- the task board list
- the calendar task data

The calendar remains visible below the task board. The task editor, create flow, edit flow, complete/reopen action, and delete action remain unchanged.

The task board helper copy can be updated to be more planning-oriented, while the calendar copy can remain mostly unchanged.

## Error Handling

This slice does not add new network or persistence behavior. Existing Dexie errors will continue to surface as they do today.

Date parsing should be defensive:

- tasks with `null` due dates are excluded from `Today`, `Upcoming`, and `Overdue`
- malformed date values should not crash the UI
- malformed dates should be treated as not matching planning date buckets

## Testing

Add unit tests for `task-planning.ts` covering:

- date-only today, upcoming, and overdue behavior
- date-time today, upcoming, and overdue behavior
- done and cancelled exclusion rules
- no-due-date exclusion from planning tabs
- counts matching visible task rules
- malformed due date handling

Update component tests if tab labels, counts, or empty states change existing expectations.

Keep the existing repository and helper tests.

Run these checks before completion:

```powershell
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

## Documentation

Update `README.md` to mention planning tabs in the current feature list.

Update `CHANGELOG.md` under `Unreleased` with a concise user-facing note.

Do not run release scripts, create tags, or bump the version unless the user explicitly approves a release action.

## Acceptance Criteria

Planning Views is complete when:

- the task board shows `All`, `Today`, `Upcoming`, `Overdue`, and `Done` tabs
- each tab shows an accurate count
- selecting a tab filters both the task list and calendar
- date-only and date-time tasks follow the agreed local-time bucket rules
- cancelled tasks appear only in `All`
- view-aware empty states are shown
- task create/edit/complete/reopen/delete behavior still works
- README and changelog are updated
- typecheck, tests, and production build pass

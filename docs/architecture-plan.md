# DoUrStuff Architecture Plan

## Purpose

This document turns the project goals into an implementation plan for a local-first task manager that works on mobile and desktop, supports reminders and recurring tasks, syncs across devices, enables sharing and backups, and leaves space for AI features later.

It also treats low maintenance cost as a core product constraint, since the project is starting as a personal app and should be cheap or free to operate for light usage.

## Product vision

Build a task manager that is:

- fast to capture tasks in
- reliable without internet
- comfortable to use on a phone
- available across signed-in devices
- safe to back up and recover
- simple to share with other people
- structured enough for reminders and analytics
- extensible enough for AI-assisted workflows
- inexpensive to run and maintain

## Product scope

### In scope for the early product

- Create, update, complete, reopen, and delete tasks
- Required title
- Optional description
- Optional tags
- Status tracking
- Due date and due datetime
- Relative deadline entry such as "in 4 hours" or "in 2 days"
- Notification preferences
- Recurring task configuration
- Offline-first storage
- Login and account support
- Multi-device sync
- Backup/export capability
- Task or list sharing
- Responsive mobile and desktop UI
- Modern, simple interface
- Free-tier-friendly operations

### Out of scope for MVP

- Multi-user collaboration
- Complex team workflows
- Heavy analytics dashboards
- Advanced AI automations that modify tasks without user review

## Recommended technical approach

### Frontend

- `Next.js` with App Router
- Progressive Web App setup
- Responsive design with mobile-first layouts
- A small internal design system for consistency

Recommendation:

- Choose `Next.js` because authentication, sync APIs, sharing, backup controls, and future AI endpoints all fit naturally into a full-stack web app.

### Backend

- `Next.js` route handlers for the first backend iteration
- `PostgreSQL` for primary cloud persistence
- `Prisma` or `Drizzle` for schema management
- Auth provider such as `NextAuth/Auth.js`, Clerk, or Supabase Auth
- Background jobs later for reminders, cleanup, backups, and analytics refreshes

Recommendation:

- Start with the smallest backend footprint that supports real sync.
- If minimizing maintenance is the top priority, Supabase is a strong option because auth, database, and storage can live in one managed free-tier platform.
- If you want more framework ownership, `Next.js + PostgreSQL + Prisma + Auth.js` is still valid, but it may require more moving pieces to maintain.

### Storage

- `IndexedDB` as the primary local cache/offline database
- `Dexie` as a lightweight wrapper for querying and migrations

Why:

- Better fit than `localStorage` for structured offline task records
- Supports larger data volume
- Easier to evolve over time

### Offline strategy

- Cache app shell assets with a service worker
- Store task and view state locally in IndexedDB
- Queue mutations while offline
- Sync queued mutations when connectivity returns

### Sync strategy

- Every task should have a stable client-generated id
- Track `createdAt`, `updatedAt`, `deletedAt`, and `lastSyncedAt`
- Store pending local mutations in a sync queue
- Reconcile local and remote changes on reconnect

Recommendation:

- Use client-generated UUIDs
- Start with a simple conflict policy such as last-write-wins at the record level
- Move to field-aware merges only if real usage proves it necessary

### Backups

- Server-side scheduled database backups
- User-facing export options later such as JSON or CSV
- Soft delete before permanent deletion when feasible

### Cost-conscious platform strategy

- Prefer a PWA over separate native apps
- Prefer one managed backend platform over multiple small services
- Keep the backend optional for single-device use
- Avoid background workers until they are clearly needed
- Keep AI features opt-in and on-demand

Recommendation:

- Lowest-maintenance path: `Next.js` frontend on a free tier plus Supabase free tier for auth and PostgreSQL.
- Lowest-complexity path if sync is deferred: ship local-first first, and add backend services only when you need cross-device sync.

### Sharing

- Share at the list or project level first
- Support roles such as owner, editor, viewer
- Avoid per-field permissions in early versions

### Notifications

- Web Notifications API for permission and display
- Service worker notifications where supported
- In-app reminder fallback when background notification support is limited

Important constraint:

Web notification behavior differs by platform, especially on mobile browsers. Treat browser notifications as best effort in the web app, and keep the architecture open for a future native wrapper if stronger reminder delivery becomes necessary.

### AI integration

- AI should not be part of the initial critical path
- Start with user-invoked assistance only
- AI output should always be converted into explicit, editable task fields before saving
- AI must remain optional because it can introduce recurring API cost

### Design system direction

- Keep the visual language modern, simple, and calm
- Use clear spacing, restrained color, and strong typography hierarchy
- Prefer a lightweight UI with obvious actions over dense productivity dashboards

Recommendation:

- Design for focus rather than decoration
- Use a compact but readable card/list system
- Make mobile capture feel especially smooth and uncluttered

## Architecture principles

### 1. Local-first

The app should work even if the network disappears. Core task operations must not depend on a backend.

### 2. Progressive enhancement

Core task management works everywhere. Notifications, AI parsing, and future sync should layer on top.

### 3. Account-aware offline support

Signed-in users should still be able to work offline, with local changes syncing later.

### 4. Schema before features

A clean task model will save time later when reminders, recurrence, stats, and AI are introduced.

### 5. Explicit user control

AI can suggest structure, but users should confirm what gets saved.

### 6. Simple modern UX

The interface should feel current and polished without becoming visually busy.

### 7. Cost-aware evolution

The architecture should scale in complexity and cost only when real usage demands it.

## Proposed domain model

### Task

Suggested initial fields:

- `id`
- `userId`
- `listId` optional
- `title` required
- `description` optional
- `tags` string array
- `status`
- `createdAt`
- `updatedAt`
- `deletedAt` optional
- `completedAt` optional
- `dueAt` optional datetime
- `dueDateOnly` boolean
- `relativeDeadlineInput` optional string
- `priority` optional
- `archived` boolean
- `version` optional

### Status

Keep this simple at first:

- `todo`
- `in_progress`
- `done`
- `cancelled`

You can add more later, but too many states early on usually slow product learning.

### Reminder settings

- `notificationsEnabled`
- `reminderOffsets` array
- `repeatReminder` boolean
- `repeatReminderInterval` optional
- `snoozeOptions` optional

Examples:

- remind 1 hour before
- remind 1 day before
- remind every 2 hours until done

### Recurrence

- `isRecurring`
- `recurrenceRule`
- `recurrenceEndAt` optional
- `nextOccurrenceAt` optional

Recommendation:

Represent recurrence as a structured rule internally, even if the first UI only supports simple repeat choices like daily, weekly, and monthly.

### User

- `id`
- `email`
- `displayName`
- `createdAt`
- `updatedAt`

### List or workspace

- `id`
- `name`
- `ownerUserId`
- `color` optional
- `createdAt`
- `updatedAt`

### Share membership

- `id`
- `listId`
- `userId`
- `role`
- `createdAt`

### Audit and analytics support

For future stats, keep enough timestamps to answer:

- how many tasks were created
- how many were completed
- completion rate over time
- overdue count
- average completion time

## Information architecture

### Primary views

- Inbox or All Tasks
- Today
- Upcoming
- Completed
- Shared
- Tags or grouped views later

### Task creation flow

The fastest flow should be:

- enter title
- optionally add due date
- save

Everything else should be expandable but not mandatory.

### Mobile-first considerations

- bottom-aligned quick add action
- large tap targets
- simple date/time input
- avoid crowded forms
- support one-handed task capture
- keep visual chrome minimal

### Design direction

- Clean surfaces with subtle elevation
- Strong whitespace and readable typography
- Limited accent color usage
- Clear empty states
- Minimal settings friction

## Offline-first behavior details

### Requirements

- App opens without active internet after first install/load
- Existing tasks remain available offline
- Create/edit/complete actions work offline
- Reminder preferences remain stored offline
- Signed-in users can continue working during temporary disconnection

### Suggested implementation

- Cache HTML, JS, CSS, icons, and essential assets
- Persist tasks and settings in IndexedDB
- Persist pending sync operations locally
- Use versioned migrations for schema changes

This helps keep the product useful even if hosted services are temporarily unavailable or later removed.

### Future-ready sync layer

- local operation log
- server reconciliation rules
- conflict policy such as "last write wins" or field-level merge

This is now part of the main architecture, but it should still start simple.

## Notifications and mobile quick-add

### What is realistic in a web-first MVP

- Ask for notification permission
- Send scheduled reminders while the app is active
- Use service worker notifications where the platform allows it
- Support installable PWA behavior

### Hard truth

"Add task from push notification" is a strong product idea, but pure web support can be limited depending on platform and browser. There are two practical paths:

1. Start with a PWA and support quick add from the app plus notifications where possible.
2. Later wrap the app with Capacitor or another native shell if you want stronger push and background capabilities on mobile.

Recommended decision:

- Build the app as a PWA first.
- Design notification and quick-capture interfaces behind an abstraction.
- Reassess native packaging once the core product proves useful.
- Do not assume paid push infrastructure in the early product.

## AI feature plan

### AI use cases worth building

- Convert natural language into a structured task
- Suggest title cleanup
- Detect dates like "tomorrow at 6pm"
- Suggest tags
- Suggest recurring schedules
- Break large tasks into subtasks later

### AI use cases to avoid early

- Auto-completing tasks without review
- Aggressive prioritization without transparency
- Background changes the user did not request

### AI system boundaries

AI should output a draft object such as:

```json
{
  "title": "Pay electricity bill",
  "description": "Use the online portal",
  "tags": ["finance", "home"],
  "dueAt": "2026-05-24T18:00:00",
  "status": "todo",
  "suggestedReminders": ["1 day before", "2 hours before"]
}
```

The UI should show this draft for confirmation before it becomes a saved task.

### AI rollout order

1. Natural language parser for task creation
2. Tag and reminder suggestions
3. Subtask suggestions
4. Planning assistance across multiple tasks

## Authentication and sync flow

### Core flow

1. User signs in.
2. App loads server-backed account data when online.
3. App hydrates and reads from local IndexedDB for fast startup and offline access.
4. Local changes are written immediately to IndexedDB and queued for sync.
5. Sync worker pushes queued mutations to the backend when online.
6. Server returns canonical updates and conflict results.

### Suggested sync units

- create task
- update task
- complete task
- delete task
- create list
- rename list
- share list

### Conflict policy for early versions

- last write wins per record
- soft-delete support
- server timestamps stored alongside client timestamps

This is not perfect, but it is a good learning tradeoff for an early product.

## Cost and maintenance strategy

### Target approach

- Free to use for solo usage
- Cheap to host for light shared usage
- No always-on paid worker requirements in the first versions

### Recommended rollout from a cost perspective

1. Build the offline-first PWA and make it fully usable locally.
2. Add managed auth and database only when you need sync across devices.
3. Add sharing after the sync model is stable.
4. Add AI only as an explicitly triggered feature.

### Cost-sensitive feature notes

- Offline/local tasks are effectively free after deployment.
- Sync adds database and auth cost pressure, so keep the schema simple and writes efficient.
- Sharing increases read/write volume and permissions complexity, so keep it list-based.
- AI is the easiest feature to make costly, so keep it optional and bounded.

### Good low-cost hosting candidates

- Vercel free tier for the web app
- Supabase free tier for auth and PostgreSQL
- Optional local export for backup safety

This combination is not guaranteed to stay free forever, but it is a sensible low-maintenance starting point for a personal project.

## Backup and recovery approach

### Early approach

- rely on regular database backups on the server
- keep soft-deleted records for a grace period
- allow local export later

### Later improvements

- user-triggered restore flows
- downloadable full account export
- version history for important lists

## Sharing model

### Recommended initial scope

- share lists, not individual reminder settings or analytics
- owner can invite editors or viewers
- editors can add and modify tasks
- viewers can read but not change tasks

This keeps permissions manageable while still covering the main collaboration use case.

## Suggested folder direction

When implementation starts, a clean structure could look like:

```text
src/
  app/
  components/
  features/
    tasks/
    reminders/
    stats/
    ai/
  db/
  lib/
  hooks/
  styles/
docs/
```

If using a plain React app, replace `app/` with route-oriented pages or screens.

## Roadmap

### Phase 0: Foundation

- Choose stack
- Set up project structure
- Add linting, formatting, and basic testing
- Configure PWA basics
- Define visual direction and design tokens
- Choose the lowest-maintenance hosting/auth/data combination

### Phase 1: Task core MVP

- Define task schema
- Build local database layer
- Create task list and task editor
- Add create, edit, complete, reopen, delete
- Support title, description, tags, status
- Add due date and due datetime
- Ensure responsive UI
- Establish modern, simple visual patterns
- Verify offline behavior

### Phase 2: Authentication and backend sync

- Add user model and authentication
- Add PostgreSQL schema
- Build task sync endpoints
- Add local mutation queue
- Sync tasks across signed-in devices
- Add backup strategy
- Keep the deployment within free-tier constraints

### Phase 3: Sharing

- Add list/workspace model
- Add membership and roles
- Build invite/share flows
- Add shared task views

### Phase 4: Reminders and recurrence

- Add reminder settings model
- Add reminder UI
- Implement recurring task creation rules
- Add overdue and upcoming logic
- Validate platform notification limitations

### Phase 5: Insights

- Add task stats and simple charts
- Show completed vs pending
- Show overdue counts
- Add basic filtering by tags and status

### Phase 6: AI-assisted capture

- Add AI task parsing endpoint or local integration boundary
- Build "describe your task" input
- Show editable structured preview
- Save only after confirmation

### Phase 7: Decide on native wrapper

- Reassess whether native packaging is needed for better mobile notifications

## Quality plan

### Functional testing priorities

- task CRUD
- offline reload behavior
- sign in and session persistence
- sync queue replay
- multi-device task consistency
- share permissions
- date and time handling
- reminder calculations
- recurring task generation
- mobile responsive layouts

### Edge cases to test

- timezone changes
- daylight savings transitions
- tasks with date-only versus datetime deadlines
- overdue reminders
- recurring tasks completed before due time
- offline updates across app refreshes
- same task edited on two devices
- revoked access to a shared list

## Open decisions

These do not block documentation, but they should be decided before coding starts:

1. Whether to use Auth.js or Supabase Auth
2. Whether to use Prisma or Drizzle
3. Whether subtasks belong in MVP or later
4. Whether status needs more than `todo`, `in_progress`, `done`, `cancelled`
5. Whether recurrence should launch with simple presets only
6. Whether mobile quick add must be browser-only, or can later rely on a native wrapper
7. Whether backend sync should ship in v1, or after the local-first MVP proves useful

## Recommended next step

Start with a `Next.js` PWA that is fully useful offline and cheap to host. Design the data model so sync can be added cleanly, but keep the first version as light as possible. Then add managed auth and sync on free tiers, then sharing, then reminders, then AI.

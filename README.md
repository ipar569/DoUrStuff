# DoUrStuff

DoUrStuff is a learning project for building a task manager that feels practical on both mobile and desktop, works offline, can sync across devices, and leaves room for AI-assisted task creation later.

The goal is not just to build another todo app. The goal is to learn how to design a reliable, offline-capable productivity product with reminders, recurring work, flexible task states, authentication, syncing, sharing, backups, and future analytics.

This is also a personal project, so low maintenance cost matters. The architecture should prefer free-tier-friendly services, local-first behavior, and optional hosted features instead of assuming paid infrastructure from the beginning.

## Product goals

- Work well on mobile and desktop from day one.
- Keep working without an internet connection.
- Support login and syncing across multiple devices.
- Support backups and task sharing.
- Support flexible task timing and lifecycle options.
- Make adding tasks quick, especially on mobile.
- Keep the interface modern, simple, and calm.
- Keep ongoing hosting and maintenance costs as close to free as possible.
- Leave clean foundations for stats, grouping, and AI features.

## Core requirements

The current product direction is based on these requirements:

1. Responsive experience for mobile and desktop.
2. Offline support with local-first behavior.
3. Task metadata such as:
   - status
   - due date or due datetime
   - relative deadlines like "end in 2 hours" or "end in 3 days"
   - notification preferences
   - recurring schedules
4. Future statistics such as completed vs not completed.
5. Easy task creation on mobile, ideally from notification-driven flows.
6. AI support for task creation and structuring.
7. Mandatory title, with optional description and tags.
8. Login/backend architecture for syncing across multiple devices.
9. Backups and task sharing features.
10. Modern and simple design.
11. Cost of maintaining the project should stay minimal, ideally within free tiers.

## Proposed product shape

At a high level, DoUrStuff should feel like:

- a fast local task manager first
- a reminder system second
- a sync-capable product with accounts
- a shareable and backup-friendly product
- an AI-enhanced assistant after the foundations are stable

That ordering still matters. Offline reliability and clean task modeling should come before advanced sync behavior, sharing rules, and AI automation.

## Suggested architecture direction

For a learning project, a web-first stack is a strong fit:

- Frontend: `Next.js` PWA
- Styling: `Tailwind CSS` with a small, intentional design system
- Local data: `IndexedDB` via `Dexie`
- Offline support: Service worker + app shell caching
- Authentication: free-tier-friendly auth
- Backend API: only when needed for sync/sharing
- Primary database: free-tier-friendly hosted `PostgreSQL` or equivalent
- Sync layer: task change tracking + conflict resolution
- Backups: scheduled database backups and optional user export
- Sharing: workspace/list/task sharing with permissions
- Notifications: Web Notifications API + service worker notifications where supported
- Background reminders: best effort in web, stronger support later if wrapped as a mobile app
- AI integration later: API-backed assistant for parsing natural language into structured tasks

Why this direction:

- One codebase can target both desktop and mobile browsers.
- PWA support helps with installability and offline use.
- IndexedDB is a good fit for structured local task storage.
- Local-first behavior reduces dependency on always-on infrastructure.
- `Next.js` gives a clean place to grow into auth, sync APIs, and AI endpoints only when needed.
- This keeps the learning path approachable while still allowing real multi-device architecture on low-cost infrastructure.

## Recommended build phases

### Phase 1: Local-first MVP

- Create, edit, complete, and delete tasks
- Required title, optional description and tags
- Basic statuses
- Due date and due datetime support
- Works fully offline
- Responsive UI for phone and desktop
- Modern, simple design foundations

### Phase 2: Accounts and sync

- Login and account model
- Backend task persistence
- Sync between devices
- Backup/export strategy
- Initial sharing model

### Phase 3: Reminder system

- Notification preferences per task
- Reminder timing rules
- Recurring task support
- Mobile-friendly quick add flow

### Phase 4: Insights and organization

- Task stats
- Filters and tag grouping
- Completed vs pending reports
- Basic history/audit views

### Phase 5: AI assistance

- Natural language task creation
- AI extraction of title, due date, tags, and reminders
- Suggest recurring schedules
- Optional task breakdown suggestions

## Design principles

- Local-first: the app should assume the network may disappear.
- Fast capture: adding a task should take a few seconds.
- Simple task model: avoid overengineering the first version.
- Modern and calm UI: clean typography, strong spacing, minimal clutter.
- Extensible schema: design fields so reminders, recurrence, and AI fit naturally later.
- Sync-safe architecture: local edits should be compatible with eventual server sync.
- Cost-aware architecture: avoid paid dependencies unless usage clearly justifies them.
- Graceful degradation: features like notifications should fail safely when a platform does not support them fully.

## What should be built first

The first implementation should focus on:

- task data model
- offline storage
- authentication model
- sync-ready identifiers and timestamps
- responsive layout
- modern visual system
- create/edit/complete flows
- date handling

That foundation will make reminders, analytics, and AI much easier to add without rewriting core pieces.

## Cost strategy

The product should be built so that:

- offline and single-device use work with no paid backend
- sync and sharing can run on generous free tiers
- backups rely on managed free-tier features plus export options
- AI stays optional and user-invoked so it does not create recurring cost pressure
- expensive always-on infrastructure is avoided in early versions

## Documentation

- Product and architecture plan: [docs/architecture-plan.md](C:/Projects/DoUrStuff/docs/architecture-plan.md)

## Initial success criteria

The first meaningful milestone is:

- installable web app
- works offline after first load
- create and edit tasks on mobile and desktop
- support login and account-backed persistence
- support title, description, tags, status, and due date fields
- preserve data locally across refreshes and offline sessions
- sync tasks across signed-in devices

## Notes

This repository is currently documentation-first. The docs are meant to guide implementation decisions and keep the learning project focused as development starts.

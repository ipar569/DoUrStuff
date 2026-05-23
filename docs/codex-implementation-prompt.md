# Codex Implementation Prompt

Use this prompt when you want Codex to execute the implementation plan for DoUrStuff.

## Prompt

Build DoUrStuff as a modern, simple, offline-capable task manager with account-based sync, while keeping ongoing maintenance cost as close to free as possible.

Product requirements:

- Must work well on mobile and desktop.
- Must support offline usage after the initial load.
- Must support account login.
- Must sync tasks across multiple signed-in devices.
- Must support future backup and recovery workflows.
- Must support future task sharing, starting at the list/workspace level.
- Must support task status, due date or due datetime, relative deadline input, notification preferences, recurring tasks, and future stats.
- Task title is required.
- Description and tags are optional.
- AI should help with task creation later, but core task management must work without AI.
- The UI should feel modern, simple, calm, and mobile-friendly.
- The architecture should prefer free-tier-friendly or zero-cost choices for light personal usage.

Technical direction:

- Use `Next.js` with App Router.
- Make it a PWA.
- Use `IndexedDB` with `Dexie` for offline/local cache.
- Prefer managed free-tier-friendly backend choices when sync is added.
- Use `PostgreSQL` for server persistence if a backend is needed.
- Use `Prisma` or `Drizzle` for schema management.
- Use `Auth.js` or Supabase Auth depending on which reduces maintenance overhead.
- Implement local-first writes with a sync queue for server reconciliation.
- Start with simple conflict handling such as last-write-wins.
- Defer non-essential hosted services until they are clearly needed.

Implementation priorities:

1. Create the project structure and core tooling.
2. Establish a modern, simple design system with responsive foundations.
3. Implement the local task domain model and offline storage.
4. Build task CRUD with required title and optional description/tags.
5. Add due date/datetime support and basic status handling.
6. Keep the first version fully useful without paid infrastructure.
7. Add authentication and backend persistence only when needed for sync.
8. Add sync across devices for signed-in users.
9. Add list/workspace support as the base for sharing.
10. Add reminder and recurrence support.
11. Leave clear extension points for stats and AI-assisted task creation.

Design expectations:

- Use intentional typography, spacing, and hierarchy.
- Keep the interface uncluttered.
- Optimize the task capture flow for mobile.
- Avoid generic dashboard-heavy UI unless it clearly helps the workflow.
- Use a restrained color system and accessible contrast.

Architecture expectations:

- Separate UI, domain logic, local storage, sync logic, and backend logic clearly.
- Use stable ids and timestamps that support offline creation and later sync.
- Keep schema and state transitions easy to extend.
- Avoid overengineering early conflict resolution and permissions.
- Prefer architecture that can run with minimal or no recurring cost at small scale.

Execution style:

- Start by scaffolding the app and the main architecture.
- Prefer the simplest low-maintenance path that still leaves room for sync later.
- Implement in small verified steps.
- After each major phase, summarize what was added and what remains.
- Prefer production-credible structure, but keep the learning project approachable.

Reference docs:

- [README.md](C:/Projects/DoUrStuff/README.md)
- [docs/architecture-plan.md](C:/Projects/DoUrStuff/docs/architecture-plan.md)

## Suggested first execution task

If starting from scratch, begin by:

1. scaffolding a `Next.js` app
2. setting up PWA support
3. setting up Tailwind and a small design token system
4. adding IndexedDB/Dexie infrastructure
5. creating the initial task schema and task list/task form UI

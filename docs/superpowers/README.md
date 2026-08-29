# Superpowers Planning Context

This directory stores the design and implementation planning context for future Codex sessions.

Start here when resuming roadmap work on DoUrStuff.

## Current State

- Repository: `C:\Projects\DoUrStuff`
- Current app: local-first task manager using Next.js, React, Tailwind CSS, Dexie, IndexedDB, Vitest, and a basic PWA/service worker setup.
- Current branch when this context was written: `main`
- Release guidance: follow `AGENTS.md`; do not create tags, run release scripts, or push without explicit user approval.
- Local verification commands on Windows PowerShell:

```powershell
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

## Roadmap Decision

The remaining work should be built as vertical slices, in this order:

1. Planning Views
2. Reminder Basics
3. Recurring Tasks
4. Natural Date Entry
5. Local Reliability
6. Sync/Auth
7. AI Capture
8. Sharing

The user initially considered a foundation-first approach, then explicitly switched back to vertical slices.

## Approved Planning Views Slice

Planning Views is the first approved slice. It should add:

- `All`
- `Today`
- `Upcoming`
- `Overdue`
- `Done`

The tabs should filter both the task board and calendar. The slice should not add reminders, recurrence, natural language date parsing, schema changes, backend work, account sync, tag filtering, version bumps, release tags, or release commands.

### Design Spec

Read this first:

```text
docs/superpowers/specs/2026-07-14-planning-views-design.md
```

Status: approved by the user.

### Implementation Plan

Then read this:

```text
docs/superpowers/plans/2026-07-14-planning-views.md
```

Status: ready to execute.

Recommended execution mode from the plan:

- `superpowers:subagent-driven-development`, if credits/context allow.
- `superpowers:executing-plans`, if executing inline in one session.

## Resume Prompt For A New Session

Use this prompt to resume with minimal context:

```text
Please resume DoUrStuff roadmap work. Start by reading docs/superpowers/README.md, then docs/superpowers/specs/2026-07-14-planning-views-design.md, then docs/superpowers/plans/2026-07-14-planning-views.md. The Planning Views design is approved and the implementation plan is ready. Do not redesign unless the local files conflict with the plan. Execute the plan task by task, keeping commits small and running npm.cmd run typecheck, npm.cmd run test:run, and npm.cmd run build before completion.
```

## Future Slice Plans

For roadmap-level plans after Planning Views, read:

```text
docs/superpowers/future-slices.md
```

Status: future slices are documented as planning handoffs. Each future slice still needs its own design spec and implementation plan before code changes.

## Future Slice Notes

Future slices still need their own design specs and implementation plans before code changes:

- Reminder Basics: reminder fields, reminder UI, notification permission, and in-app indicators.
- Recurring Tasks: repeat rules, next occurrence generation, and recurrence display/editing.
- Natural Date Entry: parse phrases such as `tomorrow 6pm` and `in 4 hours`.
- Local Reliability: export/import, trash/recovery, and clearer local/offline data safety affordances.
- Sync/Auth: sign-in, backend persistence, mutation queue, reconciliation, and cross-device sync.
- AI Capture: optional AI-assisted task creation with editable structured preview.
- Sharing: lists/workspaces, invites, roles, and shared task views after sync is stable.

## Important Architectural Decisions

- Keep Next.js App Router, React, Dexie, Tailwind, and Vitest.
- Do not switch frameworks.
- Do not add backend/auth before the task workflows are stronger.
- Do not add a global state library yet.
- Add small domain modules as features grow, beginning with `src/features/tasks/task-planning.ts`.
- Keep date bucket logic out of UI components.
- Keep task persistence unchanged for the Planning Views slice.

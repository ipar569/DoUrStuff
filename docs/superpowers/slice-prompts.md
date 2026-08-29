# Slice Session Prompts

Use these prompts to start future Codex sessions with enough context and a clear boundary. They are designed to reduce token use by pointing the new session at the durable docs instead of replaying old chat history.

## General Rules For Every Prompt

- Start by reading `docs/superpowers/README.md`.
- Read `docs/superpowers/future-slices.md`.
- Inspect current code before making plans or changes.
- Follow `AGENTS.md` release rules.
- Do not run release scripts, create tags, or push without explicit user approval.
- Use `npm.cmd` on Windows PowerShell:

```powershell
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

## Planning Views: Execute Approved Plan

Use this when Planning Views has not been implemented yet.

```text
Please resume DoUrStuff Planning Views work.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. docs/superpowers/specs/2026-07-14-planning-views-design.md
4. docs/superpowers/plans/2026-07-14-planning-views.md

The Planning Views design is approved and the implementation plan is ready. Inspect the current code to confirm it still matches the plan. If it matches, execute the implementation plan task by task. Keep commits small. Do not redesign unless the local code conflicts with the plan. Do not add reminders, recurrence, natural language parsing, schema changes, backend work, sync, tag filtering, release scripts, tags, pushes, or version bumps.

Before completion, run:
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

## Planning Views: Review Existing Implementation

Use this if Planning Views may already be implemented and you want a status check.

```text
Please review the current DoUrStuff Planning Views implementation.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/specs/2026-07-14-planning-views-design.md
3. docs/superpowers/plans/2026-07-14-planning-views.md

Then inspect the current code and compare it to the design acceptance criteria. Report what is complete, what is missing, and any risks or test gaps. Do not make code changes unless I explicitly ask.
```

## Reminder Basics: Start Design Spec

Use this after Planning Views is implemented or intentionally skipped.

```text
Please start the Reminder Basics slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans under docs/superpowers/specs and docs/superpowers/plans

Inspect the current code, especially task types, Dexie schema, task editor, task list, calendar, and any planning-view modules. Use superpowers:brainstorming to create a Reminder Basics design spec before any code changes. The slice should focus on simple local reminders: reminder fields, reminder UI, notification permission, and in-app indicators. Keep browser/PWA notifications best-effort. Do not add recurrence, sync/auth, sharing, AI, server scheduling, push infrastructure, release scripts, tags, pushes, or version bumps.

First decision to resolve: should reminders require a due date before they can be enabled, or should users be allowed to set a standalone reminder date/time?
```

## Reminder Basics: Write Implementation Plan

Use this only after the Reminder Basics design spec is approved.

```text
Please write the Reminder Basics implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Reminder Basics design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-reminder-basics.md. Make it task-by-task, TDD-oriented, and explicit about files, interfaces, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Recurring Tasks: Start Design Spec

Use this after Reminder Basics is implemented or intentionally skipped.

```text
Please start the Recurring Tasks slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially task types, Dexie schema, task repository status updates, reminder modules if present, task editor, task list, and calendar. Use superpowers:brainstorming to create a Recurring Tasks design spec before any code changes. Focus on simple local recurrence presets such as daily, weekly, monthly, and none. Do not add arbitrary RRULE editing, complex exceptions, sync/auth, sharing, AI, release scripts, tags, pushes, or version bumps.

First decision to resolve: when a recurring task is completed, should DoUrStuff create a separate completed history item and a new open task, or simply move the same task forward to the next due date?
```

## Recurring Tasks: Write Implementation Plan

Use this only after the Recurring Tasks design spec is approved.

```text
Please write the Recurring Tasks implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Recurring Tasks design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-recurring-tasks.md. Make it task-by-task, TDD-oriented, and explicit about recurrence helper interfaces, repository behavior, UI changes, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Natural Date Entry: Start Design Spec

Use this after Recurring Tasks is implemented or intentionally skipped.

```text
Please start the Natural Date Entry slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially task editor date/time inputs, task helpers, planning/date modules, reminders, and recurrence modules if present. Use superpowers:brainstorming to create a Natural Date Entry design spec before any code changes. Focus on deterministic local parsing for common phrases such as tomorrow 6pm, in 4 hours, in 2 days, and next Friday. Do not add AI parsing, broad locale parsing, voice input, sync/auth, sharing, release scripts, tags, pushes, or version bumps.

First decision to resolve: should natural date entry be a separate quick input beside the normal date/time fields, or part of a single smart task title field?
```

## Natural Date Entry: Write Implementation Plan

Use this only after the Natural Date Entry design spec is approved.

```text
Please write the Natural Date Entry implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Natural Date Entry design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-natural-date-entry.md. Make it task-by-task, TDD-oriented, and explicit about parser interfaces, accepted phrases, invalid input behavior, UI preview behavior, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Local Reliability: Start Design Spec

Use this after the task power slices are implemented or intentionally paused.

```text
Please start the Local Reliability slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially Dexie schema, task repository, soft-delete behavior, task views, and any settings/local data UI. Use superpowers:brainstorming to create a Local Reliability design spec before any code changes. Focus on JSON export/import, trash/recovery, permanent delete, and clear local data status. Do not add cloud backups, account sync, server restore, sharing, AI, release scripts, tags, pushes, or version bumps.

First decision to resolve: should import merge into existing local data, or replace the local database after a clear confirmation?
```

## Local Reliability: Write Implementation Plan

Use this only after the Local Reliability design spec is approved.

```text
Please write the Local Reliability implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Local Reliability design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-local-reliability.md. Make it task-by-task, TDD-oriented, and explicit about export/import payloads, validation, trash repository methods, UI changes, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Sync/Auth: Start Design Spec

Use this only after local workflows are valuable enough to sync.

```text
Please start the Sync/Auth slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially Dexie schema, task repository, task domain modules, backup/local reliability modules, and current deployment docs. Use superpowers:brainstorming to create a Sync/Auth design spec before any code changes. Focus on sign-in, backend persistence, local mutation queue, sync status, reconciliation, and preserving offline usefulness. Do not add sharing, AI, complex conflict UI, native mobile packaging, release scripts, tags, pushes, or version bumps.

First decision to resolve: when a user signs in for the first time, should existing local tasks automatically upload to their account, or should the app ask for confirmation first?
```

## Sync/Auth: Write Implementation Plan

Use this only after the Sync/Auth design spec is approved and the backend/auth provider has been chosen.

```text
Please write the Sync/Auth implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Sync/Auth design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-sync-auth.md. Make it task-by-task, TDD-oriented, and explicit about auth provider setup, environment variables, schema/migrations, local mutation queue interfaces, reconciliation rules, UI states, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## AI Capture: Start Design Spec

Use this after Sync/Auth is implemented or after explicitly deciding AI can run for local-only users through a server API key.

```text
Please start the AI Capture slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially task draft types, task editor, date/reminder/recurrence modules, auth/sync modules if present, and API route patterns. Use superpowers:brainstorming to create an AI Capture design spec before any code changes. Focus on user-invoked task parsing, typed structured output, editable preview, clear fallback behavior, and save only after confirmation. Do not add autonomous task changes, background planning, sharing-aware AI, release scripts, tags, pushes, or version bumps.

First decision to resolve: should AI Capture be available to local-only users through a server API key, or only after Sync/Auth introduces accounts?
```

## AI Capture: Write Implementation Plan

Use this only after the AI Capture design spec is approved.

```text
Please write the AI Capture implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved AI Capture design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-ai-capture.md. Make it task-by-task, TDD-oriented, and explicit about structured output schema, API route behavior, model/error handling, preview UI, no-save-before-confirmation behavior, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Sharing: Start Design Spec

Use this after Sync/Auth is stable.

```text
Please start the Sharing slice for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. all completed earlier slice specs and plans

Inspect the current code, especially auth, sync, task ownership, local cache behavior, and backend authorization patterns. Use superpowers:brainstorming to create a Sharing design spec before any code changes. Focus on list/workspace sharing, owner/editor/viewer roles, invite flow, and shared task views. Do not add per-field permissions, public anonymous sharing, comments/chat, billing, release scripts, tags, pushes, or version bumps.

First decision to resolve: should Sharing start with list/workspace sharing only, with no individual task sharing?
```

## Sharing: Write Implementation Plan

Use this only after the Sharing design spec is approved.

```text
Please write the Sharing implementation plan for DoUrStuff.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. the approved Sharing design spec under docs/superpowers/specs
4. completed earlier slice specs and plans

Use superpowers:writing-plans. Save the plan to docs/superpowers/plans/YYYY-MM-DD-sharing.md. Make it task-by-task, TDD-oriented, and explicit about list/workspace data model, membership roles, invite flow, authorization checks, local cache handling, UI states, tests, commits, and verification commands. Do not implement code in this session unless I explicitly approve execution after reviewing the plan.
```

## Status Check Prompt

Use this when you are unsure where the roadmap currently stands.

```text
Please check the current DoUrStuff roadmap status.

Start by reading:
1. docs/superpowers/README.md
2. docs/superpowers/future-slices.md
3. docs/superpowers/slice-prompts.md
4. all specs and plans under docs/superpowers/specs and docs/superpowers/plans

Then inspect the current code and git status. Report which roadmap slices appear complete, which have specs/plans only, which are not started, and what the recommended next session prompt should be. Do not make code changes.
```

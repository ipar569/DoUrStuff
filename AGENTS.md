# Working on DoUrStuff

DoUrStuff is a fresh Flutter Android/Windows app. The accepted design is in
`docs/proposals/2026-10-03-offline-first-architecture.md`; implementation status
is in `docs/verification/phase-2.md` (with retained Phase 1 platform gates). Earlier web application code is not a
compatibility target. Do not restore it or rewrite Git history.

## Structure and boundaries

- `lib/domain`: pure Dart values and ports; no Flutter or provider imports.
- `lib/data/local`: Drift schema, file opening, migrations and command transactions.
- `lib/app`: responsive presentation and theme. All task reads/writes use SQLite.
- `test`: real SQLite durability/invariant tests, domain and widget tests.
- `drift_schemas`: versioned schema snapshots. Generated Dart is committed.
- `docs`: accepted decisions, contracts, setup, operational and test evidence.
- `.agents/skills`: migration, sync and release workflows; read the relevant skill.

## Commands

Use Flutter pinned in `.flutter-version`; `pubspec.lock` is committed. On this
machine the optional ignored SDK is `.tools/flutter/bin`; do not require that
path on other machines. Run from the repo root:

```
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build windows --release
```

Use `dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/drift_schema_v1.json`
after a schema change. Verify the exact pinned tool help if its CLI changes.
Run relevant SQLite/domain/widget checks after changes, then the quality suite.
Native compilation is not device or notification verification. Report exact
commands/results and unverified behavior; never invent CI/device evidence.

## Data and security invariants

Never perform network calls in a local command transaction. Entity changes,
history, outbox sequence and reminder-dirty state commit together. Device clocks
are provenance, never conflict ordering. Separate databases by profile and
verify immutable profile metadata before use. Never reset a failed migration.
Do not log task content, tokens or credentials. Do not embed privileged keys.
No real account data in test fixtures. Do not silently upload guest data.

Keep provider code behind the domain ports; add abstractions only for real
boundaries. Avoid paid dependencies/services. Dark theme uses shared tokens;
controls need labels, keyboard focus and text scaling.

## Changes and releases

Keep phases usable; update the backlog and verification report. Do not represent
planned cloud sync, recurrence, reminders or workflows as working. Never hide a
failed check. Preserve unrelated changes and existing deletions. Publishing,
production migration execution and store distribution require user authorization
for that action. Ordinary local implementation/tests do not require another
approval. No production secrets in PR workflows; pin Actions to commit SHAs.

## Task completion workflow

For each completed repository-change task, use
[finish-task](.agents/skills/finish-task/SKILL.md): create a `codex/` branch,
commit only that task's changes, push it, open a PR to `main`, obtain an independent
review subagent's code review, address findings, wait for applicable checks, then
merge and verify the merge. Reuse the same branch/PR when resuming a task. Read-only
questions need no branch or empty PR.

This is the user's standing authorization for task branch pushes, PR creation,
review comments and merging completed changes to `main`; no repeated permission
request is needed. Explicit task restrictions such as local-only, no-push or
no-merge take precedence. This authorization does not include releases, store
publication or production deployment/migrations, including those triggered by
push/merge automation. Never bypass review or branch protections. If a required
check/review or merge is blocked, leave the PR open and report the exact blocker.
Preserve unrelated working-tree changes; use an isolated worktree when necessary.

## Next-session continuation prompt

When ending a work session with further steps, tasks or phases remaining, include
a ready-to-copy continuation prompt in the final response. Base it on the current
delivery plan, backlog and latest verification handoff; identify the earliest
unfinished increment and its concrete next actions. Include the repository path,
branch/PR and exact reviewed head or verified merge commit when relevant, completed
checks, pending checks or blockers, required instructions/skills and safety or
authorization boundaries needed to resume correctly. Tell the next agent to refresh
Git/GitHub state and preserve newer work before continuing. Keep the prompt concise
and self-contained, and link the detailed handoff rather than repeating its history.
Do not invent completed work or acceptance evidence, imply broader authorization,
or stop authorized work early merely to provide a prompt. If nothing remains within
the agreed scope, say so instead of inventing a next task.

---
name: finish-task
description: Finish a completed DoUrStuff repository change through a task branch, pull request, independent code review, passing checks and merge to main. Apply to code, documentation and repository configuration changes; no empty PRs for read-only tasks.
---

# Finish a repository task

Read the root `AGENTS.md`, the PR template and the task's explicit constraints.
The repository instructions record the user's standing authorization to commit,
push a task branch, create/update its PR, publish review findings and merge to
`main`. Do not ask for that authorization again. An explicit local-only, no-push,
draft-only or no-merge instruction for the task overrides this default. Release
publication, production migrations and store distribution remain separate actions.
Inspect push/merge automation before publishing; if it would deploy production,
leave that action pending separate authorization without disabling protections.

## Isolate and verify the change

- Establish the task's scope from the request and initial Git status. Preserve
  unrelated edits and deletions. A completed, usable milestone can be delivered
  while later project milestones remain open; describe that boundary accurately.
- Create a descriptive `codex/<task>` branch before committing, preferably when
  implementation starts. Reuse the branch/PR when continuing the same task;
  start a new branch from current `origin/main` for a distinct task. Fetch first.
- If the checkout contains unrelated work, use an isolated worktree and transfer
  only this task's changes. Never reset, clean, discard, blindly stash, force-push
  or commit everything merely to get a clean checkout. Review the complete staged
  diff and branch diff against `origin/main`, including untracked files.
- Run the checks required by `AGENTS.md` and the applicable migration/sync/release
  skill, proportionate to the actual change. For instruction-only changes, check
  Markdown references, skill validation and the diff; application rebuilds are
  unnecessary locally. Still wait for applicable repository CI checks on the PR.
  Update verification/backlog evidence for implementation work and record any
  unverified acceptance gates. Never describe a failed or unrun check as passed.

## Publish and review

1. Commit only the reviewed task files and push the task branch to the verified
   repository remote. Never push directly to `main`. Create a PR targeting `main`,
   or update this task's existing PR; follow `.github/PULL_REQUEST_TEMPLATE.md`.
   Explain the final behavior, validation and remaining limits. Attach the PR to
   this chat with `attach_artifact` when available.
2. Request an independent review subagent for the actual PR diff and current head
   commit, with access to relevant code/tests/instructions. It reviews only; it
   must not commit, push, merge or modify files. Ask for concrete bugs, regressions,
   security/data risks and missing essential tests, with file/line evidence.
   Do not substitute a compiler/test result for code review. If independent review
   is unavailable, leave the PR open and report the missing review mechanism.
3. Inspect GitHub reviews, inline threads and CI too. Fix actionable findings,
   rerun affected checks, commit and push the fixes, then obtain review of the
   updated diff. Do not dismiss blocking reviews or resolve threads without
   addressing their substance. Record the reviewed SHA, findings and their
   disposition in the PR. An agent review summary is not a GitHub approval by
   another account and must not be represented as satisfying such a requirement.
   For CLI multiline bodies, use a UTF-8 file and `--body-file`.

## Merge and confirm

- Refresh the PR state, head SHA, base/mergeability, checks, review decisions and
  unresolved threads. Merge only the reviewed head, with no unresolved actionable
  findings or blocking review, and all required/applicable checks successful.
  Missing, pending or cancelled checks are not success. Observe branch rules even
  when the current repository has no protection configured. If the head/base
  changes in a way that invalidates review or integration results, update the
  branch and repeat the affected verification/review before merging.
- Prefer squash merge when repository settings permit it. Use the hosting API's
  expected-head guard (for GitHub CLI, `--match-head-commit <reviewed SHA>`).
  Never use an admin override, bypass rules, change protections or force-push to
  obtain a merge. Do not claim that enabling auto-merge means the PR has merged.
- Verify GitHub reports `MERGED`, record the merge commit and confirm it is on
  remote `main`. Fast-forward a local `main` only when doing so preserves its
  checkout and pending work; a dirty primary checkout may safely stay behind.
  Preserve task worktrees until needed artifacts are retained. Do not delete
  unrelated branches or worktrees.
- Finish with the PR link, actual merge state/commit, review result and relevant
  checks. If auth, checks, review, conflicts or hosting rules block completion,
  retain the branch/PR and explain the exact next action. Never report completion
  while silently leaving the promised review or merge unfinished.

# Release workflow

This project uses Git branches, semantic versioning, and GitHub Actions to keep patches and feature releases tidy.

## Branches

- `main` is the stable deployable branch.
- `codex/<short-name>` is the default branch format for work done with Codex.
- `feature/<short-name>` is fine for human-created feature branches.
- `fix/<short-name>` is useful for focused bug fixes.

Keep each branch focused on one feature, bug fix, or release preparation task.

## Version numbers

Use semantic versioning:

- Patch: bug fixes and small corrections, for example `0.1.0` to `0.1.1`.
- Minor: new features that do not break existing behavior, for example `0.1.1` to `0.2.0`.
- Major: breaking changes, for example `0.9.0` to `1.0.0`.

## Everyday feature flow

1. Start from the latest `main`.
2. Create a branch: `git checkout -b codex/my-feature`.
3. Make the change.
4. Run checks: `npm run typecheck`, `npm run test:run`, and `npm run build`.
5. Commit the change: `git add .` then `git commit -m "Add my feature"`.
6. Push the branch and open a pull request.
7. Merge only after the GitHub Actions checks pass.

## Patch release flow

Use this when shipping bug fixes.

1. Make sure `main` is clean and up to date.
2. Update `CHANGELOG.md` with the fix under a new version heading.
3. Run `npm run release:patch`.
4. Push the commit and tag: `git push origin main --follow-tags`.

## Feature release flow

Use this when shipping new features.

1. Merge approved feature branches into `main`.
2. Update `CHANGELOG.md` with the new features under a new version heading.
3. Run `npm run release:minor`.
4. Push the commit and tag: `git push origin main --follow-tags`.

## Major release flow

Use this when shipping breaking changes.

1. Document the breaking changes and migration notes in `CHANGELOG.md`.
2. Run `npm run release:major`.
3. Push the commit and tag: `git push origin main --follow-tags`.

## GitHub release

When a `v*` tag is pushed, GitHub Actions runs the release workflow. If checks pass, it builds the deployable archive and publishes a GitHub Release with the archive attached.

Example tag created by `npm run release:patch`:

```text
v0.1.1
```


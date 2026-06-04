# DoUrStuff Agent Guidance

## Release management

When working in this repository, treat `main` as the stable deployable branch and keep release changes small, reviewable, and traceable.

### Branches

- Prefer `codex/<short-name>` for Codex-created work.
- Use `feature/<short-name>` for feature branches.
- Use `fix/<short-name>` for focused bug fixes.
- Keep each branch scoped to one feature, bug fix, or release preparation task.

### Versioning

Use semantic versioning in `package.json`:

- Patch: bug fixes and small corrections, for example `0.1.0` to `0.1.1`.
- Minor: new non-breaking features, for example `0.1.1` to `0.2.0`.
- Major: breaking changes, for example `0.9.0` to `1.0.0`.

### Release preparation

Before preparing a release:

1. Inspect repo state with `git status --short --branch`.
2. Review `CHANGELOG.md`, `package.json`, `docs/release-workflow.md`, and `.github/workflows/`.
3. Confirm the intended release type with the user if it is ambiguous.
4. Update `CHANGELOG.md` before bumping the version.
5. Run or recommend these checks:
   - `npm run typecheck`
   - `npm run test:run`
   - `npm run build`

### Release commands

Only run these after the user explicitly approves the release action:

- `npm run release:patch`
- `npm run release:minor`
- `npm run release:major`

Only push release commits or tags after the user explicitly approves publishing:

- `git push origin main --follow-tags`

### Safety rules

- Do not create Git tags without explicit user approval.
- Do not push branches, tags, or releases without explicit user approval.
- Do not overwrite local changes without explicit user approval.
- If checks fail, stop and summarize the failure before making fixes.
- Keep release notes user-facing and concise.

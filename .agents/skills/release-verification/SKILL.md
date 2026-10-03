---
name: release-verification
description: Verify DoUrStuff release candidates, signing boundaries, artifacts and installed-platform evidence before authorized publication.
---

Read docs/runbooks/releases.md and the current docs/verification report. The
present workflow produces an unsigned APK and unpackaged Windows ZIP. Do not
call them signed installers, MSIX or store releases.

Run pinned quality commands in AGENTS.md and native builds on appropriate
hosts. Run dart run tool/verify_release.dart vMAJOR.MINOR.PATCH against the
intended tag; verify lockfile, schema/protocol compatibility, changelog and
artifact hashes. Check external environments/credentials without printing their
values. Missing signing credentials must fail signing; never substitute debug.

Record installed upgrade/data retention evidence and the notification matrix
from docs/runbooks/two-device-testing.md. A compile or emulator test is not
physical closed/reboot evidence. Keep untested platforms explicit.

Prepare concrete artifacts/notes before seeking missing publication
authorization. Existing user authorization remains valid; this skill adds no
local-build approval. Publish/deploy only within authorized scope. Never expose
production/signing secrets to PR workflows or public artifacts.

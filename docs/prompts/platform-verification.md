Continue DoUrStuff by closing its current platform and CI verification gaps,
prioritizing the Phase 2 Android acceptance gate before Phase 3 implementation.
Work in the repository opened in this session; do not assume an absolute path
from a previous machine. Read root AGENTS.md, README.md, docs/backlog.md, all
relevant docs/verification reports, docs/runbooks/setup.md,
docs/runbooks/releases.md and docs/runbooks/two-device-testing.md. Apply
.agents/skills/release-verification/SKILL.md and other relevant repository skills.

The Flutter/Drift Android-and-Windows architecture is already approved. This is
a fresh native application; do not restore the previous web app. Preserve
existing work and unrelated local changes. The 9 October Phase 2 report records
55 passing tests, three preview renders and local Android/Windows builds.
Windows offline editing and normal restart persistence are user-confirmed;
Android fresh-install/offline/process-restart acceptance remains open. Windows
C++ tools were installed in the recorded follow-up. Reassess current evidence
instead of repeating a resolved toolchain blocker or assuming a build is current.
Read docs/proposals/2026-10-09-phase-3-plan.md for the next phase's entry gate.
Resume unfinished checks from the latest report without rerunning unchanged
checks unless new source changes, failures or uncertainty justify it.

Do the work, not just a plan:

1. Inspect repository status, pinned SDK/dependencies, available build tools and
   actual GitHub Actions results for the current revision. Correct real workflow
   failures with least-privilege permissions and no production secrets in PRs.
2. Run the documented quality checks and build Android and Windows on appropriate
   hosts. Distinguish a local failure, missing prerequisite and hosted build
   result. Use official documentation to verify any changed tool requirements.
   Do not silently replace working global toolchains or accept new paid services.
3. Follow the Phase 2 report's Android checklist: record model, OS, app version
   and APK hash; fresh test install/profile; disable networking before first
   launch; exercise capture/edit/status/delete/undo, tags, milestones, priorities,
   dates, search/filter/sort and the saved startup view. Stop the process after
   a successful save, reopen offline and verify retained data/defaults. Preserve
   personal data; never uninstall or clear an existing real profile to get a
   clean test. Retain Windows fresh-install/abrupt-kill checks separately from
   user-reported normal restart. Exercise native keyboard/focus, large text,
   screen readers, sleep/resume and clock/zone changes where available.
4. Assess secure-token storage and notification feasibility on both targets
   using real supported adapters in isolated probes if needed. Verify documented
   platform/package identity requirements and keep probes separate from shipped
   product claims. Full notification functionality belongs to phase 4. Record
   which closed-app/reboot/permission behaviors were actually exercised.
5. If a host/device/account is unavailable, complete independent checks and
   provide precise setup steps and the next verification action. Do not claim
   device behavior from widget tests, compilation or mocked adapters.

Update the verification reports, README platform status and backlog with exact
commands, results, environment versions and remaining gates. Preserve historical
results; date new evidence. Do not tag, push, publish a release, deploy a backend
or distribute through a store unless separately authorized. End with a concise
report of verified behavior and unresolved external prerequisites.
Leave a dated next-session handoff in the relevant verification report, with
exact remaining gate, device/build details, missing prerequisite and next action.
This prompt closes prerequisites; it does not start Phase 3 product implementation.

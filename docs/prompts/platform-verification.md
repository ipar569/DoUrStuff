Continue DoUrStuff by closing the foundation's platform and CI verification gaps.
Work in the repository opened in this session; do not assume an absolute path
from a previous machine. Read root AGENTS.md, README.md, docs/backlog.md, all
relevant docs/verification reports, docs/runbooks/setup.md,
docs/runbooks/releases.md and docs/runbooks/two-device-testing.md. Apply
.agents/skills/release-verification/SKILL.md and other relevant repository skills.

The Flutter/Drift Android-and-Windows architecture is already approved. This is
a fresh native application; do not restore the previous web app. Preserve
existing work and unrelated local changes. At the original phase-1 baseline,
17 host tests and two widget previews passed; Android debug and unsigned release
APKs compiled, but no installed device was tested and Windows C++ tools were
missing. Reassess the current checkout and environment rather than assuming
those conditions still hold.

Do the work, not just a plan:

1. Inspect repository status, pinned SDK/dependencies, available build tools and
   actual GitHub Actions results for the current revision. Correct real workflow
   failures with least-privilege permissions and no production secrets in PRs.
2. Run the documented quality checks and build Android and Windows on appropriate
   hosts. Distinguish a local failure, missing prerequisite and hosted build
   result. Use official documentation to verify any changed tool requirements.
   Do not silently replace working global toolchains or accept new paid services.
3. On available installed targets, verify fresh offline capture, completion,
   reopening, persistence across process exit/restart, narrow/wide layouts,
   keyboard focus and large text. Preserve real user data; use synthetic fixtures.
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

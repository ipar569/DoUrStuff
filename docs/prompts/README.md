# Fresh-session prompts

Open this repository in a new session. Paste one of the short launch messages
below, or paste the **entire contents** of its linked prompt. Each prompt is
self-contained and supports both starting and resuming work; the original
conversation is not required. The accepted architecture remains the source of
product requirements. Inspect current code and verification reports every time:
these prompts are instructions, not evidence that an earlier phase has passed.

| Order | Prompt | When to use it |
| --- | --- | --- |
| Next acceptance work | [Platform and CI verification](platform-verification.md) | Close the remaining Phase 2 Android offline/restart gate and retained platform checks |
| As needed | [Phase 2: complete offline application](phase-2-offline-app.md) | Resume offline-feature fixes or incomplete acceptance; preserve delivered UI refinements |
| Next product phase | [Phase 3: accounts and proven sync](phase-3-account-sync.md) | Check/close Phase 2 prerequisites, then follow milestones 3.0–3.6 |
| After phase 3 gate | [Phase 4: recurrence, calendar and reminders](phase-4-recurrence-reminders.md) | Only after real two-device sync verification |
| Final | [Phase 5: portability, hardening and releases](phase-5-hardening-releases.md) | After the preceding product phases |

Planning snapshot, 9 October 2026: Phase 2 features are implemented. Its report
records 55 passing tests, three preview renders and local Android/Windows builds;
Windows offline editing and normal restart persistence are user-confirmed.
Android fresh-install/offline/process-restart acceptance remains open. Phase 3
has a [delivery plan](../proposals/2026-10-09-phase-3-plan.md),
[architecture diagrams](../architecture/phase-3-sync.md) and a
[verification tracker](../verification/phase-3.md), but no implemented accounts
or sync. Phases 4–5 remain future work. Reassess this snapshot from current code
and dated evidence; reserved tables and planned diagrams are not integrations.

## Copy-and-paste launch messages

Close the current platform gate:

```text
Read docs/prompts/platform-verification.md and follow it as my task instructions. Resume from the current checkout and latest evidence; prioritize the remaining Phase 2 Android offline/restart acceptance gate.
```

Start or resume Phase 3:

```text
Read docs/prompts/phase-3-account-sync.md and follow it as my task instructions. Check the Phase 2 entry gate, then start or resume the earliest unfinished Phase 3 milestone in the delivery plan. Preserve existing work and update the verification handoff.
```

Start or resume Phase 4:

```text
Read docs/prompts/phase-4-recurrence-reminders.md and follow it as my task instructions. Verify the real Phase 3 acceptance gate before implementing Phase 4. Resume unfinished work and update the verification handoff.
```

Start or resume Phase 5:

```text
Read docs/prompts/phase-5-hardening-releases.md and follow it as my task instructions. Resume portability, hardening and release preparation from current code and evidence. Prepare reviewable artifacts; do not push, publish or deploy production changes.
```

Reuse the same launch message after an interruption. Each prompt requires a
durable handoff in its verification report: current milestone, completed work,
exact checks, remaining failures/prerequisites and the next executable action.
Do not run multiple implementation sessions against the same checkout at once;
use separate worktrees if concurrent work is explicitly arranged.

Each phase should leave an updated backlog and a durable verification report
with the exact next action. Missing accounts, credentials, build hosts or devices
must be recorded as prerequisites. Continue independent work while those are
missing; never substitute mock evidence for the external gate.

Running a prompt authorizes its scoped local implementation and testing, including
necessary prerequisite fixes. Editing these prompt files does not start a phase.
The prompts do not independently authorize production deployment, public release,
store publication or Git pushes.
Request those actions separately when ready. A source push does not create a
release tag or publish signed installers.

# Fresh-session prompts

Open this repository in a new session and paste the **entire contents** of the
appropriate linked file. Each prompt includes its own context and instructions;
the original conversation is not required. The accepted architecture remains
the source of product requirements. Inspect current code and verification reports
at the start of every session: these prompts are starting instructions, not a
claim that an earlier phase has passed.

| Order | Prompt | When to use it |
| --- | --- | --- |
| Independent | [Platform and CI verification](platform-verification.md) | Close foundation platform gates; can run before or alongside phase 2 |
| Next | [Phase 2: complete offline application](phase-2-offline-app.md) | Extend the foundation into everyday task management |
| Then | [Phase 3: accounts and proven sync](phase-3-account-sync.md) | After the offline application works |
| After phase 3 gate | [Phase 4: recurrence, calendar and reminders](phase-4-recurrence-reminders.md) | Only after real two-device sync verification |
| Final | [Phase 5: portability, hardening and releases](phase-5-hardening-releases.md) | After the preceding product phases |

At creation, the baseline is phase 1: capture/complete/reopen, local SQLite,
atomic change journal, schema/protocol contracts, documentation and CI definitions.
Seventeen host tests passed; Android compiled locally. Windows compilation and
installed-device acceptance remained open. See the verification reports and
GitHub Actions for newer evidence. Reserved schema tables are not completed
features. Phases 2–5 have not been implemented at this baseline.

To resume an interrupted phase, reuse its prompt and add:

> Resume from the existing implementation and latest verification report. Identify
> unfinished acceptance checks and continue those; preserve completed work and
> my unrelated changes. Do not restart the phase or assume its checklist passed.

Each phase should leave an updated backlog and a durable verification report
with the exact next action. Missing accounts, credentials, build hosts or devices
must be recorded as prerequisites. Continue independent work while those are
missing; never substitute mock evidence for the external gate.

The prompts authorize implementation and testing. They do not independently
authorize production deployment, public release, store publication or Git pushes.
Request those actions separately when ready. A source push does not create a
release tag or publish signed installers.

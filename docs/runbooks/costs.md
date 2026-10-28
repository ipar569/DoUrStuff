# Operating costs and limits

28 October local retention increment: bounded operator passes can now remove
180-day logs/detailed receipts. Compact operation hashes and deletion identities,
device watermarks, history and unresolved recovery still grow. This is not a
bounded total-storage guarantee or a measured free-tier capacity claim. Automatic
scheduling and storage/lock-duration measurements remain open; no paid dependency,
cloud project, keepalive or hosted resource was added. Provider figures below
retain their recorded review dates.

Official sources were checked on 3 October 2026; recheck before provisioning or
publishing. Phase 1 has no hosted backend or paid package.

Supabase sources were rechecked on 10 October 2026. The
[pricing page](https://supabase.com/pricing) still lists the Free quotas below
and Pro from US$25/month; it separately lists 5 GB cached egress. No paid service
was selected. Store/CI figures below retain their earlier review date.
The [pausing guide](https://supabase.com/docs/guides/platform/free-project-pausing)
describes low database activity over seven days and currently permits restoration
for up to one year after pausing. Treat that as a recovery deadline, not a backup
strategy; no keepalive traffic is planned. The
[database-size guide](https://supabase.com/docs/guides/platform/database-size)
confirms the Free 500 MB read-only threshold and also describes organization
fair-use restrictions returning HTTP 402. Future sync must retain pending work
and surface these conditions without blocking SQLite editing.

Supabase Free targets $0 recurring backend cost: 500 MB DB, 5 GB egress, 50,000
MAU, two active projects, two million realtime messages and 200 peak connections.
Projects may pause after a week inactive; oversized databases can become
read-only when disk capacity is exhausted (see the 24 October correction below).
No automatic backups. Local task use must survive those conditions.
Default SMTP is restricted (currently two messages/hour); GitHub OAuth avoids
production mail as a dependency. Pro starts at US$25/month; resources/add-ons
can add cost. Retained history, tombstones, conflicts and snapshots count too.

13 October implementation status: protocol work used only existing local tools
and tests. No cloud project, paid dependency or resource was provisioned; the
provider figures above retain their 10 October source-review date.

[Pricing](https://supabase.com/pricing),
[billing](https://supabase.com/docs/guides/platform/billing-on-supabase),
[pausing](https://supabase.com/docs/guides/platform/free-project-pausing),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp).

Personal APK builds/distribution do not need backend hosting. Play registration
costs US$25 once, with verification/testing prerequisites; recheck evolving
off-store Android verification. Windows individual Store registration is
currently free; personal MSIX can use an explicitly trusted self-signed
certificate, while public signing may cost money. Apple distribution membership
is US$99/year plus Mac build access.
[Play](https://support.google.com/googleplay/android-developer/answer/6112435),
[Android verification](https://developer.android.com/developer-verification),
[Windows](https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-individual-developer),
[Apple](https://developer.apple.com/support/compare-memberships/).

Standard public GitHub Actions runners are free. Private GitHub Free includes
2,000 minutes/month and 500 MB artifact storage, with OS-dependent charging.
Use short retention and billing controls. CI, hardware, signing, stores and
backend hosting are separate cost categories.
[Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

No paid sync service, custom hosted server or artificial keepalive service is
planned. Free cloud uptime is not guaranteed; upgrades need observed needs and
explicit agreement.

16 October: local Docker/Supabase images and synthetic integration tests now run
on the existing development machine. No hosted project or paid service was
provisioned. The tested image inventory is `supabase/images.lock.json`; local
disk/memory use is separate from cloud quotas. No pricing assumptions changed.

17 October command integration uses the same local stack and disposable synthetic
accounts. No cloud resources or paid services were added. Receipt/candidate
storage now exists locally; production retention and storage growth still need
measurement before hosting or enabling accounts.

18 October recheck of [pricing](https://supabase.com/pricing),
[pausing](https://supabase.com/docs/guides/platform/free-project-pausing) and
[database limits](https://supabase.com/docs/guides/platform/database-size): Free
still lists 500 MB database, 50,000 MAU, 5 GB egress plus 5 GB cached egress, two
active projects and no automatic backups; Pro starts at US$25/month. Low activity
over seven days can pause Free projects, with a one-year platform restore window.
The 500 MB read-only threshold and organization-level HTTP 402 restriction remain
documented. This increment provisions nothing; retained status snapshots now add
to local storage and need measurement with the full history/retention design.

24 October recheck: [pricing](https://supabase.com/pricing) retains Free 500 MB
database, 50,000 MAU, 5 GB egress plus 5 GB cached egress, two active projects and
Pro from US$25/month. [Pausing](https://supabase.com/docs/guides/platform/free-project-pausing)
still uses low database activity over seven days and a one-year restore window.
The current [database-size guide](https://supabase.com/docs/guides/platform/database-size)
corrects the earlier shorthand above: **500 MB is the database billing quota,
not the read-only trigger**. Read-only mode depends on per-project disk usage,
which also includes WAL; organization fair-use restrictions can separately
return HTTP 402 based on average database size over the billing period. Retain
pending work for both failure modes. No hosted project, paid resource or service
was added by milestone ordering; earlier dated reviews remain historical.

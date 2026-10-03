# Operating costs and limits

Official sources were checked on 3 October 2026; recheck before provisioning or
publishing. Phase 1 has no hosted backend or paid package.

Supabase Free targets $0 recurring backend cost: 500 MB DB, 5 GB egress, 50,000
MAU, two active projects, two million realtime messages and 200 peak connections.
Projects may pause after a week inactive; oversized databases can become
read-only. No automatic backups. Local task use must survive those conditions.
Default SMTP is restricted (currently two messages/hour); GitHub OAuth avoids
production mail as a dependency. Pro starts at US$25/month; resources/add-ons
can add cost. Retained history, tombstones, conflicts and snapshots count too.
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

# Builds, release artifacts and distribution

Quality CI checks generation drift, formatting, analysis, real SQLite/domain/
widget tests and the schema snapshot. Native builds use Linux for Android and
Windows for Windows. PR jobs have read-only permissions, no production secrets,
SHA-pinned Actions and seven-day artifact retention.

A vMAJOR.MINOR.PATCH tag runs quality/builds, verifies pubspec and CHANGELOG,
hashes binaries and creates a draft prerelease. Only publication has
contents:write. Configure required reviewers on the release-artifacts environment
before enabling publication. No tag/release was created locally and no hosted
workflow run has yet been verified.

| Output | Meaning |
| --- | --- |
| Android debug APK | Developer build with debug key |
| Current release APK | Unsigned review binary, not installable until signed |
| Windows ZIP | Unpackaged executable/dependencies, not installer or MSIX |
| Future signed APK | Personal release using a stable private key |
| Future signed MSIX | Installed identity with a trusted certificate |
| Future AAB | Store-upload artifact, not a direct installer |

Release Gradle configuration has no debug-signing fallback. Present workflows
read no signing or store secrets. Phase 5 will add protected signing after
installed-app/upgrade evidence exists.

Future secrets: Android keystore bytes/alias/store/key passwords; Windows PFX
and password with stable publisher/package identity. Back up keys securely;
changing them can prevent upgrades. Never commit or upload them as artifacts.
Fail signing jobs when credentials are absent. Store accounts/credentials and
publication are separate prerequisites; no placeholder store job claims success.

Windows builds need Windows+C++ tooling; Android needs SDK/JDK. Apple builds
need macOS/Xcode/signing and distribution membership. Linux requires separate
build/reminder verification. Before release, test installed upgrades, migrations,
permissions, reminders and recovery. Compile success does not prove closed-app
or reboot behavior. Publish only with explicit authorization and actual evidence.

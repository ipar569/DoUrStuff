Foundation review artifacts only.

Android APK is unsigned and cannot be installed until signed. Windows ZIP is an
unpackaged application, not a signed installer or MSIX. Neither artifact is a
store publication. Extract the whole Windows ZIP and keep its data/DLL files
together. No reminder or cloud-sync support is claimed.

See docs/verification/phase-1.md at this tag for exact checks and remaining
platform prerequisites. SHA256SUMS.txt records artifact hashes. Do not replace a
personal installation signed with a different key.

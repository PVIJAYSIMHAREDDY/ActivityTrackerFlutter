# Coaching upgrade validation — 2026-09-15

Version: 1.1.0+3. Local private-study build.

- Static analysis: no issues.
- Unit/widget suite: 31 tests passed, four opt-in emulator tests skipped.
- Additional packaged-asset test: passed (32 unit/widget tests total).
- Chrome/Firebase emulator: account isolation, coaching persistence and goal
  transitions, and signed-in navigation passed. Imperial profile/weight/diet
  conversion passed in an isolated rerun after fixing the test's tab-animation
  synchronization. No production accounts or records were used.
- Real compiled browser preview: all six books and 2,450 searchable pages loaded;
  periodization search returned 20 results; the cited Bodybuilding page opened.
  Desktop 1280×900 and phone 390×844 screenshots inspected.
- Web release, Android release APK, and Android release AAB built successfully.
- Each packaged artifact contains byte-for-byte the verified imported source asset.
- Whitespace validation: git diff --check passed.

Flutter web unit tests do not mock the asset platform channel. Asset loading was
therefore tested natively and in the actual compiled browser app. The standalone
preview is built from tools/issa_preview.dart; the full release remains lib/main.dart.

## Use

Open the full app at http://localhost:8787 while its local server is running.
The account-free source-library preview is at http://localhost:8765.
Install activity-coach-1.1.0.apk on Android, or serve the extracted web ZIP over
HTTP/HTTPS. The existing Firebase configuration handles sign-in and user records.

## Scope

All 2,451 PDF page positions are indexed; 2,450 contain extracted text. The import
checks the SHA-256 of each of the six supplied books. It does not perform OCR or
interpret diagrams. Chat combines deterministic plan guidance with clearly
labeled source excerpts, not a generative AI model. Personalized prescriptions
still use reviewed coaching rules rather than treating every textbook passage as
an instruction. No external deployment was performed. The binaries contain source
text and are private-study artifacts; public redistribution needs source rights.

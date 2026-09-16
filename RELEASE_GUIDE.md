# Private coaching build 1.1.0 (build 3)

This update adds a complete extracted-text index for all six supplied ISSA books,
a searchable reader, source-linked chat, and an improved coaching overview.
Generate `assets/coaching/issa_library.json` with `tools/import_issa.py` before
building from a clean checkout. Generated assets are excluded from Git.

This build includes supplied textbook text and is intended for private study.
Confirm redistribution rights before any public hosting or store submission.
No deployment is performed by the build commands below.

## Previous release and deployment reference

The Flutter project is the shared website and Android application. The older Flask and React Native projects have not been modified.

## Architecture

Firebase project: `activitytracker-7ba37`. Firestore database ID: `default` (without parentheses). Records are under `users/{uid}`; the deployed rules restrict access to that UID. Google and anonymous sign-in are enabled. Guest records are not recoverable on another device until linked to Google. If a Google account already exists, linking is refused rather than silently discarding guest data.

The Fitness Coach uses built-in templates and rules. PDF plans are generated on the device. There is no Flask server, paid AI API, analytics integration, or configured Facebook login in this release. Internet access is needed to sign in and synchronize. Existing SDK caching is not a guarantee of complete offline operation.

## Build and verify

Use the installed Flutter 3.41.9 / Dart 3.11.5 SDK and committed pubspec.lock:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
ANDROID_HOME=/home/boss/android-sdk flutter build appbundle --release
ANDROID_HOME=/home/boss/android-sdk flutter build apk --release
```

The opt-in integration suite uses only a demo Firebase project:

```bash
firebase emulators:start --only auth,firestore --project demo-activity-tracker
# In another terminal:
flutter test --platform chrome --dart-define=RUN_EMULATOR_TESTS=true test/emulator_test.dart
```

On this computer the test launcher is `CHROME_EXECUTABLE=/tmp/fitness-test-chrome` because the current session runs as root. Normally run Flutter and Chrome as your regular user. Integration tests register the Firebase web plugins explicitly because Flutter's widget test runner does not do so.

## Upload to your website

Upload the CONTENTS of `release/website.zip` to your HTTPS website document root. This is a static build; it does not require Python or Node on the host. Do not upload the Flutter source or signing files.

The supplied build uses `/` as its base path. For a subfolder such as `https://example.com/fitness/`, rebuild first:

```bash
flutter build web --release --no-web-resources-cdn --base-href /fitness/
```

Add your website hostname (without a URL path) to Firebase Console > Authentication > Settings > Authorized domains. Existing authorized domains are localhost, activitytracker-7ba37.firebaseapp.com and activitytracker-7ba37.web.app. A custom domain cannot be configured until its address is known.

The root build can also be published to your existing Firebase Hosting site:

```bash
firebase deploy --only hosting --project activitytracker-7ba37
```

This command publishes externally. It has not been run. It replaces the current site at https://activitytracker-7ba37.web.app. Review the destination before running it.

Serve HTML, bootstrap JS and main.dart.js with revalidation (`Cache-Control: no-cache`) to avoid clients mixing releases. Firebase hosting configuration is included. The app uses hash navigation, so plain static hosting works. Publish `privacy-policy.html` and `delete-account.html` with the app and use their actual public HTTPS URLs in Play Console.

## Play Store

Upload `release/activity-tracker-1.0.1+2.aab` to an internal testing release first. The APK is for direct device testing, not the Play Store upload.

- Package: `com.vijaysimhareddy.activitytracker`.
- Version: `1.0.1`, version code `2`; increment `pubspec.yaml` if code 2 has already been used in Play Console.
- Target SDK: Android 16 / API 36. Keep the existing upload key. Credentials are in ignored `android/key.properties`; the keystore is in ignored `keystore/release.jks`.
- Register Google Play's APP SIGNING certificate SHA-1 and SHA-256 in the Firebase Android app. The upload certificate alone does not cover Play-installed apps.
- Use the updated `store_listing.md` and existing graphics under `assets/icons`. Capture fresh screenshots after testing, because the old images may show removed labels or controls.
- Complete the Health apps declaration, content rating, audience, app access and Data safety forms based on the actual release. Declare stored fitness/health data, account identifiers, optional profile details and photos as applicable. Do not copy the old guide's incomplete data checklist.
- Provide the public privacy and account-deletion URLs. The app also offers Profile > Delete account and data.
- Complete any identity verification, device verification or closed-testing requirements shown for YOUR Play Console account. Internal testing is not a substitute for required closed testing.
- Test Google sign-in on a Play-installed build, cross-device persistence, photo selection, PDF sharing and deletion using disposable accounts before production rollout.

The developer contact email retained from the original project is buntypeddi0@gmail.com. Confirm that it is monitored for deletion and support requests. Deletion requests submitted by email require you to verify the requester and remove their records/account.

## Known limits to review

Guest-to-Google linking retains the guest UID when the Google account is new. Merging with an already-existing Google account is not implemented. Account deletion uses paginated client deletion of the app's seven known collections, followed by Firebase Auth deletion; a network failure is reported and retryable. Avoid editing the same account from another device during deletion. If adding subcollections or external storage, extend deletion accordingly. Simultaneous edits to a profile or weight history use last-write-wins; habit toggles use a transaction.

Current coaching is general fitness guidance, not a medical service, certified trainer, or live generative AI. Estimated calorie/macro targets and calendar-based programme phases require user judgment and professional advice where appropriate. Notifications and Facebook login are not shipped as working features.

## Official release references

- [Flutter web deployment](https://docs.flutter.dev/deployment/web)
- [Firebase Google sign-in](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Google Play health content](https://support.google.com/googleplay/android-developer/answer/16679511)

# Activity Tracker

A full-featured Flutter fitness and lifestyle tracking app with 7 feature tabs, Firebase backend, and an AI-powered coach.

## Features

| Tab | Description |
|-----|-------------|
| **Dashboard** | Daily overview — tasks, habits, calories, workouts, and macro progress bars |
| **Training** | Log workouts by type (Strength, Cardio, Yoga, HIIT, etc.) with duration and notes; view history |
| **Diet** | Track meals by type (Breakfast, Lunch, Dinner, Snack) with calories and macros; daily summary |
| **Habits** | Build streaks with daily habit tracking; progress bar and streak counter per habit |
| **Tasks** | Date-based task list with High/Medium/Low priority; check off and delete tasks |
| **Goals** | Track goals by category (Fitness, Personal, Finance) with progress increments |
| **Coach** | ISSA-certified AI coach chat; download personalised Workout, Nutrition, or Full Plan as PDF |

## Tech Stack

- **Flutter** (Dart) — cross-platform mobile UI
- **Firebase Auth** — Google, Facebook, and anonymous (guest) sign-in
- **Cloud Firestore** — real-time global data storage scoped to each user (`users/{uid}/...`)
- **Firebase Emulator Suite** — local Auth + Firestore emulators in debug mode
- **SharedPreferences** — auth session cache and device-local settings

## Project Structure

```
lib/
├── main.dart                  # App entry, Firebase init, emulator setup, navigation
├── theme.dart                 # Colours, text styles, input decoration
├── firebase_options.dart      # Firebase project config (auto-generated)
├── models/                    # Data models (Task, Habit, Diet, Workout, Goal, BodyStats)
├── screens/                   # One file per tab + Login, Profile, BodyStats, AI Coach chat
├── services/
│   ├── auth_service.dart      # Google / Facebook / guest sign-in, session persistence
│   ├── firestore_service.dart # All Firestore reads/writes under users/{uid}/
│   ├── coach_service.dart     # AI coach API integration
│   └── api_service.dart       # HTTP helpers
└── utils/
    └── date_utils.dart        # Date formatting helpers
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- Android Studio / Xcode
- Firebase CLI (`npm install -g firebase-tools`)
- Java 21 (required by Firebase Emulator Suite)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/PVIJAYSIMHAREDDY/ActivityTrackerFlutter.git
   cd ActivityTrackerFlutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add an Android app and download `google-services.json` → `android/app/`
   - Run `flutterfire configure` to regenerate `lib/firebase_options.dart`

4. **Run with Firebase Emulators (recommended for development)**
   ```bash
   # Terminal 1 — start emulators
   firebase emulators:start --only auth,firestore

   # Terminal 2 — forward ports to Android emulator
   adb reverse tcp:9099 tcp:9099
   adb reverse tcp:8080 tcp:8080

   # Terminal 3 — run the app
   flutter run
   ```
   In `kDebugMode` the app automatically connects to the local emulators.

5. **Run against production Firebase**
   ```bash
   flutter run --release
   ```

## Authentication

| Method | Notes |
|--------|-------|
| Google | Requires SHA-1 fingerprint registered in Firebase console |
| Facebook | Requires Facebook app ID in `AndroidManifest.xml` |
| Guest | Anonymous Firebase sign-in; full Firestore access |

## Data Storage

All user data is stored in Firestore under `users/{uid}/`:

```
users/{uid}/
├── tasks/
├── habits/
├── workouts/
├── diet/
├── goals/
├── weight_history/
└── profile/
    ├── body_stats
    └── info
```

Firestore security rules enforce that users can only read/write their own documents.

## Sample Data

Navigate to **Profile → Load Sample Data (Testing)** to seed tasks, habits, workouts, diet entries, goals, and body stats for the current day — useful for testing all features immediately after install.

## License

MIT

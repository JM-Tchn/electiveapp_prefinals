# Student Information App

Flutter app for managing student records with Firebase Authentication and
Cloud Firestore.

## Features

- Create an account or sign in with Firebase Authentication.
- Sign in with Google on Android and web.
- Use responsive bottom navigation on phones and a navigation rail on wide screens.
- View a custom blue graduation-cap and open-book app logo.
- Add, edit, and delete student records.
- Record and manage student attendance with date, status, and remarks.
- Record and manage subject grades by term.
- Search by name, student number, course, year level, or email.
- Filter records by course and year level.
- View student totals and year-level counts on the dashboard.
- Switch between light-blue and dark-blue themes in Account Settings.
- Receive floating SnackBar feedback for saves, updates, and errors.

## Run on Android

Install Flutter and the Android SDK, then from the project folder run:

```powershell
flutter pub get
flutter doctor --android-licenses
flutter devices
flutter run
```

To build a debug APK:

```powershell
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

The app loads Firebase configuration from `lib/firebase_options.dart`. In the
Firebase console, enable Email/Password under Authentication and create a
Cloud Firestore database. Student records are saved under
`users/{uid}/students/{studentId}`. Attendance and grade records are saved in
the signed-in user's `attendance` and `grades` collections and linked to an
existing student record. The included Firestore rules restrict access to the
signed-in owner and require linked students to exist. Deploy the rules with:

```powershell
firebase deploy --only firestore:rules --project flutter-firebase-app-f184b
```

For Android Google sign-in, register the Android app's SHA-1 fingerprint in
Firebase Project Settings and download the refreshed `google-services.json`.
It must include the project's web OAuth client for Google Sign-In.

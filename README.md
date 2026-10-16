# Tiermetry

Tiermetry is a Flutter app for discovering activities/arenas and booking experiences.

## Prereqs

- Flutter SDK (Dart 3.x)
- Xcode (for iOS builds) or Android Studio (for Android builds)

## Run

```bash
flutter pub get
flutter run
```

## Build and launch the current Android app

From PowerShell, use the checked-in helper so you always build from the current
workspace before launching or creating an APK:

```powershell
.\tool\android-app.ps1 run       # build/install and launch on a connected device
.\tool\android-app.ps1 apk       # create build\app\outputs\flutter-apk\app-release.apk
```

The APK command builds a release APK. Use `flutter run` (or the helper's `run`
command) for a debug build on a connected device.

## Project Structure

- `lib/core/`: app-wide infrastructure (theme, widgets, service locator, services)
- `lib/features/`: vertical features (arena, home, profile, etc.)
- `assets/`: images and SVGs

The app currently uses a mock API implementation: `MockApiService` in `lib/core/services/`.

## CI

GitHub Actions runs Flutter formatting checks, `flutter analyze`, and `flutter test` on pull requests.

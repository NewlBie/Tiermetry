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

## Project Structure

- `lib/core/`: app-wide infrastructure (theme, widgets, service locator, services)
- `lib/features/`: vertical features (arena, home, profile, etc.)
- `assets/`: images and SVGs

The app currently uses a mock API implementation: `MockApiService` in `lib/core/services/`.

## CI

GitHub Actions runs Flutter formatting checks, `flutter analyze`, and `flutter test` on pull requests.

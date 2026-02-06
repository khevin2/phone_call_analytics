# CallSense

CallSense is an **Android-only Flutter app** that reads your local call log and produces offline analytics dashboards, including dual-SIM separation when available. It is designed to be privacy-forward: **no internet permission**, no analytics SDKs, and all processing stays on-device.

## Table of contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Tech stack](#tech-stack)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Running the app](#running-the-app)
- [Testing](#testing)
- [Project structure](#project-structure)
- [Permissions](#permissions)
- [Privacy](#privacy)
- [Known limitations](#known-limitations)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## Features

- **Offline-only**: no internet permission, no analytics SDKs, and no remote logging.
- **Call log ingestion**: pulls metadata from `CallLog.Calls` and stores locally.
- **Dual-SIM support**: best-effort SIM1/SIM2 mapping using subscription data.
- **Analytics dashboards**: overview, trends, time insights, and top numbers.
- **Exports**: CSV and JSON export via system share sheet.
- **Background sync**: daily sync via WorkManager.
- **Demo mode**: seed fake data for emulator testing.

## Screenshots

Screenshots are welcome! If you add or update UI, please include them in your PR.

## Tech stack

- **Flutter** (Dart)
- **Android** platform APIs (`CallLog.Calls`, WorkManager)
- **Local storage** (on-device only)

## Requirements

- Flutter SDK (stable)
- Android SDK / Android Studio or command-line tools
- An Android device or emulator

## Getting started

```bash
flutter pub get
```

## Running the app

```bash
flutter run
```

## Testing

```bash
flutter test
```

## Linting and formatting

```bash
dart format .
flutter analyze
```

## Building an APK

```bash
flutter build apk
```

## Project structure

```text
lib/          # App source
android/      # Android platform integration
test/         # Tests
```

## Permissions

CallSense requests only the following Android permissions:

- `READ_CALL_LOG` (required)
- `READ_PHONE_STATE` (required for SIM mapping)
- `READ_CONTACTS` (optional, only if user enables name resolution)

If permissions are denied, the app enters limited mode and continues to function without crashing.

## Privacy

The Android manifest **does not include** the `INTERNET` permission. All analytics are computed locally and exports stay on-device via share/save.

## Known limitations

- SIM mapping depends on device/OS exposure of phone account data. If mapping fails, calls are labeled **Unknown SIM**.
- Some manufacturers do not populate `PHONE_ACCOUNT_ID` fields consistently.
- Emulators often have no call logs; use demo mode to seed data.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code style, and PR guidance.

## Security

See [SECURITY.md](SECURITY.md) for reporting guidelines.

## Support

See [SUPPORT.md](SUPPORT.md) for help and troubleshooting guidance.

## License

This project is licensed under the [MIT License](LICENSE).

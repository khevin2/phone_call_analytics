# CallSense

CallSense is an Android-only Flutter app that reads your local call log and produces offline analytics dashboards, including dual-SIM separation when available.

## Features

- **Offline-only**: no internet permission, no analytics SDKs, and no remote logging.
- **Call log ingestion**: pulls metadata from `CallLog.Calls` and stores locally.
- **Dual-SIM support**: best-effort SIM1/SIM2 mapping using subscription data.
- **Analytics dashboards**: overview, trends, time insights, and top numbers.
- **Exports**: CSV and JSON export via system share sheet.
- **Background sync**: daily sync via WorkManager.
- **Demo mode**: seed fake data for emulator testing.

## Run the app

```bash
flutter pub get
flutter run
```

## Permissions

CallSense requests only the following Android permissions:

- `READ_CALL_LOG` (required)
- `READ_PHONE_STATE` (required for SIM mapping)
- `READ_CONTACTS` (optional, only if user enables name resolution)

If permissions are denied, the app enters limited mode and continues to function without crashing.

## Known limitations

- SIM mapping depends on device/OS exposure of phone account data. If mapping fails, calls are labeled **Unknown SIM**.
- Some manufacturers do not populate `PHONE_ACCOUNT_ID` fields consistently.
- Emulators often have no call logs; use demo mode to seed data.

## Offline-only confirmation

The Android manifest **does not include** the `INTERNET` permission. All analytics are computed locally and exports stay on-device via share/save.

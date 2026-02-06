# Contributing to CallSense

Thanks for your interest in contributing! This guide covers how to set up the project, propose changes, and submit a pull request.

## Development setup

1. Install the Flutter SDK (stable) and Android SDK tools.
2. Fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app on a device or emulator:

   ```bash
   flutter run
   ```

## Code style

- Follow standard Dart/Flutter formatting (`dart format`).
- Address lints reported by `flutter analyze`.
- Prefer small, focused commits and PRs.
- Keep changes scoped to a single concern when possible.

## Testing

Run the test suite before submitting:

```bash
flutter test
```

If you change formatting or linting rules, run:

```bash
dart format .
flutter analyze
```

If you can’t run tests locally, explain why in the PR.

## Pull requests

- Fill out the PR template.
- Include screenshots for UI changes.
- Describe any breaking changes or migration steps.
- Link relevant issues in the PR description (e.g., `Closes #123`).

## Reporting issues

Please use the issue templates for bug reports and feature requests.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

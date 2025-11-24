# Tests added by ChatGPT

Files added:
- card_tile_test.dart
- deck_panel_test.dart
- login_validation_test.dart
- models_test.dart

How to run:
From the `deck_builder` project root (where pubspec.yaml resides):
```bash
flutter test
```

Notes:
- I focused tests on components that do not perform HTTP calls at initState.
- The app's APIRunner is instantiated inside many State objects and performs network calls during initState; to avoid flaky network-dependent tests I targeted reusable view components and model parsing logic.
- If you want me to convert the widgets to accept injected API instances (for better integration testing), I can prepare small refactors and matching tests.


# Lazy macOS App Agent Guide

## Build & Test Commands

- `flutter run -d macos` - Run macOS app
- `flutter test test/widget_test.dart` - Run widget tests
- `flutter test test/widget_test.dart -n "test_name"` - Run specific widget test
- `cd macos && xcodebuild test -workspace Runner.xcworkspace -scheme Runner` - Run macOS tests
- `flutter analyze` - Run static analysis
- `flutter pub run build_runner build` - Run code generation
- `flutter pub upgrade` - Update dependencies

## Architecture

### Core Components

- **Models**:

  - `Command`: Represents user commands with title, content, and metadata
  - `CapturedContent`: Stores captured content with type and timestamp

- **Services**:

  - `ContentService`: Manages content capture and processing
  - `DatabaseHelper`: SQLite database operations using sqflite
  - `GeminiService`: AI integration with Google Generative AI API

- **Views**:

  - `CommandCenterView`: Main command interface
  - `HistoryView`: Past command history
  - `SettingsView`: Application preferences

- **macOS Integration**:
  - `AppDelegate`: Main app lifecycle handler
  - `MainFlutterWindow`: Native window management
  - Tray icon and hotkey management

### Key Dependencies

- UI: macos_ui, window_manager, tray_manager
- Data: sqflite, flutter_secure_storage
- AI: google_generative_ai
- Utilities: http, path, url_launcher

## Code Style

### General

- Follow Dart/Flutter conventions strictly
- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for types and classes
- Prefer `final` for immutable variables
- Strong null safety enforcement

### Organization

- Group imports in order:
  1. Dart/Flutter SDK imports
  2. External package imports
  3. Relative project imports
- Keep classes under 300 lines
- Split large widgets into smaller components

### Error Handling

- Use `try/catch` blocks for async operations
- Log errors with stack traces
- Provide user-friendly error messages

### Linting

- Follow Flutter recommended lints from flutter_lints, configured in `analysis_options.yaml`
- Avoid print statements in production code
- Format code with `dart format`
- Fix all analyzer warnings before committing

### Testing

- Widget tests for UI components
- Unit tests for business logic
- Mock dependencies in tests
- Test edge cases and error conditions

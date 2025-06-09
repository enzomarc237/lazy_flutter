# Development Plan: Lazy macOS App (Flutter)

**Project Goal:** Create a macOS application similar to Lazy.so using Flutter, `macos_ui`, and `leanflutter` packages. The app will feature a single, resizable window acting as a command center (triggered by `Cmd+L`) and an expanded view for content management. MVP includes text/URL capture, basic organization, and Gemini-powered summarization.

---

**Phase 1: Project Setup & Core Window/UI Management**

*   **Task 1.1: Initialize Project & Dependencies**
    *   Subtask 1.1.1: Flutter project `lazy_macos_app` created.
    *   Subtask 1.1.2: Add core packages to `pubspec.yaml`: `macos_ui`, `window_manager`, `tray_manager`, `hotkey_manager`, `sqflite`, `flutter_secure_storage`, `http`, `google_generative_ai`.
    *   Subtask 1.1.3: Run `flutter pub get` to install/update dependencies.
    *   Subtask 1.1.4: Commit `pubspec.yaml` and `pubspec.lock` changes.
*   **Task 1.2: Basic Window Configuration (`window_manager`)**
    *   Subtask 1.2.1: In `main.dart` (or a dedicated window setup service), initialize `window_manager`.
    *   Subtask 1.2.2: Configure the initial window to be frameless or use a custom title bar style (e.g., `TitleBarStyle.hidden`) to match the command center aesthetic.
    *   Subtask 1.2.3: Set an initial small size for the command center mode (e.g., 600w x 70h, adjust based on design).
    *   Subtask 1.2.4: Configure the window to be non-resizable when in command center mode.
    *   Subtask 1.2.5: Ensure the window can be centered or positioned appropriately (e.g., top-center of the screen).
    *   Subtask 1.2.6: Implement basic window lifecycle management: `show()`, `hide()`, `focus()`, `close()`, `isPreventClose(true)` (to allow hiding to tray instead of quitting).
*   **Task 1.3: Command Center UI Shell (`macos_ui`)**
    *   Subtask 1.3.1: Create a new Flutter widget: `CommandCenterView.dart`.
    *   Subtask 1.3.2: Use `MacosWindow` and `MacosScaffold` from `macos_ui` as the base for the app's root widget.
    *   Subtask 1.3.3: Inside `CommandCenterView`, implement a `MacosTextField` for input, styled like a search bar as per design images.
    *   Subtask 1.3.4: Add placeholder buttons or icons for quick actions if shown in the compact design (defer actual functionality).
    *   Subtask 1.3.5: Ensure the `CommandCenterView` is the initial view presented when the window is shown in its compact state.
*   **Task 1.4: Global Hotkey (`hotkey_manager`)**
    *   Subtask 1.4.1: In `main.dart` (or an app lifecycle manager), initialize `hotkey_manager`.
    *   Subtask 1.4.2: Register the global hotkey `Cmd+L`.
    *   Subtask 1.4.3: Define the hotkey callback function:
        *   Check if the window is currently visible and focused using `window_manager.isVisible()` and `window_manager.isFocused()`.
        *   If visible and focused (and in command center mode), potentially hide it.
        *   If not visible, or not focused:
            *   Use `window_manager` to set the window to "command center" dimensions/position.
            *   Call `window_manager.show()`.
            *   Call `window_manager.focus()`.
            *   Programmatically focus the input `MacosTextField` in `CommandCenterView`.
*   **Task 1.5: System Tray (`tray_manager`)**
    *   Subtask 1.5.1: In `main.dart` (or app lifecycle manager), initialize `tray_manager`.
    *   Subtask 1.5.2: Set a tray icon (requires an icon asset, create a placeholder if none available yet).
    *   Subtask 1.5.3: Create a tray menu with items:
        *   "Show/Hide Command Center" (toggles window visibility using `window_manager.isVisible()` and then `show()` or `hide()`).
        *   "Quit" (properly disposes of resources and calls `window_manager.destroy()` or `exit(0)`).
    *   Subtask 1.5.4: Implement `TrayListener` methods for `onTrayIconMouseDown`, `onTrayIconRightMouseDown`, `onTrayMenuItemClick`.

---

**Phase 2: Content Capture & Command Center Interaction**

*   **Task 2.1: Clipboard Integration for Capture**
    *   Subtask 2.1.1: When `CommandCenterView` becomes active (e.g., after hotkey press and window focus), automatically read text from the system clipboard using `Clipboard.getData(Clipboard.kTextPlain)`.
    *   Subtask 2.1.2: If clipboard content is retrieved, pre-fill the `MacosTextField` in `CommandCenterView`.
    *   Subtask 2.1.3: Add logic to identify if the clipboard content is a URL (e.g., using `Uri.tryParse` and checking `hasScheme`).
*   **Task 2.2: Saving Captures from Command Center**
    *   Subtask 2.2.1: Add a "Save" mechanism in `CommandCenterView` (e.g., pressing Enter in the `MacosTextField` or a dedicated save button).
    *   Subtask 2.2.2: On save, get the current text from the `MacosTextField`. Determine content type (text/URL).
    *   Subtask 2.2.3: Call data persistence logic (from Phase 3) to save the capture item.
    *   Subtask 2.2.4: After saving, clear the input field.
    *   Subtask 2.2.5: Hide the command center window using `window_manager.hide()`.
    *   Subtask 2.2.6: Provide user feedback (e.g., a brief `BotToast` notification or similar, if `BotToast` or another notification package is added).

---

**Phase 3: Data Storage & Expanded Content View**

*   **Task 3.1: Local Database Setup (`sqflite`)**
    *   Subtask 3.1.1: Define the database schema in a Dart model class (e.g., `CaptureItem.dart`):
        *   Table: `captures`
        *   Columns: `id` (INTEGER PRIMARY KEY AUTOINCREMENT), `type` (TEXT: 'text' or 'url'), `content` (TEXT), `summary` (TEXT NULL), `source_application_name` (TEXT NULL, for future enhancement), `created_at` (TEXT, ISO8601 format).
    *   Subtask 3.1.2: Create a `DatabaseHelper.dart` class to manage database initialization (`openDatabase`), connection, and CRUD operations.
    *   Subtask 3.1.3: Initialize the database when the app starts (e.g., in `main.dart`).
*   **Task 3.2: Data Persistence Logic**
    *   Subtask 3.2.1: Implement `Future<int> insertCapture(CaptureItem capture)` in `DatabaseHelper`.
    *   Subtask 3.2.2: Implement `Future<List<CaptureItem>> getAllCaptures()` (ordered by `created_at` descending) in `DatabaseHelper`.
    *   Subtask 3.2.3: Implement `Future<int> updateCaptureSummary(int id, String summary)` in `DatabaseHelper`.
    *   Subtask 3.2.4: Implement `Future<int> deleteCapture(int id)` in `DatabaseHelper` (for later use).
*   **Task 3.3: Expanded UI State & Navigation**
    *   Subtask 3.3.1: Create a new Flutter widget: `ExpandedContentView.dart`.
    *   Subtask 3.3.2: Use `macos_ui` components for layout (e.g., `ResizablePane` for list/detail, `MacosListView` for displaying captures).
    *   Subtask 3.3.3: Implement state management (e.g., using `Provider` or `Riverpod`) to control the current view (Command Center vs. Expanded Content).
    *   Subtask 3.3.4: Implement logic to switch the window and UI:
        *   Trigger for expansion: e.g., a button in command center, a tray menu option, or typing a specific command (e.g., "/expand").
        *   When expanding: Use `window_manager` to resize the window to a larger, appropriate size (e.g., 800w x 600h) and make it resizable. Update the app state to show `ExpandedContentView`.
        *   When collapsing: Resize back to command center dimensions, make non-resizable. Update app state.
    *   Subtask 3.3.5: In `ExpandedContentView`, display the list of captures fetched from the database.
    *   Subtask 3.3.6: When a capture is selected from the list, display its full `content` and `summary` (if available) in a detail area within `ExpandedContentView`.

---

**Phase 4: AI-Powered Summarization (Gemini)**

*   **Task 4.1: Gemini API Integration (`google_generative_ai`)**
    *   Subtask 4.1.1: Add `google_generative_ai` package to `pubspec.yaml` and run `flutter pub get`.
    *   Subtask 4.1.2: Create a service class `GeminiService.dart`.
    *   Subtask 4.1.3: Implement a method in `GeminiService` to take text input and return a summary using the Gemini API (e.g., `GenerativeModel(model: 'gemini-pro', apiKey: apiKey)` and `generateContent`).
*   **Task 4.2: Secure API Key Management (`flutter_secure_storage`)**
    *   Subtask 4.2.1: Create a simple settings section within `ExpandedContentView` (or a dedicated settings page later) for the user to input their Gemini API Key.
    *   Subtask 4.2.2: Use `flutter_secure_storage` to save (`write()`) and retrieve (`read()`) the API key.
    *   Subtask 4.2.3: `GeminiService` should retrieve the API key before making calls. Handle cases where the API key is not set (prompt user).
*   **Task 4.3: Summarization Feature Implementation**
    *   Subtask 4.3.1: In the detail view of a text capture within `ExpandedContentView`, add a "Generate Summary" `PushButton` from `macos_ui`.
    *   Subtask 4.3.2: On button press, retrieve the API key. If available, call the `GeminiService` to summarize the capture's `content`.
    *   Subtask 4.3.3: Show a loading indicator while waiting for the API response.
    *   Subtask 4.3.4: Process the API response to extract the summary.
    *   Subtask 4.3.5: Update the capture in the database with the new summary using `DatabaseHelper.updateCaptureSummary()`.
    *   Subtask 4.3.6: Refresh the UI to display the summary.
*   **Task 4.4: Error Handling for AI Service**
    *   Subtask 4.4.1: Implement error handling in `GeminiService` for API requests (network errors, invalid key, API limits, content moderation issues, etc.).
    *   Subtask 4.4.2: Display appropriate error messages to the user (e.g., using `MacosAlertDialog`).

---

**Phase 5: Refinements, Packaging & Documentation**

*   **Task 5.1: UI/UX Polish**
    *   Subtask 5.1.1: Review all UI elements against design images and ensure consistency with `macos_ui` guidelines.
    *   Subtask 5.1.2: Test window transitions, resizing, focus management thoroughly.
    *   Subtask 5.1.3: Add appropriate loading indicators and feedback for all asynchronous operations.
    *   Subtask 5.1.4: Ensure smooth animations and transitions if any are implemented.
*   **Task 5.2: Error Handling & Stability**
    *   Subtask 5.2.1: Implement comprehensive error handling for database operations, file I/O (if any), and other critical paths.
    *   Subtask 5.2.2: Test edge cases for capture (empty clipboard, very large text), AI interaction, and window management.
*   **Task 5.3: macOS Application Packaging**
    *   Subtask 5.3.1: Configure `macos/Runner/Info.plist` (bundle ID, version, app name, copyright).
    *   Subtask 5.3.2: Create a proper application icon and add it to `macos/Runner/Assets.xcassets/AppIcon.appiconset/`.
    *   Subtask 5.3.3: Build a release version of the macOS app (`flutter build macos --release`).
    *   Subtask 5.3.4: Test the packaged `.app` bundle.
*   **Task 5.4: Documentation**
    *   Subtask 5.4.1: This `DEVELOPMENT_PLAN.md` serves as initial planning documentation.
    *   Subtask 5.4.2: Add comments to complex code sections.
    *   Subtask 5.4.3: Create a `README.md` for the project with build and run instructions.

---

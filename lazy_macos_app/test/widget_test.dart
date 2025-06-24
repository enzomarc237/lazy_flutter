// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import FFI for testing

import 'package:lazy_macos_app/main.dart';
import 'package:lazy_macos_app/services/service_locator.dart';
import 'package:lazy_macos_app/views/command_center_view.dart'; // Import CommandCenterView

void main() {
  // Initialize FFI for sqflite databases
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setupServiceLocator(); // Ensure services are registered before tests run

  testWidgets('MyApp builds smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that MyApp builds and shows the CommandCenterView initially (or some root widget).
      // Instead of looking for specific text from a counter app,
      // we can look for a common widget type or a key if available.
      // For now, just ensuring it builds without crashing is a basic step.
      expect(find.byType(MyApp), findsOneWidget);
      // Depending on initial view, you might check for CommandCenterView or MacosWindow
      expect(find.byType(CommandCenterView), findsOneWidget);

      // Pump any pending timers to ensure they are flushed.
      await tester.pumpAndSettle();
    });
  });
}

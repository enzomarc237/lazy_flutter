import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for PhysicalKeyboardKey, Clipboard, and keyboard events
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io'; // Required for Platform.isMacOS
import 'dart:async'; // For debounce timer

// Import our models and services
import 'views/settings_view.dart';
import 'views/history_view.dart';
import 'views/command_center_view.dart';
// REMOVED: No longer needed here
// import 'models/captured_content.dart';
// import 'services/content_service.dart';

const String appTitle = 'Lazy macOS App';

// Define the hotkey
final HotKey _hotKey = HotKey(
  key: PhysicalKeyboardKey.keyL,
  modifiers: [HotKeyModifier.meta],
  scope: HotKeyScope.system,
);

/// Configure macOS window utils for modern transparent effect
Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll(); // Unregister all previous hotkeys
  await setupHotkeys();
  await setupTray();

  await _configureMacosWindowUtils();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(600, 450), // Default to command center size
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true, // Hide from taskbar, rely on tray and hotkey
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(false);
    if (Platform.isMacOS) {
      await windowManager.show();
      await windowManager.focus();
    }
  });

  runApp(const MyApp());
}

// Global key is no longer a viable way to communicate with the view's state
// after file separation. This needs a better state management solution.
// final GlobalKey<_CommandCenterViewState> commandCenterKey =
//     GlobalKey<_CommandCenterViewState>();

Future<void> setupHotkeys() async {
  await hotKeyManager.register(
    _hotKey,
    keyDownHandler: (hotKey) async {
      bool isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.focus();
      } else {
        await windowManager.show();
        await windowManager.focus();
        // FIXME: Refreshing clipboard on show is temporarily disabled post-refactor.
        // commandCenterKey.currentState?._checkClipboard();
      }
    },
  );
}

Future<void> setupTray() async {
  String iconPath = 'assets/tray_icon_template.png';

  try {
    await trayManager.setIcon(iconPath, isTemplate: true);
  } catch (e) {
    print("Error setting tray icon: $e.");
  }

  Menu menu = Menu(
    items: [
      MenuItem(key: 'show_hide_window', label: 'Show/Hide Command Center'),
      MenuItem(key: 'show_history', label: 'Show Capture History'),
      MenuItem(key: 'show_settings', label: 'Settings'),
      MenuItem.separator(),
      MenuItem(key: 'quit_app', label: 'Quit Lazy App'),
    ],
  );

  await trayManager.setContextMenu(menu);
  await trayManager.setToolTip("Lazy macOS App");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Enum for app views
enum AppView { commandCenter, history, settings }

class _MyAppState extends State<MyApp> with TrayListener {
  // Current view
  AppView _currentView = AppView.commandCenter;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    // It's good practice to unregister hotkeys if the app is truly closing,
    // though for a tray app, it might stay registered until quit from tray.
    // hotKeyManager.unregister(_hotKey);
    super.dispose();
  }

  // Switch between views
  void _switchToView(AppView view) {
    setState(() {
      _currentView = view;
    });

    // Adjust window size and properties based on view
    if (view == AppView.commandCenter) {
      windowManager.setResizable(false);
      windowManager.setSize(const Size(600, 450));
      windowManager.center();
    } else if (view == AppView.history) {
      windowManager.setResizable(true);
      windowManager.setSize(const Size(1200, 700));
      windowManager.center();
    } else if (view == AppView.settings) {
      windowManager.setResizable(true);
      windowManager.setSize(const Size(600, 400));
      windowManager.center();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: appTitle,
      color: MacosColors.transparent,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: () {
        switch (_currentView) {
          case AppView.commandCenter:
            return CommandCenterView(
              onShowHistory: () => _switchToView(AppView.history),
              onShowSettings: () => _switchToView(AppView.settings),
            );
          case AppView.history:
            return HistoryView(
              onShowCommandCenter: () => _switchToView(AppView.commandCenter),
            );
          case AppView.settings:
            return SettingsView(
              onShowCommandCenter: () => _switchToView(AppView.commandCenter),
            );
        }
      }(),
    );
  }

  @override
  void onTrayIconMouseDown() {
    // Show/Hide window or pop up context menu
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_hide_window':
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          _switchToView(AppView.commandCenter);
          await windowManager.show();
          await windowManager.focus();
          // FIXME: Refreshing clipboard on show is temporarily disabled post-refactor.
          // commandCenterKey.currentState?._checkClipboard();
        }
        break;
      case 'show_history':
        _switchToView(AppView.history);
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'show_settings':
        _switchToView(AppView.settings);
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'quit_app':
        await windowManager.destroy();
        await hotKeyManager.unregisterAll();
        exit(0);
    }
  }
}

// ALL OF CommandCenterView and its state have been moved to views/command_center_view.dart

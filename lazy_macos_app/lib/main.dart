import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for PhysicalKeyboardKey, Clipboard, and keyboard events
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:local_notifier/local_notifier.dart'; // Added for local notifications
import 'dart:io'; // Required for Platform.isMacOS
import 'dart:async'; // For debounce timer

// Import our models and services
import 'views/settings_view.dart';
import 'views/history_view.dart';
import 'views/command_center_view.dart';
import 'core/constants.dart';
import 'core/app_views.dart';
import 'views/notification_center_view.dart';
import 'services/navigation_service.dart';
import 'services/clipboard_service.dart';
import 'services/service_locator.dart';
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
  setupServiceLocator();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll(); // Unregister all previous hotkeys
  await localNotifier.setup( // Initialize local_notifier
    appName: appTitle,
  );
  await setupHotkeys();
  await setupTray();

  await _configureMacosWindowUtils();

  WindowOptions windowOptions = const WindowOptions(
    size: kCommandCenterSize,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true, // Hide from taskbar, rely on tray and hotkey
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setVisibleOnAllWorkspaces(true);
    await windowManager.setHasShadow(true);

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
      await showHide();
    },
  );
}

Future showHide() async {
  bool isVisible = await windowManager.isVisible();
  bool isFocused = await windowManager.isFocused();

  if (isVisible) {
    if (isFocused) {
      await windowManager.hide();
    } else {
      await windowManager.focus();
    }
  } else {
    await windowManager.show();
    await windowManager.focus();
    // Trigger clipboard check when the window is shown
    getIt<ClipboardService>().checkClipboard();
  }
}

Future<void> setupTray() async {
  String iconPath = 'assets/tray_icon_template.png';

  try {
    await trayManager.setIcon(iconPath);
  } catch (e) {
    // Consider logging this error to a file or a proper logging service in a real app
    // For now, removing the print statement as per lint rules.
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

class _MyAppState extends State<MyApp> with TrayListener, WindowListener {
  final NavigationService _navigationService = getIt<NavigationService>();

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _navigationService.addListener(_onViewChanged);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _navigationService.removeListener(_onViewChanged);
    super.dispose();
  }

  // This method is called by the listener when the view changes.
  // It handles side effects like resizing and showing the window.
  void _onViewChanged() {
    final view = _navigationService.currentView;
    // Adjust window size and properties based on view
    if (view == AppView.commandCenter) {
      windowManager.setResizable(false);
      windowManager.setSize(kCommandCenterSize);
      windowManager.center();
    } else if (view == AppView.history) {
      windowManager.show();
      windowManager.focus();
      windowManager.setResizable(true);
      windowManager.setSize(kHistoryViewSize);
      windowManager.center();
    } else if (view == AppView.settings) {
      windowManager.show();
      windowManager.focus();
      windowManager.setResizable(true);
      windowManager.setSize(kSettingsViewSize);
      windowManager.center();
    } else if (view == AppView.notificationCenter) {
      windowManager.show();
      windowManager.focus();
      windowManager.setResizable(true);
      windowManager.setSize(kNotificationCenterSize);
      windowManager.center();
    }
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds the widget tree when the navigation service notifies its listeners.
    return AnimatedBuilder(
      animation: _navigationService,
      builder: (context, child) => MacosApp(
        title: appTitle,
        color: MacosColors.transparent,
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: () {
          switch (_navigationService.currentView) {
            case AppView.commandCenter:
              return const CommandCenterView();
            case AppView.history:
              return const HistoryView();
            case AppView.settings:
              return const SettingsView();
            case AppView.notificationCenter:
              return NotificationCenterView();
          }
        }(),
      ),
    );
  }

  @override
  void onTrayIconMouseDown() async {
    // Show/Hide window or pop up context menu
    await showHide();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_hide_window':
        await showHide();
        break;
      case 'show_history':
        _navigationService.switchToView(AppView.history);
        break;
      case 'show_settings':
        _navigationService.switchToView(AppView.settings);
        break;
      case 'quit_app':
        await windowManager.destroy();
        await hotKeyManager.unregisterAll();
        exit(0);
    }
  }
}

// ALL OF CommandCenterView and its state have been moved to views/command_center_view.dart

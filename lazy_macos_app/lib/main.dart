import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for PhysicalKeyboardKey
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io'; // Required for Platform.isMacOS

const String appTitle = 'Lazy macOS App';

// Define the hotkey
final HotKey _hotKey = HotKey(
  key: PhysicalKeyboardKey.keyL,
  modifiers: [HotKeyModifier.meta],
  scope: HotKeyScope.system,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll(); // Unregister all previous hotkeys
  await setupHotkeys();
  await setupTray();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(600, 70),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true, // Hide from taskbar, rely on tray and hotkey
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(false);
    // Start hidden, to be shown by hotkey or tray
    // await windowManager.show();
    // await windowManager.focus();
    // For development, we might want to show it initially
    if (Platform.isMacOS) {
      // Or some dev flag
      await windowManager.show();
      await windowManager.focus();
    }
  });

  runApp(const MyApp());
}

Future<void> setupHotkeys() async {
  await hotKeyManager.register(
    _hotKey,
    keyDownHandler: (hotKey) async {
      // Show/Hide and focus the window
      bool isVisible = await windowManager.isVisible();
      if (isVisible) {
        // Optional: if window is command center and focused, maybe hide it?
        // For now, just ensure it's focused if visible, or show if not.
        await windowManager.focus();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    },
  );
}

Future<void> setupTray() async {
  // TODO: Add a real icon path, ensure assets folder and pubspec.yaml are updated
  String iconPath = Platform.isWindows
      ? 'assets/app_icon.ico'
      : 'assets/app_icon.png';
  // For macOS, it's better to use a template image if possible.
  // If 'assets/app_icon.png' is a template image, set isTemplate to true.
  // await trayManager.setIcon(iconPath, isTemplate: true);
  // Using a placeholder for now or relying on default if any
  try {
    await trayManager.setIcon(iconPath);
  } catch (e) {
    print("Error setting tray icon: $e. Using default behavior if any.");
  }

  Menu menu = Menu(
    items: [
      MenuItem(key: 'show_hide_window', label: 'Show/Hide Command Center'),
      MenuItem.separator(),
      MenuItem(key: 'quit_app', label: 'Quit Lazy App'),
    ],
  );
  
  await trayManager.setContextMenu(menu);
  // It's good practice to also set a tooltip
  await trayManager.setToolTip("Lazy macOS App");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener {
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

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: appTitle,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const CommandCenterView(),
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
          await windowManager.show();
          await windowManager.focus();
        }
        break;
      case 'quit_app':
        await windowManager.destroy(); // Properly close and destroy the window
        // hotKeyManager.unregisterAll(); // Ensure hotkeys are cleaned up
        // exit(0); // Exit the application
        break;
    }
  }
}

class CommandCenterView extends StatelessWidget {
  const CommandCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        backgroundColor:
            MacosColors.transparent, // Example for a more overlay feel
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                child: const Center(
                  child: MacosTextField(
                    placeholder: 'Capture anything...',
                    // autofocus: true, // Consider managing focus carefully
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

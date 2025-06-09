import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';

const String appTitle = 'Lazy macOS App';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(600, 70), // Small initial size for command center
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false, // Set to true if you want to hide from taskbar initially
    titleBarStyle: TitleBarStyle.hidden, // Frameless or hidden title bar
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless(); // Ensures a truly frameless window if desired
    await windowManager.setResizable(false); // Not resizable in command center mode
    // await windowManager.hide(); // Start hidden, to be shown by hotkey or tray
    // For now, let's show it to verify setup
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: appTitle,
      theme: MacosThemeData.light(), // Or MacosThemeData.dark()
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const CommandCenterView(), // Placeholder for our main view
    );
  }
}

// Placeholder for the Command Center View
class CommandCenterView extends StatelessWidget {
  const CommandCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const Center(
                child: MacosTextField(
                  placeholder: 'Capture anything...',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


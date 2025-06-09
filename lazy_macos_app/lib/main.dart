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
import 'models/captured_content.dart';
import 'services/content_service.dart';
import 'views/history_view.dart';

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

// Global key to access CommandCenterView state
final GlobalKey<_CommandCenterViewState> commandCenterKey =
    GlobalKey<_CommandCenterViewState>();

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

        // Refresh clipboard content when window appears
        commandCenterKey.currentState?._checkClipboard();
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
      MenuItem(key: 'show_history', label: 'Show Capture History'),
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

// Enum for app views
enum AppView { commandCenter, history }

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

    // Adjust window size based on view
    if (view == AppView.commandCenter) {
      // Smaller size for command center
      windowManager.setSize(const Size(600, 70));
    } else if (view == AppView.history) {
      // Larger size for history view
      windowManager.setSize(const Size(800, 500));
      windowManager.center();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: appTitle,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          switch (_currentView) {
            case AppView.commandCenter:
              return CommandCenterView(
                key: commandCenterKey,
                onShowHistory: () => _switchToView(AppView.history),
              );
            case AppView.history:
              return MacosWindow(
                child: Stack(
                  children: [
                    const HistoryView(),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MacosIconButton(
                        icon: const Icon(
                          CupertinoIcons.return_icon,
                          color: MacosColors.systemBlueColor,
                        ),
                        onPressed: () => _switchToView(AppView.commandCenter),
                        semanticLabel: 'Back to Command Center',
                      ),
                    ),
                  ],
                ),
              );
            }
        },
      ),
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

          // Refresh clipboard content when window appears
          commandCenterKey.currentState?._checkClipboard();
        }
        break;
      case 'show_history':
        // Switch to history view
        _switchToView(AppView.history);
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'quit_app':
        await windowManager.destroy(); // Properly close and destroy the window
        await hotKeyManager.unregisterAll(); // Ensure hotkeys are cleaned up
        exit(0); // Exit the application
    }
  }
}

class CommandCenterView extends StatefulWidget {
  final VoidCallback onShowHistory;

  const CommandCenterView({super.key, required this.onShowHistory});

  @override
  State<CommandCenterView> createState() => _CommandCenterViewState();
}

class _CommandCenterViewState extends State<CommandCenterView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ContentService _contentService = ContentService();

  // UI state
  bool _isUrl = false;
  bool _showFeedback = false;
  String _feedbackMessage = '';
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    // Check clipboard content when view is initialized
    _checkClipboard();
    // We need to use a post-frame callback to ensure the widget is fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Listen for text changes to detect URLs
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  // Detect URLs in text field
  void _onTextChanged() {
    final text = _textController.text.trim();
    final newContent = CapturedContent.fromString(text);
    final newIsUrl = newContent.type == ContentType.url;

    if (newIsUrl != _isUrl) {
      setState(() {
        _isUrl = newIsUrl;
      });
    }
  }

  // Check clipboard for content and pre-fill text field
  Future<void> _checkClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        setState(() {
          final text = data.text!.trim();
          _textController.text = text;
          _isUrl = CapturedContent.fromString(text).type == ContentType.url;

          // Select all text so user can easily replace it if desired
          _textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _textController.text.length,
          );
        });
      }
    } catch (e) {
      debugPrint('Error reading clipboard: $e');
    }
  }

  // Show feedback message briefly
  void _showFeedbackMessage(String message, {bool isError = false}) {
    setState(() {
      _showFeedback = true;
      _feedbackMessage = message;
    });

    // Hide feedback after a delay
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
        });
      }
    });
  }

  // Handle content saving
  void _saveContent() async {
    final String content = _textController.text.trim();
    if (content.isEmpty) return;

    // Create captured content
    final capturedContent = CapturedContent.fromString(content);

    // Save using service
    final success = await _contentService.addContent(capturedContent);

    if (success) {
      // Show feedback based on content type
      final contentType = capturedContent.type == ContentType.url
          ? 'URL'
          : 'Text';
      _showFeedbackMessage('$contentType captured successfully!');

      // Clear the text field
      _textController.clear();

      // Hide the window after a short delay
      Timer(const Duration(milliseconds: 800), () async {
        await windowManager.hide();
      });
    } else {
      _showFeedbackMessage('Failed to save content', isError: true);
    }
  }

  // Hide the window
  Future<void> _hideWindow() async {
    await windowManager.hide();
  }

  // Clear the text field
  void _clearTextField() {
    _textController.clear();
    _focusNode.requestFocus();
  }

  // Save and clear (without hiding)
  void _saveAndContinue() async {
    final String content = _textController.text.trim();
    if (content.isEmpty) return;

    final capturedContent = CapturedContent.fromString(content);
    final success = await _contentService.addContent(capturedContent);

    if (success) {
      final contentType = capturedContent.type == ContentType.url
          ? 'URL'
          : 'Text';
      _showFeedbackMessage('$contentType saved! Continue capturing...');
      _clearTextField();
    } else {
      _showFeedbackMessage('Failed to save content', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (keyEvent) {
          // Handle global keyboard shortcuts
          if (keyEvent is KeyDownEvent) {
            if (keyEvent.logicalKey == LogicalKeyboardKey.escape) {
              _hideWindow();
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.keyC &&
                HardwareKeyboard.instance.isMetaPressed &&
                HardwareKeyboard.instance.isShiftPressed) {
              _clearTextField();
            }
          }
        },
        child: MacosScaffold(
          backgroundColor: MacosColors.transparent,
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CallbackShortcuts(
                              bindings: {
                                // Save and continue with Cmd+Enter
                                const SingleActivator(
                                  LogicalKeyboardKey.enter,
                                  meta: true,
                                ): _saveAndContinue,
                                // Clear with Cmd+Delete
                                const SingleActivator(
                                  LogicalKeyboardKey.delete,
                                  meta: true,
                                ): _clearTextField,
                              },
                              child: MacosTextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                placeholder: 'Capture anything...',
                                autofocus: true,
                                onSubmitted: (value) => _saveContent(),
                                prefix: _isUrl
                                    ? const Icon(
                                        CupertinoIcons.link,
                                        size: 16,
                                        color: MacosColors.systemGrayColor,
                                      )
                                    : const Icon(
                                        CupertinoIcons.text_quote,
                                        size: 16,
                                        color: MacosColors.systemGrayColor,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MacosTooltip(
                                message: 'History',
                                child: MacosIconButton(
                                  icon: const Icon(
                                    CupertinoIcons.clock,
                                    color: MacosColors.systemGrayColor,
                                  ),
                                  onPressed: widget.onShowHistory,
                                  semanticLabel: 'Show History',
                                ),
                              ),
                              const SizedBox(width: 4),
                              MacosTooltip(
                                message: 'Clear (⌘⌫)',
                                child: MacosIconButton(
                                  icon: const Icon(
                                    CupertinoIcons.clear,
                                    color: MacosColors.systemGrayColor,
                                    size: 18,
                                  ),
                                  onPressed: _clearTextField,
                                  semanticLabel: 'Clear',
                                ),
                              ),
                              const SizedBox(width: 4),
                              MacosTooltip(
                                message: 'Save (⏎)',
                                child: MacosIconButton(
                                  icon: const Icon(
                                    CupertinoIcons.check_mark_circled,
                                    color: MacosColors.systemBlueColor,
                                  ),
                                  onPressed: () => _saveContent(),
                                  semanticLabel: 'Save',
                                ),
                              ),
                              const SizedBox(width: 4),
                              MacosTooltip(
                                message: 'Save & Continue (⌘⏎)',
                                child: MacosIconButton(
                                  icon: const Icon(
                                    CupertinoIcons.add_circled,
                                    color: MacosColors.systemGreenColor,
                                  ),
                                  onPressed: _saveAndContinue,
                                  semanticLabel: 'Save and continue',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_showFeedback) ...[
                        const SizedBox(height: 4),
                        Text(
                          _feedbackMessage,
                          style: MacosTheme.of(context).typography.caption2,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

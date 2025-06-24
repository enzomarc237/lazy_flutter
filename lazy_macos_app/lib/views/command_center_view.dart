import 'dart:async';
import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

import '../models/captured_content.dart';
import '../models/command.dart';
import '../services/content_service.dart';
import '../services/clipboard_service.dart';
import '../services/navigation_service.dart';
import '../services/service_locator.dart';
import '../core/app_views.dart';

class CommandCenterView extends StatefulWidget {
  const CommandCenterView({
    super.key,
    // Removed onShowHistory from here as it's not a direct property of the widget
    // and should be handled by the NavigationService directly.
  });

  @override
  State<CommandCenterView> createState() => _CommandCenterViewState();
}

class _CommandCenterViewState extends State<CommandCenterView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ContentService _contentService = getIt<ContentService>();
  final ClipboardService _clipboardService = getIt<ClipboardService>();
  final NavigationService _navigationService = getIt<NavigationService>();

  // UI state
  bool _isUrl = false;

  // New state for command palette
  late final List<Command> _commands;
  List<Command> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState(); // It's conventional to call super.initState() first.

    // Initialize commands with actions that call the callbacks from the widget
    _commands = [
      Command(
        title: 'Save',
        icon: CupertinoIcons.check_mark_circled,
        action: _saveContent,
      ),
      Command(
        title: 'Show History',
        icon: CupertinoIcons.clock,
        action: () => _navigationService.switchToView(AppView.history),
        badgeCount: 0, // Will be updated dynamically
      ),
      Command(
        title: 'Settings',
        icon: CupertinoIcons.settings,
        action: () => _navigationService.switchToView(AppView.settings),
      ),
      Command(
        title: 'Notifications',
        icon: CupertinoIcons.bell,
        action: () {}, // Placeholder for future notification center
      ),
      Command(
        title: 'Clear',
        icon: CupertinoIcons.clear,
        action: _clearTextField,
      ),
    ];

    _filteredCommands = _commands;
    _updateHistoryBadge(); // Initial badge update
    _clipboardService.checkClipboard(); // Initial clipboard check on view load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _clipboardService.addListener(_onClipboardContentChanged); // Listen for clipboard changes
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _clipboardService.removeListener(_onClipboardContentChanged); // Remove listener
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _updateHistoryBadge() async {
    final count = (await _contentService.getAllContent()).length;
    if (!mounted) return;
    setState(() {
      final historyCommandIndex = _commands.indexWhere(
        (cmd) => cmd.title == 'Show History',
      );
      if (historyCommandIndex != -1) {
        _commands[historyCommandIndex] = Command(
          title: 'Show History',
          icon: CupertinoIcons.clock,
          action: () => _navigationService.switchToView(AppView.history),
          badgeCount: count,
        );
      }
    });
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final newContent = CapturedContent.fromString(text);
    final newIsUrl = newContent.type == ContentType.url;

    if (newIsUrl != _isUrl) {
      setState(() {
        _isUrl = newIsUrl;
      });
    }

    setState(() {
      if (text.isEmpty) {
        _filteredCommands = _commands;
      } else {
        _filteredCommands = _commands
            .where(
              (cmd) => cmd.title.toLowerCase().contains(text.toLowerCase()),
            )
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  /// Called when the ClipboardService notifies of a change in clipboard content.
  void _onClipboardContentChanged() {
    final String? clipboardText = _clipboardService.lastClipboardContent;
    if (clipboardText != null && clipboardText != _textController.text.trim()) {
      setState(() {
        _textController.text = clipboardText;
        _isUrl = CapturedContent.fromString(clipboardText).type == ContentType.url;
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      });
    } else if (clipboardText == null && _textController.text.isNotEmpty) {
      _textController.clear(); // Clear if clipboard is empty and text field is not
    }
  }

  void _executeCommand() {
    if (_isUrl) {
      _saveContent();
      launchUrlString(_textController.text.trim());
      return;
    }

    if (_filteredCommands.isEmpty) {
      _saveContent();
      return;
    }
    // Directly call the action from the command object
    _filteredCommands[_selectedIndex].action();
  }

  void _saveContent() async {
    final String content = _textController.text.trim();
    if (content.isEmpty) return;

    final capturedContent = CapturedContent.fromString(content);
    final success = await _contentService.addContent(capturedContent);

    if (success) {
      _textController.clear();
      await _contentService.showNotification(
        'Content Saved',
        'Your content has been successfully saved to history.',
      );
      Timer(const Duration(milliseconds: 200), () async {
        await windowManager.hide();
      });
    } else {
      print('Failed to save content');
    }
  }

  Future<void> _hideWindow() async {
    await windowManager.hide();
  }

  void _clearTextField() {
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _navigateCommands(int direction) {
    setState(() {
      final newIndex = _selectedIndex + direction;
      if (newIndex >= 0 && newIndex < _filteredCommands.length) {
        _selectedIndex = newIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      backgroundColor: MacosColors.transparent,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (keyEvent) {
          if (keyEvent is KeyDownEvent) {
            if (keyEvent.logicalKey == LogicalKeyboardKey.escape) {
              _hideWindow();
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowDown) {
              _navigateCommands(1);
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
              _navigateCommands(-1);
            }
          }
        },
        child: MacosScaffold(
          backgroundColor: MacosColors.transparent,
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosTextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      placeholder: 'Type an action or navigate...',
                      clearButtonMode: OverlayVisibilityMode.editing,
                      focusedDecoration: BoxDecoration(
                        border: Border.all(width: 0, color: Colors.transparent),
                      ),
                      autofocus: true,
                      onSubmitted: (value) => _executeCommand(),
                      prefix: Icon(
                        _isUrl ? CupertinoIcons.link : CupertinoIcons.search,
                        size: 16,
                        color: MacosTheme.of(context).primaryColor,
                      ),
                    ),
                    const Divider(height: 16, color: Colors.white24),
                    SizedBox(height: 8.0),
                    Expanded(
                      child:
                          (_textController.text.isNotEmpty &&
                              _filteredCommands.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.search,
                                    size: 32,
                                    color: MacosColors.systemGrayColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No results for "${_textController.text}"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: MacosColors.systemGrayColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredCommands.length,
                              itemBuilder: (context, index) {
                                final command = _filteredCommands[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    _executeCommand();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == index
                                          ? MacosColors.systemBlueColor
                                                .withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _selectedIndex == index
                                          ? Border.all(
                                              color:
                                                  MacosColors.systemBlueColor,
                                              width: 0.5,
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          command.icon,
                                          size: 18,
                                          color: MacosColors.systemGrayColor,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          command.title,
                                          style: MacosTheme.of(
                                            context,
                                          ).typography.body,
                                        ),
                                        const Spacer(),
                                        if (command.badgeCount != null &&
                                            command.badgeCount! > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  MacosColors.systemGrayColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${command.badgeCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 16, color: Colors.white24),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHint('↑↓', 'to navigate'),
                          const SizedBox(width: 16),
                          _buildHint('⏎', 'to select'),
                          const SizedBox(width: 16),
                          _buildHint('esc', 'to close'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(String key, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            color: MacosColors.systemGrayColor,
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../models/captured_content.dart';
import '../models/command.dart';
import '../services/content_service.dart';

class CommandCenterView extends StatefulWidget {
  final VoidCallback onShowHistory;
  final VoidCallback onShowSettings;

  const CommandCenterView({
    super.key,
    required this.onShowHistory,
    required this.onShowSettings,
  });

  @override
  State<CommandCenterView> createState() => _CommandCenterViewState();
}

class _CommandCenterViewState extends State<CommandCenterView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ContentService _contentService = ContentService();

  // UI state
  bool _isUrl = false;

  // New state for command palette
  late final List<Command> _commands;
  List<Command> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

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
        action: widget.onShowHistory,
      ),
      Command(
        title: 'Settings',
        icon: CupertinoIcons.settings,
        action: widget.onShowSettings,
      ),
      Command(
        title: 'Clear',
        icon: CupertinoIcons.clear,
        action: _clearTextField,
      ),
    ];

    _filteredCommands = _commands;
    _checkClipboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _checkClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        setState(() {
          final text = data.text!.trim();
          _textController.text = text;
          _isUrl = CapturedContent.fromString(text).type == ContentType.url;
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

  void _executeCommand() {
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
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: MacosTheme.of(context).brightness == Brightness.dark
                        ? const Color.fromRGBO(40, 40, 40, 0.95)
                        : const Color.fromRGBO(240, 240, 240, 0.95),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MacosTextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        placeholder: 'Type an action or navigate...',
                        autofocus: true,
                        onSubmitted: (value) => _executeCommand(),
                        prefix: Icon(
                          _isUrl ? CupertinoIcons.link : CupertinoIcons.search,
                          size: 16,
                          color: MacosColors.systemGrayColor,
                        ),
                      ),
                      const Divider(height: 16),
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
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedIndex == index
                                            ? MacosColors.systemBlueColor
                                                  .withOpacity(0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHint('↑↓', 'to navigate'),
                          const SizedBox(width: 16),
                          _buildHint('⏎', 'to select'),
                          const SizedBox(width: 16),
                          _buildHint('esc', 'to close'),
                        ],
                      ),
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

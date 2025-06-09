import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import '../models/captured_content.dart';
import '../services/content_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ContentService _contentService = ContentService();
  List<CapturedContent> _capturedItems = [];

  @override
  void initState() {
    super.initState();
    _loadCapturedItems();
  }

  void _loadCapturedItems() {
    setState(() {
      _capturedItems = _contentService.getAllContent();
    });
  }

  // Copy content to clipboard
  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('Copied to Clipboard'),
        message: const Text('Content has been copied to the clipboard.'),
        primaryButton: PushButton(
          buttonSize: ButtonSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ),
    );
  }

  // Delete a captured item
  void _deleteItem(int index) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('Delete Item'),
        message: const Text('Are you sure you want to delete this item?'),
        primaryButton: PushButton(
          buttonSize: ButtonSize.large,
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implement actual deletion in ContentService
            // For now, just reload the list
            _loadCapturedItems();
          },
          child: const Text('Delete'),
        ),
        secondaryButton: PushButton(
          buttonSize: ButtonSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Capture History'),
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: _loadCapturedItems,
            showLabel: false,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (_capturedItems.isEmpty) {
              return const Center(
                child: Text(
                  'No captured items yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: MacosColors.systemGrayColor,
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: scrollController,
              itemCount: _capturedItems.length,
              itemBuilder: (context, index) {
                final item = _capturedItems[index];
                final isUrl = item.type == ContentType.url;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: MacosListTile(
                    leading: Icon(
                      isUrl ? CupertinoIcons.link : CupertinoIcons.text_quote,
                      color: isUrl
                          ? MacosColors.systemBlueColor
                          : MacosColors.systemGrayColor,
                    ),
                    title: Text(
                      item.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Captured on ${_formatDate(item.timestamp)}',
                      style: MacosTheme.of(context).typography.caption2,
                    ),
                    onClick: () {
                      // Show details in a dialog or open URL
                      if (isUrl) {
                        // TODO: Implement URL opening
                        _copyToClipboard(item.content);
                      } else {
                        _showContentDetails(item);
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MacosTooltip(
                          message: 'Copy to clipboard',
                          child: MacosIconButton(
                            icon: const MacosIcon(
                              CupertinoIcons.doc_on_clipboard,
                            ),
                            onPressed: () => _copyToClipboard(item.content),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MacosTooltip(
                          message: 'Delete',
                          child: MacosIconButton(
                            icon: const MacosIcon(CupertinoIcons.trash),
                            onPressed: () => _deleteItem(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Format date in a user-friendly way
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Show full content details
  void _showContentDetails(CapturedContent item) {
    showMacosSheet(
      context: context,
      builder: (context) => MacosSheet(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Captured ${item.type == ContentType.url ? 'URL' : 'Text'}',
                style: MacosTheme.of(context).typography.title3,
              ),
              const SizedBox(height: 16),
              Text(
                'Timestamp: ${_formatDate(item.timestamp)}',
                style: MacosTheme.of(context).typography.body,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: MacosColors.systemGrayColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                child: SelectableText(
                  item.content,
                  style: MacosTheme.of(context).typography.body,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PushButton(
                    buttonSize: ButtonSize.large,
                    onPressed: () => _copyToClipboard(item.content),
                    child: const Text('Copy to Clipboard'),
                  ),
                  const SizedBox(width: 8),
                  PushButton(
                    buttonSize: ButtonSize.large,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

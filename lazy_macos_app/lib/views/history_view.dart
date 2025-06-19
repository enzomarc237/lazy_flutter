import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gemini_service.dart';
import '../models/captured_content.dart';
import '../services/content_service.dart';

class HistoryView extends StatefulWidget {
  final VoidCallback onShowCommandCenter;

  const HistoryView({super.key, required this.onShowCommandCenter});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ContentService _contentService = ContentService();
  late Future<List<CapturedContent>> _capturedItemsFuture;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadCapturedItems();
  }
  final GeminiService _geminiService = GeminiService();

  Future<String> _getSummary(CapturedContent item) async {
    if (item.summary != null && item.summary!.isNotEmpty) {
      return item.summary!;
    }
    return 'No summary available.';
  }

  Future<void> _generateSummary(CapturedContent item) async {
    final summary = await _geminiService.summarize(item.content);
    if (item.id != null) {
      await _contentService.updateCaptureSummary(item.id!, summary);
      _loadCapturedItems(); // Refresh the list
    }
  }

  void _loadCapturedItems() {
    setState(() {
      _capturedItemsFuture = _contentService.getAllContent();
    });
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    // You might want a less intrusive feedback mechanism here
  }

  void _deleteItem(CapturedContent item) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('Delete Item'),
        message: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () async {
            Navigator.pop(context);
            if (item.id != null) {
              await _contentService.deleteContent(item.id!);
              _loadCapturedItems(); // Refresh the list
              setState(() {
                _selectedIndex = null; // Clear selection
              });
            }
          },
          child: const Text('Delete'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Capture History'),
        actions: [
          ToolBarIconButton(
            label: 'Back to Command Center',
            icon: const MacosIcon(CupertinoIcons.return_icon),
            onPressed: widget.onShowCommandCenter,
            showLabel: false,
          ),
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
            return FutureBuilder<List<CapturedContent>>(
              future: _capturedItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: ProgressCircle());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No captured items yet',
                      style: TextStyle(fontSize: 16, color: MacosColors.systemGrayColor),
                    ),
                  );
                }

                final items = snapshot.data!;
                return ResizablePane(
                  minWidth: 200,
                  startWidth: 300,
                  windowBreakpoint: 600,
                  resizableSide: ResizableSide.right,
                  builder: (context, scrollController) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isUrl = item.type == ContentType.url;
                        return MacosListTile(
                          leading: Icon(
                            isUrl ? CupertinoIcons.link : CupertinoIcons.text_quote,
                            color: isUrl ? MacosColors.systemBlueColor : MacosColors.systemGrayColor,
                          ),
                          title: Text(item.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Captured on ${_formatDate(item.timestamp)}', style: MacosTheme.of(context).typography.caption2),
                          onClick: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          selected: _selectedIndex == index,
                        );
                      },
                    );
                  },
                  endPane: _selectedIndex == null
                      ? const Center(child: Text('Select an item to see details'))
                      : _buildDetailView(items[_selectedIndex!]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailView(CapturedContent item) {
    final isUrl = item.type == ContentType.url;
    return MacosScaffold(
      toolBar: ToolBar(
        title: Text(isUrl ? 'URL Details' : 'Text Details'),
        actions: [
          ToolBarIconButton(
            label: 'Copy',
            icon: const MacosIcon(CupertinoIcons.doc_on_doc),
            onPressed: () => _copyToClipboard(item.content),
            showLabel: false,
          ),
          if (isUrl)
            ToolBarIconButton(
              label: 'Open URL',
              icon: const MacosIcon(CupertinoIcons.globe),
              onPressed: () => _openUrl(item.content),
              showLabel: false,
            ),
          ToolBarIconButton(
            label: 'Delete',
            icon: const MacosIcon(CupertinoIcons.trash),
            onPressed: () => _deleteItem(item),
            showLabel: false,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(item.content, style: MacosTheme.of(context).typography.body),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: _getSummary(item),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ProgressCircle();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Text(snapshot.data ?? 'No summary available.');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  PushButton(
                    controlSize: ControlSize.large,
                    child: const Text('Generate Summary'),
                    onPressed: () => _generateSummary(item),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

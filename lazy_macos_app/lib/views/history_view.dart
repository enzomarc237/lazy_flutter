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
      _loadCapturedItems();
    }
  }

  void _loadCapturedItems() {
    setState(() {
      _capturedItemsFuture = _contentService.getAllContent();
    });
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _deleteItem(CapturedContent item) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('Delete Item'),
        message: const Text('Are you sure you want to delete this item?'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () async {
            Navigator.pop(context);
            if (item.id != null) {
              await _contentService.deleteContent(item.id!);
              _loadCapturedItems();
              setState(() => _selectedIndex = null);
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
                      style: TextStyle(
                        fontSize: 16,
                        color: MacosColors.systemGrayColor,
                      ),
                    ),
                  );
                }

                final items = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: MacosTheme.of(context).brightness == Brightness.dark
                        ? const Color.fromRGBO(40, 40, 40, 0.9)
                        : const Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: MacosTheme.of(context).brightness == Brightness.dark
                          ? const Color.fromRGBO(100, 100, 100, 0.8)
                          : const Color.fromRGBO(220, 220, 220, 0.8),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isUrl = item.type == ContentType.url;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
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
                                            color: MacosColors.systemBlueColor,
                                            width: 0.5,
                                          )
                                        : null,
                                  ),
                                  child: MacosListTile(
                                    leading: Icon(
                                      isUrl
                                          ? CupertinoIcons.link
                                          : CupertinoIcons.text_quote,
                                      color: isUrl
                                          ? MacosColors.systemBlueColor
                                          : MacosColors.systemGrayColor,
                                    ),
                                    title: Text(
                                      item.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Captured on ${_formatDate(item.timestamp)}',
                                      style: MacosTheme.of(context)
                                          .typography
                                          .caption2
                                          .copyWith(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: Colors.white.withAlpha(30),
                        ),
                        Expanded(
                          flex: 3,
                          child: _selectedIndex == null
                              ? const Center(
                                  child: Text('Select an item to see details'),
                                )
                              : _buildDetailView(items[_selectedIndex!]),
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
                  SelectableText(
                    item.content,
                    style: MacosTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withAlpha(30)),
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

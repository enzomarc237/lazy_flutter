import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gemini_service.dart';
import '../models/captured_content.dart';
import '../services/content_service.dart';
import '../services/navigation_service.dart';
import '../services/service_locator.dart';
import '../core/app_views.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ContentService _contentService = getIt<ContentService>();
  final GeminiService _geminiService = getIt<GeminiService>();
  final NavigationService _navigationService = getIt<NavigationService>();

  late Future<List<CapturedContent>> _capturedItemsFuture;
  List<CapturedContent> _items = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadCapturedItems();
  }

  Future<String> _getSummary(CapturedContent item) async {
    if (item.summary != null && item.summary!.isNotEmpty) {
      return item.summary!;
    }
    return 'No summary available.';
  }

  Future<void> _generateSummary(CapturedContent item) async {
    if (item.id == null) return;

    try {
      final summary = await _geminiService.summarize(item.content);
      await _contentService.updateCaptureSummary(item.id!, summary);
      // Instead of reloading all items, just update the specific one
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(summary: summary);
        }
      });
    } on GeminiException catch (e) {
      _showErrorDialog('Summarization Error', e.message);
    } catch (e) {
      _showErrorDialog('An Unexpected Error Occurred', e.toString());
    }
  }

  void _loadCapturedItems() {
    setState(() {
      _capturedItemsFuture = _contentService.getAllContent().then((items) {
        if (mounted) {
          _items = items;
        }
        return items;
      });
    });
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _showErrorDialog(String title, String message) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: Text(title),
        message: Text(message),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ),
    );
  }

  void _deleteItem(CapturedContent item) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('Delete Item'),
        message: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () async {
            Navigator.pop(context);
            if (item.id != null) {
              await _contentService.deleteContent(item.id!);
              if (!mounted) return;
              setState(() {
                _items.removeWhere((i) => i.id == item.id);
                _selectedIndex = null;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: MacosScaffold(
        toolBar: ToolBar(
          title: const Text('Capture History'),
          actions: [
            ToolBarIconButton(
              label: 'Back to Command Center',
              icon: const MacosIcon(CupertinoIcons.return_icon),
              onPressed: () =>
                  _navigationService.switchToView(AppView.commandCenter),
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
      
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
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
                                        ? MacosColors.systemBlueColor.withOpacity(
                                            0.15,
                                          )
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
                              : _buildDetailView(_items[_selectedIndex!]),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: item.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MacosColors.systemGrayColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('#$tag'),
                        );
                      }).toList(),
                    ),
                  ],
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

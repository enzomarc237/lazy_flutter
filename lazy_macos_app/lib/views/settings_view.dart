import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import '../services/gemini_service.dart';
import '../services/navigation_service.dart';
import '../services/service_locator.dart';
import '../core/app_views.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _apiKeyController = TextEditingController();
  final _geminiService = getIt<GeminiService>();
  final _navigationService = getIt<NavigationService>();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _geminiService.getApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  Future<void> _saveApiKey() async {
    await _geminiService.saveApiKey(_apiKeyController.text);
    _showSavedDialog();
  }

  void _showSavedDialog() {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.check_mark_circled),
        title: const Text('API Key Saved'),
        message: const Text('Your Gemini API key has been saved securely.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ),
    );
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
          title: const Text('Settings'),
          actions: [
            ToolBarIconButton(
              label: 'Back to Command Center',
              icon: const MacosIcon(CupertinoIcons.return_icon),
              onPressed: () =>
                  _navigationService.switchToView(AppView.commandCenter),
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
                    const Text('Gemini API Key'),
                    const SizedBox(height: 10),
                    MacosTextField(
                      controller: _apiKeyController,
                      placeholder: 'Enter your Gemini API Key',
                    ),
                    const SizedBox(height: 20),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: _saveApiKey,
                      child: const Text('Save API Key'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

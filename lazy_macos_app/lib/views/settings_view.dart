import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import '../services/gemini_service.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onShowCommandCenter;

  const SettingsView({super.key, required this.onShowCommandCenter});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _apiKeyController = TextEditingController();
  final _geminiService = GeminiService();

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
    // You might want to show a confirmation message
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Settings'),
        actions: [
          ToolBarIconButton(
            label: 'Back to Command Center',
            icon: const MacosIcon(CupertinoIcons.return_icon),
            onPressed: widget.onShowCommandCenter,
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
    );
  }
}

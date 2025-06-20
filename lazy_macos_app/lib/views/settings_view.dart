import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
              child: SingleChildScrollView(
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
              ),
            );
          },
        ),
      ],
    );
  }
}

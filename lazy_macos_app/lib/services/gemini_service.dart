import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final _secureStorage = const FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  Future<String> summarize(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'API Key not set.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      final prompt = 'Summarize the following text: $text';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Could not generate summary.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}

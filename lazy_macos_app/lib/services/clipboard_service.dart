import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier

/// A service to manage clipboard interactions and notify listeners of changes.
class ClipboardService extends ChangeNotifier {
  String? _lastClipboardContent;

  String? get lastClipboardContent => _lastClipboardContent;

  /// Checks the current clipboard content and updates if it's different.
  /// Notifies listeners if the content has changed.
  Future<void> checkClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      final String? currentContent = data?.text?.trim();

      if (currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        notifyListeners(); // Notify any widgets listening to this service
      }
    } catch (e) {
      debugPrint('Error reading clipboard: $e');
    }
  }
}
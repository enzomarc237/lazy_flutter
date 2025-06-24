import 'package:flutter/foundation.dart';
import '../core/app_views.dart';

/// A service to manage the current view of the application.
///
/// It uses ChangeNotifier to notify listeners when the view changes.
class NavigationService extends ChangeNotifier {
  AppView _currentView = AppView.commandCenter;

  AppView get currentView => _currentView;

  void switchToView(AppView view) {
    if (_currentView != view) {
      _currentView = view;
      notifyListeners();
    }
  }
}
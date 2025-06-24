import 'package:get_it/get_it.dart';

import 'content_service.dart';
import 'database_helper.dart';
import 'gemini_service.dart';
import 'clipboard_service.dart';
import 'navigation_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register services
  getIt.registerLazySingleton<ClipboardService>(() => ClipboardService());
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<ContentService>(
    () => ContentService(),
  ); // Corrected registration
  getIt.registerLazySingleton<GeminiService>(() => GeminiService());
}

# Lazy macOS App

Application Flutter moderne pour macOS permettant de capturer, organiser et exploiter du contenu (texte, URL) avec intégration IA (Gemini), notifications natives, gestion du presse-papiers, et navigation fluide.

## Fonctionnalités principales

- **Command Center** : Palette de commandes rapide pour capturer du texte ou des liens, avec détection automatique des URLs.
- **Historique** : Visualisation, recherche, copie, suppression et résumé IA des contenus capturés.
- **Paramètres** : Gestion sécurisée de la clé API Gemini (Google Generative AI).
- **Notifications natives** : Alertes discrètes lors des captures.
- **Intégration macOS** :
  - Icône dans la barre de menu (tray)
  - Raccourci clavier global (Cmd+L)
  - Fenêtres redimensionnables selon la vue

## Architecture

- **Service Locator** : Gestion centralisée des dépendances avec `get_it`.
- **Services** :
  - `ContentService` (gestion du contenu)
  - `DatabaseHelper` (SQLite via sqflite)
  - `GeminiService` (résumés IA)
  - `ClipboardService` (presse-papiers)
  - `NavigationService` (navigation entre vues)
- **Vues** :
  - `CommandCenterView`, `HistoryView`, `SettingsView`
- **Modèles** :
  - `CapturedContent`, `Command`

## Prérequis

- Flutter >= 3.8.0
- macOS (application desktop native)
- Clé API Gemini (Google Generative AI) pour la génération de résumés

## Installation & Lancement

```sh
flutter pub get
flutter run -d macos
```

## Commandes utiles

- **Analyser le code** :

  ```sh
  flutter analyze
  ```

- **Lancer les tests** :

  ```sh
  flutter test test/widget_test.dart
  ```

- **Mettre à jour les dépendances** :

  ```sh
  flutter pub upgrade
  ```

## Configuration Gemini

1. Obtenez une clé API Gemini sur [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Lancez l’application, ouvrez les paramètres et collez la clé dans le champ prévu.

## Dépendances principales

- `macos_ui`, `window_manager`, `tray_manager`, `hotkey_manager`
- `sqflite`, `flutter_secure_storage`, `google_generative_ai`, `get_it`, `url_launcher`

## Structure du projet

- `lib/`
  - `views/` : Vues principales de l’application
  - `models/` : Modèles de données
  - `services/` : Services et gestionnaires
  - `core/` : Constantes, enums, etc.

## Contribution

- Respecter les conventions Dart/Flutter
- Linting automatique avec `flutter_lints`
- Documenter toute nouvelle fonctionnalité dans ce README

## Licence

MIT

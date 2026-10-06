# Calorie Tracker — Flutter App

A dark-green calorie tracker with AI nutrition assistant and light/dark theme support.

## Features
- **Home** — Calorie ring, progress bar, macro breakdown (protein, carbs, fat, fiber, sodium), daily log
- **Meals** — Save meals with full nutritional facts; log them to today
- **AI Chat** — Ask about any meal, get nutrition estimates, save straight to Meals tab
- **Settings** — Toggle between System / Light / Dark theme; auto-follows device setting

## Setup

### 1. Install Flutter
https://docs.flutter.dev/get-started/install — then run `flutter doctor`

### 2. Get dependencies
```bash
cd calorie_tracker
flutter pub get
```

### 3. Add your Anthropic API key
Open `lib/services/ai_service.dart` and replace the placeholder:
```dart
'x-api-key': 'YOUR_API_KEY_HERE',
```
Get a key at https://console.anthropic.com

### 4. Run
```bash
# Any connected device / emulator
flutter run

# Release APK for Android
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# iOS (Mac only)
flutter build ios --release
```

## Project structure
```
lib/
├── main.dart                    # Entry point, state, shell
├── models/
│   └── meal.dart                # Meal + LoggedMeal models
├── screens/
│   ├── home_screen.dart         # Calorie ring + macros
│   ├── meals_screen.dart        # Saved meals + Add dialog
│   ├── ai_chat_screen.dart      # AI chatbot
│   └── settings_screen.dart     # Theme switcher + about
└── services/
    ├── theme_provider.dart      # ThemeProvider + color palettes
    ├── storage_service.dart     # SharedPreferences persistence
    └── ai_service.dart          # Anthropic API integration
```

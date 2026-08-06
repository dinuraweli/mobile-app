// File: lib/config/api_config.dart
class ApiConfig {
    // Pass at build/run time — never hardcode:
  //   flutter run --dart-define=GEMINI_API_KEY=your_key_here
  //   flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
}
// File: lib/config/api_config.dart
class ApiConfig {
  // Replace this with your actual Gemini API key
  static const String geminiApiKey = 'AIzaSyAbC5HMYjlfpaKlgAnmlKMrldMfvcSwKgA'; // Your key here
  
  // Verify key is set
  static bool get isGeminiConfigured => 
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_API_KEY_HERE';
}
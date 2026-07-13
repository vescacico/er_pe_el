/// Gemini API Configuration
/// Add your API key here to enable AI chatbot feature
/// Get your API key at: https://makersuite.google.com/app/apikey
class ApiConfig {
  // TODO: Replace with your actual Gemini API key
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Set to true when API key is configured
  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
}

// lib/config/api_config.dart
class ApiConfig {
  // For physical device: Use your computer's IP (e.g., '192.168.1.100')
  // For Android emulator: Use '10.0.2.2'
  // For iOS simulator: Use '127.0.0.1' or 'localhost'
  static const String baseUrl = 'http://127.0.0.1:5000'; // Use localhost for Chrome/local dev
  
  static String get extractEndpoint => '$baseUrl/api/extract';
  static String get audioProcessingEndpoint => '$baseUrl/api/audio_processing';
}
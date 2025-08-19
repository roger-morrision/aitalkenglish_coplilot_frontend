import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration utility class
/// Provides easy access to environment variables with fallbacks
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Initialize environment variables
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ Environment variables loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load environment variables: $e');
      print('📝 Using fallback configurations');
    }
  }

  /// Check if environment variables are loaded
  static bool get isLoaded => dotenv.isInitialized;

  // Backend Configuration
  static String get developmentBackendUrl => 
      dotenv.env['DEVELOPMENT_BACKEND_URL'] ?? 'http://localhost:3000';
  
  static String get stagingBackendUrl => 
      dotenv.env['STAGING_BACKEND_URL'] ?? 'https://aitalkenglish-staging.onrender.com';
  
  static String get productionBackendUrl => 
      dotenv.env['PRODUCTION_BACKEND_URL'] ?? 'https://aitalkenglish-coplilot-backend.onrender.com';
  
  static String get apiEnvironment => 
      dotenv.env['API_ENVIRONMENT']?.toLowerCase() ?? 'development';

  // API Keys
  static String get openRouterApiKey => 
      dotenv.env['OPENROUTER_API_KEY'] ?? '';

  // Timeout Configuration
  static int get chatTimeoutSeconds => 
      int.tryParse(dotenv.env['CHAT_TIMEOUT_SECONDS'] ?? '') ?? 120;
  
  static int get suggestionsTimeoutSeconds => 
      int.tryParse(dotenv.env['SUGGESTIONS_TIMEOUT_SECONDS'] ?? '') ?? 120;
  
  static int get apiTimeoutSeconds => 
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '') ?? 60;

  // Server Configuration
  static int get port => 
      int.tryParse(dotenv.env['PORT'] ?? '') ?? 3000;

  /// Get current backend URL based on environment
  static String get currentBackendUrl {
    switch (apiEnvironment) {
      case 'staging':
        return stagingBackendUrl;
      case 'production':
        return productionBackendUrl;
      case 'development':
      default:
        return developmentBackendUrl;
    }
  }

  /// Update environment variable at runtime
  static void setEnvironmentVariable(String key, String value) {
    dotenv.env[key] = value;
  }

  /// Get environment variable with fallback
  static String getenv(String key, [String fallback = '']) {
    return dotenv.env[key] ?? fallback;
  }

  /// Check if we're in development mode
  static bool get isDevelopment => apiEnvironment == 'development';
  static bool get isStaging => apiEnvironment == 'staging';
  static bool get isProduction => apiEnvironment == 'production';

  /// Print current configuration for debugging
  static void printConfig() {
    print('🌍 Environment Configuration:');
    print('   Environment: $apiEnvironment');
    print('   Backend URL: $currentBackendUrl');
    print('   Is Development: $isDevelopment');
    print('   Chat Timeout: ${chatTimeoutSeconds}s');
    print('   API Timeout: ${apiTimeoutSeconds}s');
    print('   OpenRouter API Key: ${openRouterApiKey.isEmpty ? 'Not Set' : 'Set (${openRouterApiKey.length} chars)'}');
  }

  /// Validate required environment variables
  static bool validateRequired() {
    final required = <String, String>{
      'DEVELOPMENT_BACKEND_URL': developmentBackendUrl,
      'PRODUCTION_BACKEND_URL': productionBackendUrl,
    };

    bool isValid = true;
    for (final entry in required.entries) {
      if (entry.value.isEmpty) {
        print('❌ Missing required environment variable: ${entry.key}');
        isValid = false;
      }
    }

    // Warn about missing optional but recommended variables
    if (openRouterApiKey.isEmpty) {
      print('⚠️ OpenRouter API key not set - AI features may not work');
    }

    if (isValid) {
      print('✅ All required environment variables are set');
    }

    return isValid;
  }

  /// Quick environment switching for testing
  static void switchToEnvironment(String environment) {
    setEnvironmentVariable('API_ENVIRONMENT', environment);
    print('🔄 Switched to $environment environment');
    print('🔗 New Backend URL: $currentBackendUrl');
  }

  /// Get all environment URLs for display
  static Map<String, String> get allUrls => {
    'development': developmentBackendUrl,
    'staging': stagingBackendUrl,
    'production': productionBackendUrl,
  };
}

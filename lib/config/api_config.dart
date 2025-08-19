import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  development,
  staging,
  production,
}

class ApiConfig {
  // Fallback URLs if environment variables are not available
  static const String _fallbackDevelopmentUrl = 'http://localhost:3000';
  static const String _fallbackStagingUrl = 'https://aitalkenglish-staging.onrender.com';
  static const String _fallbackProductionUrl = 'https://aitalkenglish-coplilot-backend.onrender.com';
  
  // Backend URLs from environment variables or fallbacks
  static String get developmentBackendUrl => 
      dotenv.env['DEVELOPMENT_BACKEND_URL'] ?? _fallbackDevelopmentUrl;
  static String get stagingBackendUrl => 
      dotenv.env['STAGING_BACKEND_URL'] ?? _fallbackStagingUrl;
  static String get productionBackendUrl => 
      dotenv.env['PRODUCTION_BACKEND_URL'] ?? _fallbackProductionUrl;
  
  // Get current environment from environment variable or fallback to development
  static Environment get currentEnvironment {
    final envString = dotenv.env['API_ENVIRONMENT']?.toLowerCase() ?? 'development';
    switch (envString) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      case 'development':
      default:
        return Environment.development;
    }
  }
  
  // Default timeout settings (in seconds) - can be overridden by environment variables
  static const int _defaultChatTimeoutSeconds = 120; // 2 minutes
  static const int _defaultSuggestionsTimeoutSeconds = 120; // 2 minutes
  static const int _defaultGeneralTimeoutSeconds = 60; // 1 minute
  
  // Get base URL based on current environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return developmentBackendUrl;
      case Environment.staging:
        return stagingBackendUrl;
      case Environment.production:
        return productionBackendUrl;
    }
  }
  
  // Get environment name for debugging
  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.development:
        return 'Development (Local)';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
  
  // Check if we're in development mode
  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isProduction => currentEnvironment == Environment.production;
  
  // Debug settings based on environment
  static bool get enableDebugLogging => !isProduction;
  static bool get enableDebugBanner => isDevelopment;
  
  // Timeout configurations with environment variable support
  static Duration get chatTimeout {
    // Try to get from environment variable, fallback to default
    final timeoutFromEnv = dotenv.env['CHAT_TIMEOUT_SECONDS'];
    if (timeoutFromEnv != null && timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultChatTimeoutSeconds);
  }
  
  static Duration get suggestionsTimeout {
    // Try to get from environment variable, fallback to default
    final timeoutFromEnv = dotenv.env['SUGGESTIONS_TIMEOUT_SECONDS'];
    if (timeoutFromEnv != null && timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultSuggestionsTimeoutSeconds);
  }
  
  static Duration get generalApiTimeout {
    // Try to get from environment variable, fallback to default
    final timeoutFromEnv = dotenv.env['API_TIMEOUT_SECONDS'];
    if (timeoutFromEnv != null && timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultGeneralTimeoutSeconds);
  }
  
  // Legacy timeout for backward compatibility
  static Duration get apiTimeout => generalApiTimeout;
  
  // Print current configuration (for debugging)
  static void printConfig() {
    print('🌍 Environment: ${environmentName}');
    print('🔗 Backend URL: ${baseUrl}');
    print('⚙️ Debug Logging: ${enableDebugLogging}');
    print('⏱️ Chat Timeout: ${chatTimeout.inSeconds}s');
    print('⏱️ Suggestions Timeout: ${suggestionsTimeout.inSeconds}s');
    print('⏱️ General API Timeout: ${generalApiTimeout.inSeconds}s');
  }
  
  // Get OpenRouter API Key from environment
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  
  // Check if environment variables are loaded
  static bool get isEnvLoaded => dotenv.isInitialized;
  
  // Force reload environment variables
  static Future<void> reloadEnv() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ Environment variables reloaded successfully');
    } catch (e) {
      print('❌ Failed to reload environment variables: $e');
    }
  }
  
  // Get all environment URLs for easy switching
  static Map<Environment, String> get environmentUrls => {
    Environment.development: developmentBackendUrl,
    Environment.staging: stagingBackendUrl,
    Environment.production: productionBackendUrl,
  };
  
  // Set environment programmatically (for testing or dynamic switching)
  static void setEnvironment(Environment environment) {
    final envString = environment.toString().split('.').last;
    dotenv.env['API_ENVIRONMENT'] = envString;
    print('🔄 Environment switched to: ${environmentName}');
    print('🔗 New Backend URL: ${baseUrl}');
  }
}

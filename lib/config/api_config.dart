enum Environment {
  development,
  staging,
  production,
}

class ApiConfig {
  // Backend URLs for different environments
  static const String developmentBackendUrl = 'http://localhost:3000';
  static const String stagingBackendUrl = 'https://aitalkenglish-staging.onrender.com';
  static const String productionBackendUrl = 'https://aitalkenglish-coplilot-backend.onrender.com';
  
  // Current environment - Change this to switch environments
  static const Environment currentEnvironment = Environment.production;
  
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
    const timeoutFromEnv = String.fromEnvironment(
      'CHAT_TIMEOUT_SECONDS',
      defaultValue: '',
    );
    if (timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultChatTimeoutSeconds);
  }
  
  static Duration get suggestionsTimeout {
    // Try to get from environment variable, fallback to default
    const timeoutFromEnv = String.fromEnvironment(
      'SUGGESTIONS_TIMEOUT_SECONDS',
      defaultValue: '',
    );
    if (timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultSuggestionsTimeoutSeconds);
  }
  
  static Duration get generalApiTimeout {
    // Try to get from environment variable, fallback to default
    const timeoutFromEnv = String.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: '',
    );
    if (timeoutFromEnv.isNotEmpty) {
      final timeoutSeconds = int.tryParse(timeoutFromEnv);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        return Duration(seconds: timeoutSeconds);
      }
    }
    return const Duration(seconds: _defaultGeneralTimeoutSeconds);
  }
  
  // Legacy timeout for backward compatibility
  static Duration get apiTimeout => generalApiTimeout;
  
  // Quick environment switchers for testing
  static const Map<Environment, String> environmentUrls = {
    Environment.development: developmentBackendUrl,
    Environment.staging: stagingBackendUrl,
    Environment.production: productionBackendUrl,
  };
  
  // Print current configuration (for debugging)
  static void printConfig() {
    print('🌍 Environment: ${environmentName}');
    print('🔗 Backend URL: ${baseUrl}');
    print('⚙️ Debug Logging: ${enableDebugLogging}');
    print('⏱️ Chat Timeout: ${chatTimeout.inSeconds}s');
    print('⏱️ Suggestions Timeout: ${suggestionsTimeout.inSeconds}s');
    print('⏱️ General API Timeout: ${generalApiTimeout.inSeconds}s');
  }
}

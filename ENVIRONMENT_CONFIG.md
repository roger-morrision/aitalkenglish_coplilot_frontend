# Frontend App Environment Configuration Guide

## Overview
This guide explains how to configure backend API endpoints and environment settings for the Flutter frontend application.

## Environment Variables Setup

### 1. Environment File (.env)
The app uses a `.env` file to store configuration variables. This file is already configured with the following structure:

```properties
# Backend API URLs for different environments
DEVELOPMENT_BACKEND_URL=http://localhost:3000
STAGING_BACKEND_URL=https://aitalkenglish-staging.onrender.com
PRODUCTION_BACKEND_URL=https://aitalkenglish-coplilot-backend.onrender.com

# Current environment (development, staging, production)
API_ENVIRONMENT=development

# API Keys
OPENROUTER_API_KEY=your-api-key-here

# Timeout Configuration
CHAT_TIMEOUT_SECONDS=120
SUGGESTIONS_TIMEOUT_SECONDS=120
API_TIMEOUT_SECONDS=60

# Server Configuration
PORT=3000
```

### 2. Environment Configuration Classes

#### EnvConfig (`lib/config/env_config.dart`)
- Loads and manages environment variables from .env file
- Provides easy access to configuration values with fallbacks
- Includes validation and debugging utilities

#### ApiConfig (`lib/config/api_config.dart`)
- Manages API configuration and timeouts
- Automatically selects backend URL based on environment
- Integrates with EnvConfig for environment variable support

## Usage Examples

### Basic Usage
```dart
import 'package:your_app/config/env_config.dart';

// Get current backend URL
String backendUrl = EnvConfig.currentBackendUrl;

// Check environment
if (EnvConfig.isDevelopment) {
  print('Running in development mode');
}

// Get timeout values
int chatTimeout = EnvConfig.chatTimeoutSeconds;
```

### API Service Usage
```dart
import 'package:your_app/config/api_config.dart';
import 'package:http/http.dart' as http;

// Make API calls using configured settings
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/endpoint'),
).timeout(ApiConfig.generalApiTimeout);
```

### Runtime Environment Switching (Debug Mode)
```dart
import 'package:your_app/config/env_config.dart';

// Switch to staging environment
EnvConfig.switchToEnvironment('staging');

// Print current configuration
EnvConfig.printConfig();

// Validate configuration
bool isValid = EnvConfig.validateRequired();
```

## Environment Settings UI

### Access Environment Settings
1. Go to Settings screen in the app
2. Look for "Developer Settings" section (only visible in debug mode)
3. Tap "Environment Settings" button

### Environment Settings Features
- **View Current Configuration**: See active environment and backend URL
- **Switch Environments**: Change between development, staging, and production (debug mode only)
- **API Configuration**: View timeout settings and other API parameters
- **Environment URLs**: Display all configured backend URLs
- **Debug Actions**: Print config to console, validate settings, reload environment

## Configuration Management

### 1. Changing Backend URLs
Update the `.env` file with your backend URLs:
```properties
DEVELOPMENT_BACKEND_URL=http://your-local-backend:3000
STAGING_BACKEND_URL=https://your-staging-backend.com
PRODUCTION_BACKEND_URL=https://your-production-backend.com
```

### 2. Switching Environments
**Method 1: Environment Variable**
```properties
API_ENVIRONMENT=production  # Change this in .env file
```

**Method 2: Runtime (Debug Mode)**
```dart
EnvConfig.switchToEnvironment('production');
```

**Method 3: UI Settings (Debug Mode)**
- Open Environment Settings screen
- Select desired environment from radio buttons

### 3. Configuring Timeouts
Adjust timeout values in `.env`:
```properties
CHAT_TIMEOUT_SECONDS=180    # 3 minutes for chat responses
SUGGESTIONS_TIMEOUT_SECONDS=120  # 2 minutes for suggestions
API_TIMEOUT_SECONDS=90      # 1.5 minutes for general API calls
```

### 4. API Keys
Set your API keys in `.env`:
```properties
OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
```

## Production Deployment

### 1. Set Production Environment
```properties
API_ENVIRONMENT=production
PRODUCTION_BACKEND_URL=https://your-production-backend.com
```

### 2. Secure API Keys
- Never commit real API keys to version control
- Use environment-specific configuration files
- Consider using CI/CD secrets for production builds

### 3. Disable Debug Features
Debug features (environment switching UI) are automatically hidden in production builds.

## Troubleshooting

### Common Issues
1. **Environment not loading**: Check if `.env` file is in assets folder in pubspec.yaml
2. **API calls failing**: Verify backend URL is correct and accessible
3. **Timeout errors**: Increase timeout values in environment configuration

### Debug Tools
```dart
// Print all configuration
EnvConfig.printConfig();
ApiConfig.printConfig();

// Validate required variables
bool isValid = EnvConfig.validateRequired();

// Check if environment is loaded
bool loaded = EnvConfig.isLoaded;
```

### Logging
The app automatically logs configuration details in debug mode:
```
🌍 Environment Configuration:
   Environment: development
   Backend URL: http://localhost:3000
   Is Development: true
   Chat Timeout: 120s
   API Timeout: 60s
   OpenRouter API Key: Set (45 chars)
```

## Security Notes

### Environment Variables
- Keep sensitive data in environment variables, not hardcoded
- Use different API keys for different environments
- Regularly rotate API keys

### Access Control
- Environment switching is only available in debug mode
- Production builds automatically hide developer settings
- Validate all environment variables on app startup

## Best Practices

### Development
1. Use local backend URL for development
2. Keep development API keys separate from production
3. Test with different environments before deployment

### Production
1. Use HTTPS URLs for all production backends
2. Set appropriate timeout values for production load
3. Monitor API usage and adjust rate limits accordingly

### Maintenance
1. Regularly update backend URLs as needed
2. Keep environment configuration documentation up to date
3. Test configuration changes in staging before production

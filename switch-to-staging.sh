#!/bin/bash
echo "🔄 Switching to Staging Environment"
echo "===================================="

# Update environment in config
sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.staging/" lib/config/api_config.dart

echo "✅ Environment switched to Staging"
echo "🔗 Backend URL: https://aitalkenglish-staging.onrender.com"
echo ""
echo "💡 To test:"
echo "   flutter run -d chrome --web-port 8082"
echo ""
echo "📋 Current configuration:"
grep -A 1 "currentEnvironment" lib/config/api_config.dart

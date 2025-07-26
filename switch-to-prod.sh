#!/bin/bash
echo "🔄 Switching to Production Environment"
echo "======================================="

# Update environment in config
sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.production/" lib/config/api_config.dart

echo "✅ Environment switched to Production"
echo "🔗 Backend URL: https://aitalkenglish-coplilot-backend.onrender.com"
echo ""
echo "💡 To test:"
echo "   flutter run -d chrome --web-port 8082"
echo ""
echo "📋 Current configuration:"
grep -A 1 "currentEnvironment" lib/config/api_config.dart

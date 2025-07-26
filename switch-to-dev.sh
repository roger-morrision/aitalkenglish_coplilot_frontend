#!/bin/bash
echo "🔄 Switching to Development Environment (localhost:3000)"
echo "========================================================="

# Update environment in config
sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.development/" lib/config/api_config.dart

echo "✅ Environment switched to Development"
echo "🔗 Backend URL: http://localhost:3000"
echo ""
echo "💡 To test:"
echo "   1. Start local backend: node backend-server.js"
echo "   2. Start Flutter: flutter run -d chrome --web-port 8082"
echo ""
echo "📋 Current configuration:"
grep -A 1 "currentEnvironment" lib/config/api_config.dart

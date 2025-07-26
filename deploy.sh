#!/bin/bash

echo "🚀 AI Talk English - Production Deployment Script"
echo "=================================================="

# Check if backend URL is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide your deployed backend URL"
    echo "Usage: ./deploy.sh https://your-backend-url.onrender.com"
    exit 1
fi

BACKEND_URL=$1
echo "🔗 Backend URL: $BACKEND_URL"

# Update API configuration
echo "📝 Updating API configuration..."
sed -i "s|https://your-backend-url.onrender.com|$BACKEND_URL|g" lib/config/api_config.dart
sed -i "s|static const bool useProduction = false|static const bool useProduction = true|g" lib/config/api_config.dart

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️ Building for web (production)..."
flutter build web --release

echo "📂 Copying to web_deploy..."
rm -rf web_deploy/*
cp -r build/web/* web_deploy/

echo "📋 Git status:"
git status

echo "✅ Build complete! Next steps:"
echo "1. Review changes: git diff"
echo "2. Commit: git add . && git commit -m 'feat: update for production backend'"
echo "3. Deploy: git push origin main"
echo ""
echo "🌐 Your app will be available at:"
echo "   https://roger-morrision.github.io/aitalkenglish_coplilot_frontend/web_deploy/"
echo ""
echo "🔗 Backend running at: $BACKEND_URL"

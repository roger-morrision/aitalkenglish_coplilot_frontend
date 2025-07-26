#!/bin/bash

echo "🚀 AI Talk English - Multi-Environment Deployment Script"
echo "========================================================"

# Show usage if no environment specified
if [ -z "$1" ]; then
    echo "❌ Error: Please specify environment"
    echo ""
    echo "Usage: ./deploy.sh <environment> [backend-url]"
    echo ""
    echo "Environments:"
    echo "  dev        - Development (localhost:3000)"
    echo "  staging    - Staging environment"
    echo "  prod       - Production environment"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh dev"
    echo "  ./deploy.sh staging https://your-staging-backend.onrender.com"
    echo "  ./deploy.sh prod https://aitalkenglish-coplilot-backend.onrender.com"
    exit 1
fi

ENVIRONMENT=$1
BACKEND_URL=$2

# Set environment and backend URL
case $ENVIRONMENT in
    "dev")
        ENV_NAME="development"
        DEFAULT_BACKEND="http://localhost:3000"
        ;;
    "staging")
        ENV_NAME="staging"
        DEFAULT_BACKEND="https://aitalkenglish-staging.onrender.com"
        ;;
    "prod")
        ENV_NAME="production"
        DEFAULT_BACKEND="https://aitalkenglish-coplilot-backend.onrender.com"
        ;;
    *)
        echo "❌ Error: Invalid environment '$ENVIRONMENT'"
        echo "Valid environments: dev, staging, prod"
        exit 1
        ;;
esac

# Use provided backend URL or default
if [ -n "$BACKEND_URL" ]; then
    FINAL_BACKEND_URL=$BACKEND_URL
else
    FINAL_BACKEND_URL=$DEFAULT_BACKEND
fi

echo "🌍 Environment: $ENV_NAME"
echo "🔗 Backend URL: $FINAL_BACKEND_URL"
echo ""

# Update API configuration
echo "📝 Updating API configuration..."
if [ "$ENV_NAME" = "development" ]; then
    sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.development/" lib/config/api_config.dart
elif [ "$ENV_NAME" = "staging" ]; then
    sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.staging/" lib/config/api_config.dart
    sed -i "s|static const String stagingBackendUrl = '[^']*'|static const String stagingBackendUrl = '$FINAL_BACKEND_URL'|" lib/config/api_config.dart
else
    sed -i "s/static const Environment currentEnvironment = Environment\.[^;]*/static const Environment currentEnvironment = Environment.production/" lib/config/api_config.dart
    sed -i "s|static const String productionBackendUrl = '[^']*'|static const String productionBackendUrl = '$FINAL_BACKEND_URL'|" lib/config/api_config.dart
fi

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️ Building for web ($ENV_NAME)..."
flutter build web --release

echo "📂 Copying to web_deploy..."
rm -rf web_deploy/*
cp -r build/web/* web_deploy/

echo ""
echo "📋 Current configuration:"
grep -A 1 "currentEnvironment" lib/config/api_config.dart
echo ""

echo "📊 Git status:"
git status --porcelain

echo ""
echo "✅ Build complete for $ENV_NAME environment!"
echo ""
echo "Next steps:"
echo "1. Test locally: flutter run -d chrome --web-port 8082"
echo "2. Review changes: git diff lib/config/api_config.dart"
echo "3. Commit: git add . && git commit -m 'feat: deploy to $ENV_NAME environment'"
echo "4. Deploy: git push origin main"
echo ""
echo "🌐 Frontend will be available at:"
echo "   https://roger-morrision.github.io/aitalkenglish_coplilot_frontend/web_deploy/"
echo ""
echo "🔗 Backend: $FINAL_BACKEND_URL"

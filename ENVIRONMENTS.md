# 🌍 Multi-Environment Configuration Guide

This AI Talk English app supports three environments for easy development, testing, and deployment.

## 📋 Available Environments

### 🟢 Development (Local)
- **Backend URL**: `http://localhost:3000`
- **Usage**: Local development and testing
- **Features**: Debug logging, environment banner, full debugging tools
- **Requirements**: Local backend server running

### 🟡 Staging 
- **Backend URL**: `https://aitalkenglish-staging.onrender.com`
- **Usage**: Testing before production deployment
- **Features**: Debug logging, environment banner, production-like testing
- **Requirements**: Staging backend deployed

### 🔴 Production
- **Backend URL**: `https://aitalkenglish-coplilot-backend.onrender.com`
- **Usage**: Live app for end users
- **Features**: No debug info, optimized performance, clean UI
- **Requirements**: Production backend deployed and stable

## 🔧 Quick Environment Switching

### Method 1: Simple Scripts
```bash
# Switch to development (localhost)
./switch-to-dev.sh

# Switch to staging
./switch-to-staging.sh

# Switch to production
./switch-to-prod.sh
```

### Method 2: Advanced Deployment
```bash
# Deploy to specific environment
./deploy.sh dev                    # Development
./deploy.sh staging [backend-url]  # Staging (optional custom URL)
./deploy.sh prod [backend-url]     # Production (optional custom URL)
```

### Method 3: Manual Configuration
Edit `lib/config/api_config.dart`:
```dart
// Change this line to switch environments
static const Environment currentEnvironment = Environment.development; // or staging, production
```

## 📱 Environment Features

### Development Mode
- ✅ Green environment banner visible
- ✅ Debug information in Settings
- ✅ Console logging enabled
- ✅ 10-second API timeout
- ✅ Print configuration option

### Staging Mode  
- ✅ Orange environment banner visible
- ✅ Debug information in Settings
- ✅ Console logging enabled
- ✅ 15-second API timeout
- ✅ Print configuration option

### Production Mode
- ❌ No environment banner
- ❌ No debug information
- ❌ No console logging
- ✅ 20-second API timeout (more tolerant)
- ❌ No debug options

## 🚀 Deployment Workflows

### Local Development
1. Start backend: `node backend-server.js`
2. Switch to dev: `./switch-to-dev.sh`
3. Run Flutter: `flutter run -d chrome --web-port 8082`
4. Test features locally

### Staging Testing
1. Deploy backend to staging environment
2. Switch to staging: `./switch-to-staging.sh`
3. Run Flutter: `flutter run -d chrome --web-port 8082`
4. Test with staging backend

### Production Deployment
1. Ensure production backend is stable
2. Deploy to production: `./deploy.sh prod`
3. Commit and push: `git add . && git commit -m "deploy: production" && git push`
4. Access at: https://roger-morrision.github.io/aitalkenglish_coplilot_frontend/web_deploy/

## 🔍 Environment Detection

The app automatically detects and displays the current environment:

- **Visual Indicators**: Environment banner (dev/staging only)
- **Debug Info**: Available in Settings screen (dev/staging only)
- **Console Logs**: Environment configuration printed to browser console
- **API Behavior**: Different timeouts and error handling per environment

## 🛠️ Customization

### Adding New Environments
1. Add to enum in `lib/config/api_config.dart`:
```dart
enum Environment {
  development,
  staging,
  testing,     // New environment
  production,
}
```

2. Add URL in ApiConfig class:
```dart
static const String testingBackendUrl = 'https://your-testing-backend.com';
```

3. Update switch statements to handle new environment

### Custom Backend URLs
Override default URLs during deployment:
```bash
./deploy.sh staging https://my-custom-staging-backend.herokuapp.com
./deploy.sh prod https://my-custom-production-backend.vercel.app
```

## 📊 Environment Status

Check current configuration anytime:
- Look for environment banner (dev/staging)
- Check Settings screen for debug info
- Run `ApiConfig.printConfig()` in console
- Check browser network tab for backend requests

## 🔒 Security Notes

- **API Keys**: Always use environment variables for sensitive data
- **CORS**: Backend configured to allow all origins (adjust for production security)
- **Debug Info**: Automatically hidden in production mode
- **Logging**: Sensitive data should never be logged in any environment

## 📞 Environment Testing Checklist

### ✅ Before Switching Environments
- [ ] Confirm target backend is running and accessible
- [ ] Check API key is configured in target backend
- [ ] Verify CORS settings allow your frontend domain

### ✅ After Environment Switch
- [ ] Environment banner shows correct environment (dev/staging only)
- [ ] Settings screen shows correct backend URL
- [ ] Chat functionality works with target backend
- [ ] AI model selection works
- [ ] Voice settings sync properly
- [ ] No console errors related to network requests

This configuration system makes it easy to develop locally, test in staging, and deploy to production with confidence! 🎉

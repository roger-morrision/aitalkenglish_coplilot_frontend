# AI Talk English Backend Deployment Guide

## 🚀 Quick Deployment Options

### Option 1: Render (Recommended - Free)

1. **Sign up**: Go to [render.com](https://render.com) and sign up with GitHub
2. **New Web Service**: Click "New" → "Web Service"
3. **Connect Repository**: Select `aitalkenglish_coplilot_frontend`
4. **Configure**:
   - **Name**: `aitalkenglish-backend`
   - **Region**: Choose closest to you
   - **Branch**: `main`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node backend-server.js`
   - **Plan**: `Free`

5. **Environment Variables**:
   - `OPENROUTER_API_KEY`: Your OpenRouter API key
   - `NODE_ENV`: `production`

6. **Deploy**: Click "Create Web Service"

Your backend will be at: `https://aitalkenglish-backend.onrender.com`

### Option 2: Railway (Free)

1. **Sign up**: Go to [railway.app](https://railway.app)
2. **New Project**: "Deploy from GitHub repo"
3. **Select**: `aitalkenglish_coplilot_frontend`
4. **Auto-deploy**: Railway will detect Node.js and deploy automatically
5. **Environment Variables**: Add `OPENROUTER_API_KEY` in settings

### Option 3: Netlify Functions (Serverless)

1. **Sign up**: Go to [netlify.com](https://netlify.com)
2. **Deploy**: Connect GitHub repo for frontend
3. **Functions**: Move backend logic to `netlify/functions/`

## 🔧 Update Frontend for Production

After deploying your backend:

1. **Edit**: `lib/config/api_config.dart`
2. **Update**: Change `productionBackendUrl` to your deployed URL
3. **Switch**: Set `useProduction = true`
4. **Rebuild**: `flutter build web --release`
5. **Deploy**: Update GitHub Pages

## 📱 GitHub Pages + Backend Setup

```bash
# 1. Deploy backend to Render/Railway
# 2. Get your backend URL (e.g., https://your-app.onrender.com)
# 3. Update Flutter config
# 4. Rebuild and deploy

# Update Flutter config
cd lib/config/
# Edit api_config.dart with your backend URL

# Rebuild Flutter
flutter clean
flutter build web --release
cp -r build/web/* web_deploy/
git add .
git commit -m "feat: update for production backend"
git push origin main
```

## 🌐 Access Your Deployed App

- **Frontend**: `https://roger-morrision.github.io/aitalkenglish_coplilot_frontend/web_deploy/`
- **Backend**: Your deployed backend URL
- **Full Stack**: Frontend calls backend via HTTPS

## 🔒 Security Notes

- Backend already has CORS enabled for all origins
- Add your frontend domain to CORS whitelist for production
- Keep API keys in environment variables only

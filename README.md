# 🎯 AI Talk English - AI-Powered English Learning App

A comprehensive Flutter-based English learning application featuring AI conversation, grammar checking, vocabulary building, and pronunciation practice.

## ✨ Features

### 🤖 AI Chat Tutor
- **Interactive Conversations**: Practice English with an AI tutor
- **Real-time Feedback**: Get instant grammar and vocabulary suggestions
- **Voice Input**: Speak your messages using speech-to-text
- **Audio Playback**: Click 🔊 icons to replay any AI response or suggestion
- **Smart Suggestions**: Toggle AI insights on/off to save tokens

### 🔊 Audio Learning System
- **Manual Audio Controls**: Click volume icons to replay any text
- **Pronunciation Practice**: Hear AI responses, grammar fixes, and vocabulary
- **No Interference Design**: Manual audio doesn't conflict with voice input
- **Multi-level Audio**: 
  - AI response playback
  - Grammar correction audio
  - Vocabulary word pronunciation
  - Example sentence audio
  - Alternative expression audio

### 📚 Grammar & Vocabulary Tools
- **Grammar Checker**: Real-time grammar analysis and correction
- **Vocabulary Builder**: Learn new words with definitions and examples
- **Better Expressions**: Get alternative ways to say things
- **Contextual Learning**: See words used in real sentences

### 🗣️ Voice Features
- **Speech-to-Text**: Talk instead of typing
- **Text-to-Speech**: Automatic audio playback of AI responses
- **Voice Settings**: Configure voice input and autoplay preferences
- **Pronunciation Training**: Replay any text for pronunciation practice

## 🌍 Multi-Environment Support

### Environment Configuration
- **Development**: `http://localhost:3000` (local backend)
- **Staging**: `https://aitalkenglish-staging.onrender.com`
- **Production**: `https://aitalkenglish-coplilot-backend.onrender.com`

### Quick Environment Switching
```bash
# Switch to development
./switch-to-dev.sh

# Switch to staging  
./switch-to-staging.sh

# Switch to production
./switch-to-prod.sh
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Web browser (Chrome recommended)
- Backend API access

### Installation
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aitalkenglish_coplilot_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   # For production (default)
   ./switch-to-prod.sh
   
   # For local development
   ./switch-to-dev.sh
   ```

4. **Run the application**
   ```bash
   flutter run -d chrome
   ```

### Building for Production
```bash
# Build web application
flutter build web --release

# Deploy with environment configuration
./deploy.sh production
```

## 📱 App Structure

### Main Features
- **🏠 Home**: Welcome screen and navigation
- **💬 Chat**: AI conversation tutor with audio features
- **📖 Grammar**: Text analysis and grammar checking
- **📚 Vocabulary**: Word learning and flashcards
- **📊 Progress**: Learning analytics and achievements
- **⚙️ Settings**: Voice and AI model configuration

### Audio System Architecture
```
Manual Audio (AudioPlayButton)
├── Separate TTS instance (_manualTts)
├── No interference with auto voice listening  
├── Play/stop controls with visual feedback
└── Smart text cleaning for natural speech

Auto Voice Features
├── Speech-to-text for message input
├── Auto-play for AI responses  
├── Voice settings configuration
└── Independent from manual audio system
```

## 🔧 Configuration

### Voice Settings
- **Voice Input**: Enable/disable speech-to-text
- **Auto-play**: Automatic audio for AI responses
- **Manual Audio**: Click-to-play for any text content

### AI Settings
- **Model Selection**: Choose AI model for responses
- **Suggestions**: Toggle grammar/vocabulary insights
- **Token Management**: Control AI usage and costs

### Environment Settings
Located in `lib/config/api_config.dart`:
```dart
// Change environment by modifying this line
static const Environment currentEnvironment = Environment.production;
```

## 🎯 Audio Features Guide

### 🔊 Where to Find Audio Icons

1. **AI Chat Responses**: Next to every AI message
2. **Grammar Corrections**: In grammar fix suggestions  
3. **Better Versions**: Next to alternative expressions
4. **Vocabulary Words**: Next to each new word
5. **Example Sentences**: Next to vocabulary examples

### How Audio Works
- **Click 🔊**: Starts audio playback
- **Click ⏹️**: Stops current audio
- **Auto-stop**: New audio stops previous audio
- **No Conflicts**: Works alongside voice input features

## 📚 Learning Workflow

### Typical Session
1. **Start Conversation**: Type or speak a message
2. **Get AI Response**: Receive feedback and suggestions
3. **Practice Pronunciation**: Click audio icons to replay content
4. **Learn Vocabulary**: Hear new words and examples
5. **Try Better Expressions**: Listen to alternative phrasings
6. **Apply Grammar**: Hear corrected grammar structures

### Advanced Features
- **Toggle Suggestions**: Save AI tokens by disabling detailed insights
- **Voice-only Practice**: Use speech input + audio output for speaking practice
- **Multi-modal Learning**: Combine reading, listening, and speaking

## 🔄 Development Workflow

### Environment Management
```bash
# Check current environment
flutter run --dart-define-from-file=config/current_env.json

# Switch environments
./switch-to-dev.sh    # Development
./switch-to-staging.sh # Staging  
./switch-to-prod.sh   # Production
```

### Building & Testing
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Build for web
flutter build web --release
```

## 📖 Documentation

- **[Audio Features Guide](AUDIO_FEATURES.md)**: Detailed audio system documentation
- **[Environment Setup](ENVIRONMENTS.md)**: Multi-environment configuration guide
- **[API Integration](lib/services/api_service.dart)**: Backend communication details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- AI model providers for language learning capabilities
- Open source audio libraries for TTS functionality

---

**Happy Learning! 🎓🗣️**

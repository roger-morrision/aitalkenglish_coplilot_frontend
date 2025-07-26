import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/api_service.dart';
import '../settings/settings_screen.dart';
import '../../widgets/audio_player.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _lastWords = '';
  late AnimationController _micAnimationController;
  bool _isTyping = false;
  bool _isBackendConnected = true;
  bool _isSuggestionsEnabled = true; // New setting for suggestions panel
  final Set<int> _loadingSuggestions = {}; // Track which messages are loading suggestions
  
  // Voice settings
  bool _voiceAutoplayEnabled = true;
  bool _voiceInputEnabled = true;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _micAnimationController.repeat();
    _loadVoiceSettings();
  }

  Future<void> _loadVoiceSettings() async {
    try {
      final voiceSettings = await ApiService.getVoiceSettings();
      setState(() {
        _voiceAutoplayEnabled = voiceSettings['voice_autoplay_enabled'] ?? true;
        _voiceInputEnabled = voiceSettings['voice_input_enabled'] ?? true;
      });
    } catch (e) {
      print('Error loading voice settings: $e');
      // Keep default values if loading fails
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMessage = _ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    
    final aiResponse = await _getAIResponse(text);
    
    // Show AI response immediately with optimistic loading placeholder
    final aiMessageIndex = _messages.length;
    
    // Create placeholder suggestions to show immediately
    final placeholderSuggestions = _MessageSuggestions(
      grammarFix: 'Analyzing grammar...',
      betterVersions: [
        'Finding alternative expressions...',
        'Generating better versions...',
      ],
      vocabulary: [
        _VocabularyItem(
          word: 'Loading...', 
          meaning: 'Analyzing vocabulary...', 
          example: 'Finding relevant examples...'
        )
      ],
    );
    
    setState(() {
      _messages.add(_ChatMessage(
        text: aiResponse, 
        isUser: false, 
        suggestions: _isSuggestionsEnabled ? placeholderSuggestions : null
      ));
      _isTyping = false;
      // Start loading suggestions for this message
      if (_isSuggestionsEnabled) {
        _loadingSuggestions.add(aiMessageIndex);
      }
    });
    _scrollToBottom();
    
    // Auto-play AI response if enabled
    if (_voiceAutoplayEnabled) {
      await _tts.speak(aiResponse);
    }
    
    // Get suggestions for the user's message asynchronously if enabled
    if (_isSuggestionsEnabled) {
      try {
        print('Chatbot: Requesting suggestions for message: $text');
        final suggestionsData = await ApiService.getMessageSuggestions(text);
        print('Chatbot: Received suggestions: $suggestionsData');
        final suggestions = _MessageSuggestions.fromJson(suggestionsData);
        print('Chatbot: Suggestions parsed: ${suggestions.grammarFix}');
        
        // Update the AI message with suggestions by replacing it
        setState(() {
          _messages[aiMessageIndex] = _ChatMessage(
            text: aiResponse, 
            isUser: false, 
            suggestions: suggestions
          );
          _loadingSuggestions.remove(aiMessageIndex); // Clear loading state
        });
      } catch (e) {
        print('Chatbot: Error getting suggestions: $e');
        // Show error-specific fallback with correct data types
        final errorSuggestions = _MessageSuggestions(
          grammarFix: 'Could not fetch suggestions from server',
          betterVersions: [
            'Error: Unable to get alternative expressions - ${e.toString()}',
            'Try again later when the AI service is available',
            'Check your internet connection'
          ],
          vocabulary: [
            _VocabularyItem(
              word: 'error', 
              meaning: 'A problem or mistake that prevents something from working properly', 
              example: 'There was an error connecting to the suggestion service'
            )
          ],
        );
        
        // Update the AI message with error suggestions by replacing it
        setState(() {
          _messages[aiMessageIndex] = _ChatMessage(
            text: aiResponse, 
            isUser: false, 
            suggestions: errorSuggestions
          );
          _loadingSuggestions.remove(aiMessageIndex); // Clear loading state
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _getAIResponse(String userInput) async {
    try {
      final response = await ApiService.sendChatMessage(userInput);
      if (mounted) {
        setState(() {
          _isBackendConnected = true;
        });
      }
      return response;
    } catch (e) {
      print('Error getting AI response: $e');
      if (mounted) {
        setState(() {
          _isBackendConnected = false;
        });
      }
      return "I'm sorry, I'm having trouble connecting to the server right now. Please try again in a moment.";
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_lastWords.isNotEmpty) {
      _sendMessage(_lastWords);
      _lastWords = '';
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Chat Settings'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Suggestions Panel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isSuggestionsEnabled,
                        onChanged: (value) {
                          setDialogState(() {
                            _isSuggestionsEnabled = value;
                          });
                          setState(() {
                            _isSuggestionsEnabled = value;
                          });
                        },
                        activeColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSuggestionsEnabled 
                                ? 'Suggestions enabled: Each message will get grammar & vocabulary insights'
                                : 'Suggestions disabled: Save AI tokens with simple conversation mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Token Usage: ${_isSuggestionsEnabled ? "Higher" : "Lower"} - ${_isSuggestionsEnabled ? "Detailed analysis for each message" : "Basic conversation only"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Clear Chat'),
            ],
          ),
          content: Text(
            'Are you sure you want to clear all chat messages? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chat cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help, color: Colors.blue),
              SizedBox(width: 8),
              Text('Help & Tips'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  Icons.chat,
                  'Chat Features',
                  'Type messages to practice English conversation with AI tutor',
                ),
                SizedBox(height: 12),
                if (_voiceInputEnabled)
                  _buildHelpItem(
                    Icons.mic,
                    'Voice Input',
                    'Tap the microphone to speak your message instead of typing',
                  ),
                if (_voiceInputEnabled)
                  SizedBox(height: 12),
                _buildHelpItem(
                  Icons.lightbulb,
                  'AI Suggestions',
                  'Enable suggestions in settings for grammar tips and vocabulary',
                ),
                SizedBox(height: 12),
                if (_voiceAutoplayEnabled)
                  _buildHelpItem(
                    Icons.volume_up,
                    'Text-to-Speech',
                    'AI responses are automatically spoken aloud for pronunciation practice',
                  ),
                if (_voiceAutoplayEnabled)
                  SizedBox(height: 12),
                _buildHelpItem(
                  Icons.settings,
                  'Voice Settings',
                  'Configure voice features in settings (tap ⋮ → AI Model Settings)',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Fixed Header Bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AI English Tutor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isTyping 
                            ? 'Typing...' 
                            : _isBackendConnected 
                                ? _isSuggestionsEnabled 
                                    ? 'Online • Suggestions ON' 
                                    : 'Online • Suggestions OFF'
                                : 'Connection issues',
                        style: TextStyle(
                          color: _isBackendConnected 
                              ? Colors.white.withOpacity(0.8)
                              : Colors.orange.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'ai_settings') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    } else if (value == 'settings') {
                      _showSettingsDialog();
                    } else if (value == 'clear') {
                      _showClearChatDialog();
                    } else if (value == 'help') {
                      _showHelpDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'ai_settings',
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.deepPurple, size: 20),
                          SizedBox(width: 12),
                          Text('AI Model Settings'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.deepPurple, size: 20),
                          SizedBox(width: 12),
                          Text('Chat Settings'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Text('Clear Chat'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Text('Help & Tips'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Scrollable Chat Body - Now contains everything
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final msgIndex = _isTyping ? index - 1 : index;
                      final actualMessageIndex = _messages.length - 1 - msgIndex;
                      final msg = _messages[actualMessageIndex];
                      return _buildMessageWithSuggestions(msg, actualMessageIndex);
                    },
                  ),
          ),
          
          // Input Form at Bottom - Simplified
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _sendMessage,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Show microphone button only if voice input is enabled
                  if (_voiceInputEnabled) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                        ),
                        onPressed: _isListening ? _stopListening : _startListening,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'m here to help you practice English',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isSuggestionsEnabled ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSuggestionsEnabled ? Colors.green[200]! : Colors.orange[200]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSuggestionsEnabled ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 16,
                  color: _isSuggestionsEnabled ? Colors.green[600] : Colors.orange[600],
                ),
                const SizedBox(width: 6),
                Text(
                  _isSuggestionsEnabled ? 'AI Suggestions: ON' : 'AI Suggestions: OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isSuggestionsEnabled ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• Tap ⋮ to toggle',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI is typing',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWithSuggestions(_ChatMessage message, int messageIndex) {
    return Column(
      children: [
        // Main message bubble
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Colors.deepPurple 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.grey[800],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      // Audio icon for AI responses
                      if (!message.isUser) ...[
                        const SizedBox(width: 8),
                        AudioPlayButton(
                          text: message.text,
                          size: 18,
                          mini: true,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.deepPurple[700],
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Suggestions panel (for AI messages - show loading or actual suggestions)
        if (!message.isUser && (_isSuggestionsEnabled && (_loadingSuggestions.contains(messageIndex) || message.suggestions != null)))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '📚 Grammar & Vocabulary Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _loadingSuggestions.contains(messageIndex) 
                                ? Colors.orange[100] 
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _loadingSuggestions.contains(messageIndex) 
                                ? Colors.orange[300]! 
                                : Colors.green[300]!
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_loadingSuggestions.contains(messageIndex)) ...[
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'LOADING...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'ON',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Tooltip(
                      message: 'Disable in three dots menu to save AI tokens',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Show loading or actual content
                if (_loadingSuggestions.contains(messageIndex)) ...[
                  // Show placeholder content while loading instead of loading indicators
                  
                  // Grammar Fix Section with placeholder
                  Text(
                    '✏️ Grammar Check',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Analyzing grammar patterns...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Better Versions Section with placeholder
                  Text(
                    '💡 Alternative Expressions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generating better alternatives...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Vocabulary Section with placeholder
                  Text(
                    '📖 New Vocabulary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Finding relevant vocabulary...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.purple[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (message.suggestions != null) ...[
                  // Actual suggestions content
                  
                  // Grammar Fix Section
                  if (message.suggestions!.grammarFix.isNotEmpty) ...[
                    Text(
                      '✏️ Grammar Check',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.suggestions!.grammarFix,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AudioPlayButton(
                            text: message.suggestions!.grammarFix,
                            size: 16,
                            mini: true,
                            color: Colors.green[700],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Better Versions Section
                  if (message.suggestions!.betterVersions.isNotEmpty) ...[
                    Text(
                      '💡 Alternative Expressions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...message.suggestions!.betterVersions.asMap().entries.map((entry) => 
                      BetterVersionItem(
                        text: entry.value,
                        index: entry.key,
                      ),
                    ).toList(),
                    const SizedBox(height: 12),
                  ],
                  
                  // Vocabulary Section
                  if (message.suggestions!.vocabulary.isNotEmpty) ...[
                    Text(
                      '📖 New Vocabulary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...message.suggestions!.vocabulary.map((vocab) => 
                      VocabularyAudioItem(
                      word: vocab.word,
                      meaning: vocab.meaning,
                      example: vocab.example,
                    ),
                  ).toList(),
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final _MessageSuggestions? suggestions;
  _ChatMessage({required this.text, required this.isUser, this.suggestions});
}

class _VocabularyItem {
  final String word;
  final String meaning;
  final String example;
  
  _VocabularyItem({required this.word, required this.meaning, required this.example});
  
  factory _VocabularyItem.fromJson(Map<String, dynamic> json) {
    return _VocabularyItem(
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
    );
  }
}

class _MessageSuggestions {
  final String grammarFix;
  final List<String> betterVersions;
  final List<_VocabularyItem> vocabulary;
  
  _MessageSuggestions({
    required this.grammarFix,
    required this.betterVersions,
    required this.vocabulary,
  });
  
  factory _MessageSuggestions.fromJson(Map<String, dynamic> json) {
    return _MessageSuggestions(
      grammarFix: json['grammar_fix']?.toString() ?? '',
      betterVersions: _parseStringList(json['better_versions']),
      vocabulary: _parseVocabularyList(json['vocabulary']),
    );
  }
  
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    if (data is String) {
      return [data];
    }
    return [data.toString()];
  }
  
  static List<_VocabularyItem> _parseVocabularyList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return _VocabularyItem.fromJson(item);
        }
        return _VocabularyItem(word: 'error', meaning: 'Invalid data format', example: item.toString());
      }).toList();
    }
    return [];
  }
}

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../services/progress_service.dart';
import '../../services/conversation_service.dart';
import '../../models/conversation.dart';
import '../settings/settings_screen.dart';
import '../../widgets/audio_player.dart';
import 'conversation_history_screen.dart';
import '../../main.dart'; // Import for WelcomeScreen

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  // Current conversation and messages
  Conversation? _currentConversation;
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
  bool _isLoadingConversation = false;
  
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
    _initTts();
    _loadVoiceSettings();
    _loadActiveConversation();
  }
  
    // New: Load a specific conversation by ID
    Future<void> _loadConversationById(String conversationId) async {
        setState(() => _isLoadingConversation = true);
        try {
            print('Loading conversation ID: $conversationId');
            final conversation = await ConversationService.loadConversation(conversationId);
            if (conversation != null) {
                print('Conversation loaded: ${conversation.title}');
                print('Raw messages count: ${conversation.messages.length}');
                for (int i = 0; i < conversation.messages.length; i++) {
                    final msg = conversation.messages[i];
                    print('Message $i: ${msg.isUser ? "USER" : "AI"} - ${msg.content.length > 50 ? msg.content.substring(0, 50) + "..." : msg.content}');
                }
                
                // Sort messages by timestamp ascending
                final sortedMessages = List.of(conversation.messages)
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                
                print('After sorting: ${sortedMessages.length} messages');
                for (int i = 0; i < sortedMessages.length; i++) {
                    final msg = sortedMessages[i];
                    print('Sorted Message $i: ${msg.isUser ? "USER" : "AI"} - ${msg.content.length > 50 ? msg.content.substring(0, 50) + "..." : msg.content}');
                }
                
                setState(() {
                    _currentConversation = conversation;
                    _messages.clear();
                    for (final message in sortedMessages) {
                        _messages.add(_ChatMessage(
                            text: message.content,
                            isUser: message.isUser,
                            suggestions: message.metadata != null
                                ? _MessageSuggestions.fromJson(message.metadata!)
                                : null,
                        ));
                    }
                });
                print('UI messages count: ${_messages.length}');
                print('Current conversation set to: ${_currentConversation?.id}');
                
                // For reverse: true ListView, scroll to position 0 to show latest messages at bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && _messages.isNotEmpty) {
                    _scrollController.animateTo(
                      0.0, // Scroll to bottom (most recent message)
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                });
            } else {
                print('Conversation is null');
            }
        } catch (e) {
            print('Error loading conversation by ID: $e');
        } finally {
            setState(() => _isLoadingConversation = false);
        }
    }

  Future<void> _loadActiveConversation() async {
    setState(() => _isLoadingConversation = true);
    
    try {
      final activeConversation = await ConversationService.getActiveConversation();
      if (activeConversation != null) {
        setState(() {
          _currentConversation = activeConversation;
          _messages.clear();
          
          // Convert conversation messages to _ChatMessage format
          for (final message in activeConversation.messages) {
            _messages.add(_ChatMessage(
              text: message.content,
              isUser: message.isUser,
              suggestions: message.metadata != null 
                  ? _MessageSuggestions.fromJson(message.metadata!)
                  : null,
            ));
          }
        });
        
        print('Loaded conversation: ${activeConversation.title} with ${activeConversation.messages.length} messages');
      } else {
        print('No active conversation found, will create new one on first message');
      }
    } catch (e) {
      print('Error loading active conversation: $e');
    } finally {
      setState(() => _isLoadingConversation = false);
    }
  }

  Future<void> _initTts() async {
    // Configure TTS for automatic playback to match manual audio buttons
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(1.0); // Standard speech rate
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);
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
    
    try {
      // Track user progress
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final currentProgress = await ProgressService.loadProgress(user.uid);
        await ProgressService.trackMessageSubmission(currentProgress, text, 'chat');
      }
      
      // Add user message to conversation service, using current conversation if available
      print('_sendMessage: Current conversation before addUserMessage: ${_currentConversation?.id}');
      final (userMessage, conversation) = await ConversationService.addUserMessage(text, currentConversation: _currentConversation);
      
      // Update current conversation reference
      _currentConversation = conversation;
      print('_sendMessage: Current conversation after addUserMessage: ${_currentConversation?.id}');
      
      // Add to UI
      final userUIMessage = _ChatMessage(text: text, isUser: true);
      setState(() {
        _messages.add(userUIMessage);
        _isTyping = true;
      });
      _controller.clear();
      _scrollToBottom();
      
      // Get AI response with suggestions in a single call if suggestions are enabled
      print('_sendMessage: Requesting AI response for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
      
      Map<String, dynamic>? aiResponseData;
      String aiResponse;
      _MessageSuggestions? suggestions;
      
      if (_isSuggestionsEnabled) {
        // Use combined API call to get both response and suggestions
        print('_sendMessage: Using combined API call with suggestions enabled');
        aiResponseData = await ApiService.sendChatMessageWithSuggestions(
          text,
          conversationId: _currentConversation?.id,
          includeSuggestions: true,
        );
        
        aiResponse = aiResponseData['reply'] ?? 'Error';
        
        // Parse suggestions if available
        if (aiResponseData['suggestions'] != null) {
          try {
            suggestions = _MessageSuggestions.fromJson(aiResponseData['suggestions']);
            print('_sendMessage: Suggestions parsed successfully');
          } catch (e) {
            print('_sendMessage: Error parsing suggestions: $e');
            suggestions = null;
          }
        }
      } else {
        // Use simple chat API call without suggestions
        print('_sendMessage: Using simple chat API call without suggestions');
        aiResponse = await _getAIResponse(text);
        suggestions = null;
      }
      
      print('_sendMessage: Received AI response: "${aiResponse.substring(0, aiResponse.length > 100 ? 100 : aiResponse.length)}..."');
      
      // Add AI response to conversation service with the conversation reference
      ChatMessage? aiChatMessage;
      try {
        print('_sendMessage: About to save AI message to conversation: ${conversation.id}');
        print('_sendMessage: Current conversation has ${conversation.messages.length} messages');
        aiChatMessage = await ConversationService.addAIMessage(aiResponse, conversation: conversation);
        print('_sendMessage: AI message saved successfully: ${aiChatMessage.id}');
        
        // Update our current conversation reference to include the new AI message
        final updatedConversationWithAI = conversation.addMessage(aiChatMessage);
        _currentConversation = updatedConversationWithAI;
        print('_sendMessage: Updated current conversation, now has ${_currentConversation!.messages.length} messages');
      } catch (e) {
        print('_sendMessage: Error saving AI message: $e');
        print('_sendMessage: Conversation details - ID: ${conversation.id}, messages: ${conversation.messages.length}');
        
        // Retry once after a short delay for transient issues
        try {
          print('_sendMessage: Retrying AI message save after error...');
          await Future.delayed(Duration(milliseconds: 500));
          aiChatMessage = await ConversationService.addAIMessage(aiResponse, conversation: conversation);
          print('_sendMessage: AI message saved successfully on retry: ${aiChatMessage.id}');
          
          final updatedConversationWithAI = conversation.addMessage(aiChatMessage);
          _currentConversation = updatedConversationWithAI;
        } catch (retryError) {
          print('_sendMessage: Retry also failed: $retryError');
          // Show warning but continue
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: AI response may not be saved to history'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Save Error'),
                        content: Text('Failed to save AI response: $retryError'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }
      }
      
      // Show AI response immediately with suggestions if available
      setState(() {
        _messages.add(_ChatMessage(
          text: aiResponse, 
          isUser: false, 
          suggestions: suggestions
        ));
        _isTyping = false;
      });
      _scrollToBottom();
      
      // Auto-play AI response if enabled
      if (_voiceAutoplayEnabled) {
        await _tts.speak(aiResponse);
      }
      
      // If we got suggestions, update the message metadata in conversation service
      if (suggestions != null && aiChatMessage != null) {
        try {
          await ConversationService.updateMessageMetadata(
            _currentConversation?.id ?? '',
            aiChatMessage.id,
            {'suggestions': aiResponseData?['suggestions']},
          );
        } catch (e) {
          print('_sendMessage: Error updating message metadata: $e');
        }
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() => _isTyping = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      // Pass conversation ID if available
      final conversationId = _currentConversation?.id;
      final response = await ApiService.sendChatMessage(userInput, conversationId: conversationId);
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
      
      // Check if it's a rate limit error and provide a specific message
      final errorMessage = e.toString();
      if (errorMessage.contains('429') || errorMessage.contains('Rate limit') || errorMessage.contains('rate limit')) {
        return "I apologize, but I'm currently experiencing high demand. Please wait a moment and try again. The AI service has rate limits that help ensure fair usage for everyone.";
      } else if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
        return "The AI service is taking longer than expected to respond. Please try sending your message again.";
      } else {
        return "I'm sorry, I'm having trouble connecting to the server right now. Please try again in a moment.";
      }
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

  void _showConversationHistory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConversationHistoryScreen(),
      ),
    );

    // Handle result from conversation history screen
    if (result != null) {
      if (result == 'new') {
        // New conversation was created, reload current conversation
        await _loadActiveConversation();
      } else if (result is String) {
        // Specific conversation was selected, load it by ID
        await _loadConversationById(result);
      }
    }
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
            height: 80, // Fixed height for consistent alignment
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 8,
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
              crossAxisAlignment: CrossAxisAlignment.center, // Center all items vertically
              children: [
                SizedBox(
                  height: 48, // Fixed height for button
                  width: 48,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // Navigate back to WelcomeScreen instead of just popping
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
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
                  child: Container(
                    height: 48, // Fixed height for text container
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
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
                ),
                SizedBox(
                  height: 48, // Fixed height for menu button
                  width: 48,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'ai_settings') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      } else if (value == 'history') {
                        _showConversationHistory();
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
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.deepPurple, size: 20),
                            SizedBox(width: 12),
                            Text('Chat History'),
                          ],
                        ),
                      ),
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
        mainAxisAlignment: MainAxisAlignment.end, // Align to right side for AI
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
          const SizedBox(width: 8),
          // AI avatar next to typing indicator
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
            mainAxisAlignment: message.isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isUser) ...[
                // User avatar on the left for user messages
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
              if (!message.isUser) ...[
                const SizedBox(width: 8),
                // AI avatar on the right for AI messages
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
              ],
            ],
          ),
        ),
        
        // Suggestions panel (for AI messages - show suggestions if available)
        if (!message.isUser && (_isSuggestionsEnabled && message.suggestions != null))
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
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Text(
                            'READY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
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
                
                // Grammar Errors Section
                if (message.suggestions!.grammarErrors.isNotEmpty) ...[
                  Text(
                    '✏️ Grammar Issues',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...message.suggestions!.grammarErrors.asMap().entries.map((entry) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.value.type,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ),
                              Spacer(),
                              AudioPlayButton(
                                text: entry.value.correction,
                                size: 16,
                                mini: true,
                                color: Colors.red[700],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.red[800]),
                              children: [
                                TextSpan(
                                  text: '❌ Error: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '"${entry.value.error}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.green[800]),
                              children: [
                                TextSpan(
                                  text: '✅ Correction: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '"${entry.value.correction}"',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '💡 ${entry.value.explanation}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                  const SizedBox(height: 12),
                ],
                
                // Spelling Errors Section
                if (message.suggestions!.spellingErrors.isNotEmpty) ...[
                  Text(
                    '📝 Spelling Issues',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...message.suggestions!.spellingErrors.asMap().entries.map((entry) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                                    children: [
                                      TextSpan(
                                        text: '❌ "${entry.value.error}" → ✅ "${entry.value.correction}"',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AudioPlayButton(
                                text: entry.value.correction,
                                size: 16,
                                mini: true,
                                color: Colors.orange[700],
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '💡 ${entry.value.explanation}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
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

class _GrammarError {
  final String error;
  final String correction;
  final String explanation;
  final String type;
  
  _GrammarError({
    required this.error,
    required this.correction,
    required this.explanation,
    required this.type,
  });
  
  factory _GrammarError.fromJson(Map<String, dynamic> json) {
    return _GrammarError(
      error: json['error']?.toString() ?? '',
      correction: json['correction']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Grammar Error',
    );
  }
}

class _SpellingError {
  final String error;
  final String correction;
  final String explanation;
  
  _SpellingError({
    required this.error,
    required this.correction,
    required this.explanation,
  });
  
  factory _SpellingError.fromJson(Map<String, dynamic> json) {
    return _SpellingError(
      error: json['error']?.toString() ?? '',
      correction: json['correction']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
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
  final List<_GrammarError> grammarErrors;
  final List<_SpellingError> spellingErrors;
  final List<String> betterVersions;
  final List<_VocabularyItem> vocabulary;
  
  _MessageSuggestions({
    required this.grammarErrors,
    required this.spellingErrors,
    required this.betterVersions,
    required this.vocabulary,
  });
  
  factory _MessageSuggestions.fromJson(Map<String, dynamic> json) {
    return _MessageSuggestions(
      grammarErrors: _parseGrammarErrorList(json['grammar_errors']),
      spellingErrors: _parseSpellingErrorList(json['spelling_errors']),
      betterVersions: _parseStringList(json['better_versions']),
      vocabulary: _parseVocabularyList(json['vocabulary']),
    );
  }
  
  static List<_GrammarError> _parseGrammarErrorList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return _GrammarError.fromJson(item);
        }
        return _GrammarError(
          error: 'Parse error',
          correction: 'Unable to parse',
          explanation: 'Invalid data format',
          type: 'System Error',
        );
      }).toList();
    }
    return [];
  }
  
  static List<_SpellingError> _parseSpellingErrorList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return _SpellingError.fromJson(item);
        }
        return _SpellingError(
          error: 'Parse error',
          correction: 'Unable to parse',
          explanation: 'Invalid data format',
        );
      }).toList();
    }
    return [];
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

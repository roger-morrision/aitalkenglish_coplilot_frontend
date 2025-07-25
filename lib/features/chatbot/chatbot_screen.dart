import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/api_service.dart';

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
  _MessageSuggestions? _currentSuggestions;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _micAnimationController.repeat();
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
    setState(() {
      _messages.add(_ChatMessage(text: aiResponse, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
    
    // Get suggestions for the user's message
    try {
      print('Chatbot: Requesting suggestions for message: $text');
      setState(() {
        _currentSuggestions = null; // Clear old suggestions first
        _isLoadingSuggestions = true;
      });
      
      final suggestions = await ApiService.getMessageSuggestions(text);
      print('Chatbot: Received suggestions: $suggestions');
      
      setState(() {
        _currentSuggestions = _MessageSuggestions.fromJson(suggestions);
        _isLoadingSuggestions = false;
      });
      print('Chatbot: Suggestions panel updated with: ${_currentSuggestions?.grammarFix}');
    } catch (e) {
      print('Chatbot: Error getting suggestions: $e');
      // Show error-specific fallback
      setState(() {
        _currentSuggestions = _MessageSuggestions(
          grammarFix: 'Error: $text',
          betterVersions: ['[Error: Could not fetch suggestions from server - $e]'],
          vocabulary: [
            _VocabularyItem(
              word: 'error', 
              meaning: 'API connection failed', 
              example: 'Check console for details: $e'
            )
          ],
        );
        _isLoadingSuggestions = false;
      });
    }
    
    await _tts.speak(aiResponse);
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
                                ? 'Online' 
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
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // TODO: Show chat options menu
                  },
                ),
              ],
            ),
          ),
          
          // Scrollable Chat Body
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
                      final msg = _messages[_messages.length - 1 - msgIndex];
                      return _buildMessage(msg);
                    },
                  ),
          ),
          
          // Bottom section with constrained height to prevent overflow
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4, // Max 40% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Suggestions Panel (scrollable if needed)
                if (_isLoadingSuggestions)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text('Loading suggestions...'),
                      ],
                    ),
                  )
                else if (_currentSuggestions != null)
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildSuggestionsPanel(),
                    ),
                  ),
                
                // Input Form at Bottom
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

  Widget _buildMessage(_ChatMessage message) {
    return Container(
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
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.grey[800],
                  fontSize: 14,
                  height: 1.4,
                ),
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
    );
  }

  Widget _buildSuggestionsPanel() {
    if (_currentSuggestions == null) return const SizedBox.shrink();
    
    // Debug logging
    print('=== SUGGESTIONS PANEL DEBUG ===');
    print('Grammar fix: ${_currentSuggestions!.grammarFix}');
    print('Better versions: ${_currentSuggestions!.betterVersions}');
    print('Vocabulary count: ${_currentSuggestions!.vocabulary.length}');
    for (var vocab in _currentSuggestions!.vocabulary) {
      print('Vocab: ${vocab.word} - ${vocab.meaning} - ${vocab.example}');
    }
    print('=== END DEBUG ===');
    
    return Container(
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
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📚 Grammar & Vocabulary Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.blue[600], size: 20),
                onPressed: () {
                  setState(() {
                    _currentSuggestions = null;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Grammar Fix Section
          if (_currentSuggestions!.grammarFix.isNotEmpty) ...[
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
              child: Text(
                _currentSuggestions!.grammarFix,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Better Versions Section
          if (_currentSuggestions!.betterVersions.isNotEmpty) ...[
            Text(
              '💡 Alternative Expressions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 4),
            ..._currentSuggestions!.betterVersions.map((version) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        version,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
            const SizedBox(height: 12),
          ],
          
          // Vocabulary Section
          if (_currentSuggestions!.vocabulary.isNotEmpty) ...[
            Text(
              '📖 New Vocabulary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            ..._currentSuggestions!.vocabulary.map((vocab) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.word,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vocab.meaning,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[700],
                      ),
                    ),
                    if (vocab.example.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Example: ${vocab.example}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).toList(),
          ],
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _VocabularyItem {
  final String word;
  final String meaning;
  final String example;
  
  _VocabularyItem({required this.word, required this.meaning, required this.example});
  
  factory _VocabularyItem.fromJson(Map<String, dynamic> json) {
    return _VocabularyItem(
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      example: json['example'] ?? '',
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
      grammarFix: json['grammar_fix'] ?? '',
      betterVersions: List<String>.from(json['better_versions'] ?? []),
      vocabulary: (json['vocabulary'] as List<dynamic>?)
          ?.map((item) => _VocabularyItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

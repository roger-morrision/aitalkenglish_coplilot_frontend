class Conversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final bool isActive;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.isActive = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((messageJson) => ChatMessage.fromJson(messageJson))
          .toList() ?? [],
      isActive: json['isActive'] ?? json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'is_active': isActive,
    };
  }

  // Create a new conversation with generated title from first message
  factory Conversation.createNew({
    required String userId,
    String? customTitle,
    String? firstMessage,
  }) {
    final now = DateTime.now();
    final title = customTitle ?? 
        (firstMessage != null ? _generateTitleFromMessage(firstMessage) : 'New Conversation');
    
    return Conversation(
      id: _generateConversationId(),
      userId: userId,
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
      isActive: true,
    );
  }

  // Update conversation with new message
  Conversation addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return Conversation(
      id: id,
      userId: userId,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
      isActive: isActive,
    );
  }

  // Update conversation title
  Conversation updateTitle(String newTitle) {
    return Conversation(
      id: id,
      userId: userId,
      title: newTitle,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: messages,
      isActive: isActive,
    );
  }

  // Mark conversation as active/inactive
  Conversation setActive(bool active) {
    return Conversation(
      id: id,
      userId: userId,
      title: title,
      createdAt: createdAt,
      updatedAt: active ? DateTime.now() : updatedAt,
      messages: messages,
      isActive: active,
    );
  }

  // Get last message preview
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final lastMessage = messages.last;
    final preview = lastMessage.content.length > 50 
        ? '${lastMessage.content.substring(0, 50)}...'
        : lastMessage.content;
    return lastMessage.isUser ? 'You: $preview' : preview;
  }

  // Get message count
  int get messageCount => messages.length;

  // Get user messages count (for progress tracking)
  int get userMessageCount => messages.where((m) => m.isUser).length;

  // Public method to generate title from message
  static String generateTitleFromMessage(String message) {
    return _generateTitleFromMessage(message);
  }

  static String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
  }

  static String _generateTitleFromMessage(String message) {
    if (message.trim().isEmpty) return 'New Conversation';
    
    // Clean the message
    final cleanMessage = message.trim();
    
    // If message is short enough, use it as is
    if (cleanMessage.length <= 40) {
      return _capitalizeTitle(cleanMessage);
    }
    
    // Extract key information for title generation
    final title = _extractMeaningfulTitle(cleanMessage);
    return title.isNotEmpty ? title : _fallbackTitle(cleanMessage);
  }
  
  static String _extractMeaningfulTitle(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Question patterns - extract the topic
    if (lowerMessage.startsWith('how ') || lowerMessage.startsWith('what ') || 
        lowerMessage.startsWith('why ') || lowerMessage.startsWith('when ') ||
        lowerMessage.startsWith('where ') || lowerMessage.startsWith('which ')) {
      return _extractQuestionTopic(message);
    }
    
    // Topic indicators
    final topicPatterns = {
      'learn about': 'Learning about',
      'tell me about': 'About',
      'explain': 'Explaining',
      'help me': 'Help with',
      'practice': 'Practice',
      'grammar': 'Grammar Help',
      'vocabulary': 'Vocabulary',
      'pronunciation': 'Pronunciation',
      'conversation': 'Conversation Practice',
      'translate': 'Translation',
      'correct': 'Correction',
    };
    
    for (final pattern in topicPatterns.keys) {
      if (lowerMessage.contains(pattern)) {
        final remaining = message.substring(lowerMessage.indexOf(pattern) + pattern.length).trim();
        final topic = _extractTopicFromText(remaining);
        return topic.isNotEmpty ? '${topicPatterns[pattern]}: $topic' : topicPatterns[pattern]!;
      }
    }
    
    // Country/Location patterns
    final countryMatch = _extractCountryOrLocation(message);
    if (countryMatch.isNotEmpty) {
      return 'About $countryMatch';
    }
    
    // Activity patterns
    final activityMatch = _extractActivity(message);
    if (activityMatch.isNotEmpty) {
      return activityMatch;
    }
    
    return '';
  }
  
  static String _extractQuestionTopic(String question) {
    final words = question.split(' ');
    if (words.length < 3) return _capitalizeTitle(question);
    
    // Find the main topic after the question word
    final mainPart = words.skip(1).take(6).join(' ');
    final cleanTopic = mainPart.replaceAll(RegExp(r'[?.!]+$'), '').trim();
    
    if (cleanTopic.length > 30) {
      return '${words[0].capitalize()} ${cleanTopic.substring(0, 27)}...';
    }
    
    return '${words[0].capitalize()} $cleanTopic';
  }
  
  static String _extractTopicFromText(String text) {
    if (text.isEmpty) return '';
    
    // Remove common sentence starters and get the main topic
    final cleanText = text.replaceAll(RegExp(r'^(the|a|an|some|my|this|that)\s+', caseSensitive: false), '');
    final words = cleanText.split(' ').take(4).toList();
    
    // Remove trailing punctuation
    final lastWord = words.last.replaceAll(RegExp(r'[?.!,]+$'), '');
    if (words.isNotEmpty) {
      words[words.length - 1] = lastWord;
    }
    
    final result = words.join(' ');
    return result.length > 25 ? '${result.substring(0, 22)}...' : result;
  }
  
  static String _extractCountryOrLocation(String message) {
    final commonCountries = [
      'malaysia', 'singapore', 'thailand', 'indonesia', 'philippines', 
      'vietnam', 'cambodia', 'laos', 'myanmar', 'brunei',
      'china', 'japan', 'korea', 'india', 'australia', 'new zealand',
      'united states', 'america', 'canada', 'mexico', 'brazil',
      'england', 'britain', 'france', 'germany', 'italy', 'spain',
      'russia', 'turkey', 'egypt', 'south africa'
    ];
    
    final lowerMessage = message.toLowerCase();
    for (final country in commonCountries) {
      if (lowerMessage.contains(country)) {
        return country.split(' ').map((word) => word.capitalize()).join(' ');
      }
    }
    
    return '';
  }
  
  static String _extractActivity(String message) {
    final activities = {
      'cooking': 'Cooking',
      'traveling': 'Travel',
      'shopping': 'Shopping',
      'studying': 'Study',
      'working': 'Work',
      'eating': 'Food',
      'restaurant': 'Dining',
      'hotel': 'Hotel',
      'airport': 'Travel',
      'hospital': 'Medical',
      'school': 'Education',
      'university': 'Education',
      'business': 'Business',
      'meeting': 'Meetings',
      'interview': 'Interview',
      'job': 'Career',
      'movie': 'Entertainment',
      'music': 'Music',
      'sports': 'Sports',
      'exercise': 'Fitness',
      'weather': 'Weather',
      'family': 'Family',
      'friend': 'Friends',
      'holiday': 'Holiday',
      'vacation': 'Vacation',
      'birthday': 'Celebration',
      'wedding': 'Wedding',
    };
    
    final lowerMessage = message.toLowerCase();
    for (final activity in activities.keys) {
      if (lowerMessage.contains(activity)) {
        return activities[activity]!;
      }
    }
    
    return '';
  }
  
  static String _fallbackTitle(String message) {
    // Get first meaningful words
    final words = message.split(' ');
    final meaningfulWords = words.where((word) => 
      word.length > 2 && 
      !['the', 'and', 'but', 'for', 'are', 'you', 'can', 'will', 'with'].contains(word.toLowerCase())
    ).take(4).toList();
    
    if (meaningfulWords.isNotEmpty) {
      final title = meaningfulWords.join(' ');
      return title.length > 30 ? '${title.substring(0, 27)}...' : _capitalizeTitle(title);
    }
    
    // Final fallback - just use first few words
    final firstWords = words.take(4).join(' ');
    return firstWords.length > 30 ? '${firstWords.substring(0, 27)}...' : _capitalizeTitle(firstWords);
  }
  
  static String _capitalizeTitle(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // For storing suggestions, etc.

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversationId'] ?? json['conversation_id'],
      content: json['content'],
      isUser: json['isUser'] ?? json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create a new user message
  factory ChatMessage.createUser({
    required String conversationId,
    required String content,
  }) {
    return ChatMessage(
      id: _generateMessageId(),
      conversationId: conversationId,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  // Create a new AI message
  factory ChatMessage.createAI({
    required String conversationId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: _generateMessageId(),
      conversationId: conversationId,
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
  }

  // Create copy with metadata
  ChatMessage copyWithMetadata(Map<String, dynamic> newMetadata) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      metadata: {...?metadata, ...newMetadata},
    );
  }
}

// For conversation list display
class ConversationSummary {
  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final int messageCount;
  final bool isActive;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.messageCount,
    required this.isActive,
  });

  factory ConversationSummary.fromConversation(Conversation conversation) {
    return ConversationSummary(
      id: conversation.id,
      title: conversation.title,
      lastMessagePreview: conversation.lastMessagePreview,
      updatedAt: conversation.updatedAt,
      messageCount: conversation.messageCount,
      isActive: conversation.isActive,
    );
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      title: json['title'],
      lastMessagePreview: json['lastMessagePreview'] ?? json['last_message_preview'] ?? 'No messages yet',
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      messageCount: json['messageCount'] ?? json['message_count'] ?? 0,
      isActive: json['isActive'] ?? json['is_active'] ?? false,
    );
  }
}

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

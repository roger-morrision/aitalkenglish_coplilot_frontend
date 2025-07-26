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
      userId: json['user_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((messageJson) => ChatMessage.fromJson(messageJson))
          .toList() ?? [],
      isActive: json['is_active'] ?? false,
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

  static String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
  }

  static String _generateTitleFromMessage(String message) {
    if (message.length <= 30) return message;
    
    // Try to find a good breaking point
    final words = message.split(' ');
    if (words.length <= 4) return message;
    
    var title = '';
    for (int i = 0; i < words.length && title.length < 25; i++) {
      if (i > 0) title += ' ';
      title += words[i];
    }
    
    return '$title...';
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
      conversationId: json['conversation_id'],
      content: json['content'],
      isUser: json['is_user'],
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
      lastMessagePreview: json['last_message_preview'],
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'],
      isActive: json['is_active'] ?? false,
    );
  }
}

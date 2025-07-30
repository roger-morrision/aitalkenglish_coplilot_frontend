import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class ConversationService {
  // Get current user ID
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // CREATE OPERATIONS

  // Create and start a new conversation
  static Future<Conversation> createNewConversation({String? customTitle, String? firstMessage}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Create new conversation
    final conversation = Conversation.createNew(
      userId: userId,
      customTitle: customTitle,
      firstMessage: firstMessage,
    );

    try {
      // Save to backend
      await ApiService.saveConversation(
        conversationId: conversation.id,
        userId: userId,
        title: conversation.title,
        messages: conversation.messages.map((msg) => msg.toJson()).toList(),
      );
      
      // Activate the new conversation
      await ApiService.activateConversation(
        conversationId: conversation.id,
        userId: userId,
      );
      
      print('Conversation created and activated: ${conversation.id}');
    } catch (e) {
      print('Failed to create conversation: $e');
      rethrow;
    }

    return conversation;
  }

  // CONVERSATION MANAGEMENT

  // Get user's conversation list (summaries)
  static Future<List<ConversationSummary>> getConversationHistory() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Get conversations from backend
      final backendConversations = await ApiService.getConversationHistory(userId);
      
      // Convert backend data to conversation summaries
      final summaries = backendConversations.map((conversationData) {
        try {
          return ConversationSummary.fromJson(conversationData);
        } catch (e) {
          print('Error parsing conversation from backend: $e');
          return null;
        }
      }).where((summary) => summary != null).cast<ConversationSummary>().toList();

      print('Loaded ${summaries.length} conversations from backend');
      return summaries;
    } catch (e) {
      print('Failed to load conversations from backend: $e');
      rethrow;
    }
  }

  // Get active conversation (full conversation with messages)
  static Future<Conversation?> getActiveConversation() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Get all conversations to find the active one
      final conversations = await ApiService.getConversationHistory(userId);
      final activeConversationData = conversations.firstWhere(
        (conv) => conv['isActive'] == true || conv['is_active'] == true,
        orElse: () => null,
      );

      if (activeConversationData != null) {
        // Get full conversation details from backend
        final fullConversation = await ApiService.getConversation(activeConversationData['id']);
        return Conversation.fromJson(fullConversation);
      }
      
      return null;
    } catch (e) {
      print('Failed to get active conversation from backend: $e');
      return null;
    }
  }

  // Load a specific conversation and set it as active
  static Future<Conversation?> loadConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      print('ConversationService: Loading conversation $conversationId for user $userId');
      
      // Get conversation from backend
      final backendConversation = await ApiService.getConversation(conversationId);
      print('ConversationService: Backend returned conversation data: ${backendConversation.toString()}');
      
      final conversation = Conversation.fromJson(backendConversation);
      print('ConversationService: Parsed conversation with ${conversation.messages.length} messages');
      
      // Set as active on backend
      await ApiService.activateConversation(
        conversationId: conversationId,
        userId: userId,
      );
      
      return conversation;
    } catch (e) {
      print('Failed to load conversation from backend: $e');
      rethrow;
    }
  }

  // Switch to a conversation (set as active)
  static Future<void> switchToConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await ApiService.activateConversation(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      print('Failed to switch to conversation: $e');
      rethrow;
    }
  }

  // Update conversation title
  static Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      await ApiService.updateConversationTitle(
        conversationId: conversationId,
        newTitle: newTitle,
      );
      print('Conversation title updated: $conversationId');
    } catch (e) {
      print('Failed to update conversation title: $e');
      rethrow;
    }
  }

  // Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      await ApiService.deleteConversation(conversationId);
      print('Conversation deleted: $conversationId');
    } catch (e) {
      print('Failed to delete conversation: $e');
      rethrow;
    }
  }

  // MESSAGE OPERATIONS

  // Add a user message to the active conversation
  static Future<(ChatMessage, Conversation)> addUserMessage(String content, {Conversation? currentConversation}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Use provided current conversation or get active conversation from backend
    var activeConversation = currentConversation;
    if (activeConversation == null) {
      activeConversation = await getActiveConversation();
      if (activeConversation == null) {
        print('addUserMessage: Creating new conversation for first message');
        activeConversation = await createNewConversation(firstMessage: content);
      }
    }

    print('addUserMessage: Using conversation ${activeConversation.id} with ${activeConversation.messages.length} existing messages');

    // Create user message
    final userMessage = ChatMessage.createUser(
      conversationId: activeConversation.id,
      content: content,
    );

    try {
      // Add message to conversation
      final updatedConversation = activeConversation.addMessage(userMessage);
      
      // Check if we should update the conversation title based on accumulated context
      final shouldUpdateTitle = _shouldUpdateConversationTitle(updatedConversation);
      var finalConversation = updatedConversation;
      
      if (shouldUpdateTitle) {
        final newTitle = _generateContextualTitle(updatedConversation);
        if (newTitle != updatedConversation.title) {
          finalConversation = updatedConversation.updateTitle(newTitle);
          print('Updated conversation title from "${updatedConversation.title}" to "$newTitle"');
        }
      }
      
      // Save to backend with enhanced logging for first message scenarios
      if (activeConversation.messages.isEmpty) {
        print('addUserMessage: This is the FIRST message in the conversation');
      }
      
      await ApiService.saveConversation(
        conversationId: finalConversation.id,
        userId: userId,
        title: finalConversation.title,
        messages: finalConversation.messages.map((msg) => msg.toJson()).toList(),
      );
      
      print('User message saved to backend: ${userMessage.id}');
      print('Conversation now has ${finalConversation.messages.length} messages total');
      return (userMessage, finalConversation);
    } catch (e) {
      print('Failed to save user message to backend: $e');
      rethrow;
    }
  }
  
  // Determine if conversation title should be updated based on context
  static bool _shouldUpdateConversationTitle(Conversation conversation) {
    // Update title after 3-4 messages when we have more context
    final messageCount = conversation.messages.length;
    
    // Don't update if title was manually set (doesn't end with ... or contain common auto-generated patterns)
    if (!conversation.title.contains('...') && 
        !conversation.title.startsWith('New Conversation') &&
        conversation.title.length > 10) {
      return false;
    }
    
    // Update after we have some conversation context (3-4 messages)
    return messageCount == 3 || messageCount == 4;
  }
  
  // Generate a more contextual title based on the conversation content
  static String _generateContextualTitle(Conversation conversation) {
    final messages = conversation.messages;
    if (messages.isEmpty) return 'New Conversation';
    
    // Collect user messages for context
    final userMessages = messages.where((m) => m.isUser).map((m) => m.content).toList();
    final aiMessages = messages.where((m) => !m.isUser).map((m) => m.content).toList();
    
    if (userMessages.isEmpty) return 'New Conversation';
    
    // Try to identify the main topic from user messages
    final combinedUserText = userMessages.join(' ').toLowerCase();
    
    // Topic detection patterns
    final topicMap = {
      // Language learning topics
      'grammar|tense|verb|noun|adjective': 'Grammar Practice',
      'pronunciation|pronounce|accent|speak': 'Pronunciation Help',
      'vocabulary|word|meaning|definition': 'Vocabulary Building',
      'conversation|practice|chat|talk': 'Conversation Practice',
      'translate|translation': 'Translation Help',
      
      // Countries and travel
      'malaysia|malaysian': 'About Malaysia',
      'singapore|singaporean': 'About Singapore', 
      'thailand|thai': 'About Thailand',
      'indonesia|indonesian': 'About Indonesia',
      'philippines|filipino': 'About Philippines',
      'vietnam|vietnamese': 'About Vietnam',
      'japan|japanese': 'About Japan',
      'korea|korean': 'About Korea',
      'china|chinese': 'About China',
      'travel|trip|vacation|holiday|visit': 'Travel Discussion',
      'hotel|resort|accommodation': 'Accommodation',
      'airport|flight|plane': 'Air Travel',
      
      // Common activities
      'food|eat|restaurant|cook|meal': 'Food & Dining',
      'work|job|career|business|office': 'Work & Career',
      'study|school|university|education': 'Education',
      'family|parent|child|mother|father': 'Family',
      'friend|friendship|social': 'Social Life',
      'hobby|interest|free time|leisure': 'Hobbies & Interests',
      'health|hospital|doctor|medicine': 'Health & Medical',
      'shopping|buy|purchase|store': 'Shopping',
      'weather|rain|sun|hot|cold': 'Weather',
      'movie|film|entertainment|music': 'Entertainment',
      'sports|exercise|fitness|gym': 'Sports & Fitness',
      
      // Common conversation starters
      'how to|how do|how can': 'How-to Discussion',
      'what is|what are|what do': 'Q&A Session',
      'tell me|explain|describe': 'Learning Session',
      'help|assist|support': 'Help Request',
      'opinion|think|believe|feel': 'Opinion Discussion',
    };
    
    // Check for topic matches
    for (final pattern in topicMap.keys) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(combinedUserText)) {
        return topicMap[pattern]!;
      }
    }
    
    // If no pattern matches, extract key themes from the conversation
    return _extractConversationTheme(userMessages, aiMessages);
  }
  
  static String _extractConversationTheme(List<String> userMessages, List<String> aiMessages) {
    // Get the most substantial user message for theme extraction
    final longestUserMessage = userMessages.reduce((a, b) => a.length > b.length ? a : b);
    
    // Look for question words to determine conversation type
    final firstMessage = userMessages.first.toLowerCase();
    if (firstMessage.startsWith('how ')) return 'How-to Guide';
    if (firstMessage.startsWith('what ')) return 'Information Request';
    if (firstMessage.startsWith('why ')) return 'Explanation';
    if (firstMessage.startsWith('where ')) return 'Location Discussion';
    if (firstMessage.startsWith('when ')) return 'Time Discussion';
    
    // Extract key nouns and concepts
    final keywords = _extractKeywords(longestUserMessage);
    if (keywords.isNotEmpty) {
      final theme = keywords.take(2).join(' & ');
      return theme.length > 30 ? '${theme.substring(0, 27)}...' : _capitalizeWords(theme);
    }
    
    // Final fallback - use improved version of original method
    return Conversation.generateTitleFromMessage(userMessages.first);
  }
  
  static List<String> _extractKeywords(String text) {
    // Simple keyword extraction - remove common words and get meaningful terms
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final stopWords = {
      'i', 'me', 'my', 'you', 'your', 'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
      'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
      'this', 'that', 'these', 'those', 'there', 'here', 'where', 'when', 'how', 'what', 'why', 'who', 'which',
      'can', 'cant', 'dont', 'wont', 'isnt', 'arent', 'wasnt', 'werent', 'havent', 'hasnt', 'hadnt', 'didnt', 'doesnt',
      'very', 'really', 'quite', 'just', 'only', 'also', 'too', 'much', 'many', 'some', 'any', 'all', 'no', 'not'
    };
    
    final keywords = words
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toSet()
        .toList();
    
    return keywords;
  }
  
  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
  
  // Generate an AI-powered conversation title (optional enhancement)
  static Future<String?> generateAITitle(Conversation conversation) async {
    try {
      // Only use AI for longer conversations to avoid excessive API calls
      if (conversation.messages.length < 4) return null;
      
      // Prepare context for AI title generation
      final userMessages = conversation.messages.where((m) => m.isUser).take(3).map((m) => m.content).toList();
      final context = userMessages.join(' | ');
      
      if (context.length > 200) {
        // Truncate context to avoid long API calls
        final truncatedContext = context.substring(0, 200) + '...';
        
        final prompt = 'Generate a short, descriptive title (max 40 characters) for this English learning conversation: "$truncatedContext". Focus on the main topic or learning goal. Return only the title, no explanation.';
        
        final aiTitle = await ApiService.sendChatMessage(prompt);
        
        // Clean and validate the AI response
        var cleanTitle = aiTitle.trim();
        if (cleanTitle.startsWith('"') && cleanTitle.endsWith('"')) {
          cleanTitle = cleanTitle.substring(1, cleanTitle.length - 1);
        }
        if (cleanTitle.startsWith("'") && cleanTitle.endsWith("'")) {
          cleanTitle = cleanTitle.substring(1, cleanTitle.length - 1);
        }
        
        if (cleanTitle.length <= 50 && cleanTitle.isNotEmpty && !cleanTitle.contains('\n')) {
          return cleanTitle;
        }
      }
    } catch (e) {
      print('Failed to generate AI title: $e');
    }
    
    return null;
  }
  
  // Update conversation title with AI assistance (optional)
  static Future<void> updateTitleWithAI(String conversationId) async {
    try {
      final conversation = await loadConversation(conversationId);
      if (conversation == null) return;
      
      final aiTitle = await generateAITitle(conversation);
      if (aiTitle != null) {
        await updateConversationTitle(conversationId, aiTitle);
        print('Updated conversation title to AI-generated: "$aiTitle"');
      }
    } catch (e) {
      print('Failed to update title with AI: $e');
    }
  }

  // Add an AI response to the active conversation
  static Future<ChatMessage> addAIMessage(String content, {Map<String, dynamic>? metadata, Conversation? conversation}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // Use provided conversation or get/create active conversation
    var activeConversation = conversation;
    if (activeConversation == null) {
      activeConversation = await getActiveConversation();
      if (activeConversation == null) {
        print('addAIMessage: WARNING - No active conversation found, creating new one');
        activeConversation = await createNewConversation(firstMessage: 'Starting conversation...');
      }
    }

    print('addAIMessage: Adding AI response to conversation ${activeConversation.id}');
    print('addAIMessage: Conversation currently has ${activeConversation.messages.length} messages');

    // Create AI message
    final aiMessage = ChatMessage.createAI(
      conversationId: activeConversation.id,
      content: content,
      metadata: metadata,
    );

    try {
      // Add message to conversation and save to backend
      final updatedConversation = activeConversation.addMessage(aiMessage);
      
      print('addAIMessage: About to save conversation with ${updatedConversation.messages.length} messages');
      for (int i = 0; i < updatedConversation.messages.length; i++) {
        final msg = updatedConversation.messages[i];
        print('addAIMessage: Message $i: ${msg.isUser ? "USER" : "AI"} - ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}');
      }
      
      await ApiService.saveConversation(
        conversationId: updatedConversation.id,
        userId: userId,
        title: updatedConversation.title,
        messages: updatedConversation.messages.map((msg) => msg.toJson()).toList(),
      );
      
      print('addAIMessage: AI message saved to backend: ${aiMessage.id}');
      print('addAIMessage: Final conversation has ${updatedConversation.messages.length} messages');
    } catch (e) {
      print('addAIMessage: Failed to save AI message to backend: $e');
      print('addAIMessage: Error occurred while saving conversation ${activeConversation.id}');
      rethrow;
    }

    return aiMessage;
  }

  // UTILITY OPERATIONS

  // Get conversation statistics
  static Future<Map<String, int>> getConversationStats() async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final conversations = await getConversationHistory();
      
      int totalMessages = 0;
      int userMessages = 0;
      int aiMessages = 0;
      
      for (final summary in conversations) {
        // This is an approximation since we only have summaries
        // For exact counts, we'd need to load each conversation fully
        totalMessages += summary.messageCount;
        // Rough estimation: assume half are user messages, half are AI
        userMessages += (summary.messageCount / 2).ceil();
        aiMessages += (summary.messageCount / 2).floor();
      }
      
      return {
        'total_conversations': conversations.length,
        'total_messages': totalMessages,
        'user_messages': userMessages,
        'ai_messages': aiMessages,
      };
    } catch (e) {
      print('Failed to get conversation stats: $e');
      return {};
    }
  }

  // Search conversations
  static Future<List<ConversationSummary>> searchConversations(String query) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final searchResults = await ApiService.searchConversations(userId, query);
      
      return searchResults.map((conversationData) {
        try {
          return ConversationSummary.fromJson(conversationData);
        } catch (e) {
          print('Error parsing search result: $e');
          return null;
        }
      }).where((summary) => summary != null).cast<ConversationSummary>().toList();
    } catch (e) {
      print('Failed to search conversations: $e');
      return [];
    }
  }

  // Clear all conversations for current user
  static Future<void> clearAllConversations() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final conversations = await getConversationHistory();
      
      // Delete each conversation
      for (final conversation in conversations) {
        await deleteConversation(conversation.id);
      }
      
      print('All conversations cleared successfully');
    } catch (e) {
      print('Failed to clear all conversations: $e');
      rethrow;
    }
  }

  // DEVELOPMENT/DEBUG HELPERS

  // Print conversation statistics
  static Future<void> printDebugInfo() async {
    try {
      final stats = await getConversationStats();
      final conversations = await getConversationHistory();
      
      print('=== CONVERSATION DEBUG INFO ===');
      print('Total conversations: ${stats['total_conversations']}');
      print('Total messages: ${stats['total_messages']}');
      print('User messages: ${stats['user_messages']}');
      print('AI messages: ${stats['ai_messages']}');
      print('Recent conversations:');
      
      for (int i = 0; i < conversations.length && i < 5; i++) {
        final conv = conversations[i];
        print('  ${i + 1}. ${conv.title} (${conv.messageCount} messages, ${conv.isActive ? 'ACTIVE' : 'inactive'})');
      }
      print('=== END DEBUG INFO ===');
    } catch (e) {
      print('Failed to print debug info: $e');
    }
  }

  // Update message metadata (compatibility method)
  static Future<void> updateMessageMetadata(String conversationId, String messageId, Map<String, dynamic> metadata) async {
    // This method is kept for compatibility but doesn't perform actual updates
    // since all message management is now handled by backend APIs
    print('ConversationService: updateMessageMetadata called - metadata updates are handled by backend');
  }
}

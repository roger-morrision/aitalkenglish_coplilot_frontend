import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../services/conversation_db_service.dart';
import '../services/api_service.dart';

class ConversationService {
  static const int MAX_LOCAL_CONVERSATIONS = 50; // Limit local storage
  static const int SYNC_BATCH_SIZE = 10; // Batch size for syncing

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
      // Save to backend first (primary storage)
      await _saveConversationToBackend(conversation);
      print('Conversation saved to backend: ${conversation.id}');
    } catch (e) {
      print('Failed to save conversation to backend: $e');
      // Fallback to local storage if backend fails
      await ConversationDbService.createConversation(conversation);
      print('Conversation saved locally as fallback: ${conversation.id}');
    }
    
    // Always save locally for quick access (cache)
    try {
      await ConversationDbService.createConversation(conversation);
      await ConversationDbService.setActiveConversation(userId, conversation.id);
    } catch (e) {
      print('Warning: Failed to cache conversation locally: $e');
    }

    return conversation;
  }

  // CONVERSATION MANAGEMENT

  // Get user's conversation list (summaries)
  static Future<List<ConversationSummary>> getConversationHistory() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Try to get conversations from backend first (primary source)
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

      // Update local cache with backend data
      try {
        await _syncBackendToLocal(backendConversations);
      } catch (e) {
        print('Warning: Failed to sync backend data to local cache: $e');
      }

      print('Loaded ${summaries.length} conversations from backend');
      return summaries;
    } catch (e) {
      print('Failed to load conversations from backend: $e, falling back to local cache');
      
      // Fallback to local conversations
      final localConversations = await ConversationDbService.getUserConversations(userId);
      return localConversations;
    }
  }

  // Get active conversation (full conversation with messages)
  static Future<Conversation?> getActiveConversation() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Try to get from backend first
      final conversations = await ApiService.getConversationHistory(userId);
      final activeConversationData = conversations.firstWhere(
        (conv) => conv['is_active'] == true,
        orElse: () => null,
      );

      if (activeConversationData != null) {
        // Get full conversation details from backend
        final fullConversation = await ApiService.getConversation(activeConversationData['id']);
        final conversation = Conversation.fromJson(fullConversation);
        
        // Cache locally for quick access
        try {
          await _cacheConversationLocally(conversation);
        } catch (e) {
          print('Warning: Failed to cache conversation locally: $e');
        }
        
        return conversation;
      }
    } catch (e) {
      print('Failed to get active conversation from backend: $e, trying local cache');
    }

    // Fallback to local storage
    return await ConversationDbService.getActiveConversation(userId);
  }

  // Load a specific conversation and set it as active
  static Future<Conversation?> loadConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Try to get from backend first
      final backendConversation = await ApiService.getConversation(conversationId);
      final conversation = Conversation.fromJson(backendConversation);
      
      // Cache locally
      await _cacheConversationLocally(conversation);
      
      // Set as active on backend
      // Note: We'll need to add this API endpoint
      // For now, just set locally
      await ConversationDbService.setActiveConversation(userId, conversationId);
      
      return conversation;
    } catch (e) {
      print('Failed to load conversation from backend: $e, trying local cache');
      
      // Fallback to local storage
      final conversation = await ConversationDbService.getConversation(conversationId);
      if (conversation != null) {
        await ConversationDbService.setActiveConversation(userId, conversationId);
      }
      return conversation;
    }
  }

  // Switch to a conversation (set as active)
  static Future<void> switchToConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // For now, just set locally since we need to add backend API
    await ConversationDbService.setActiveConversation(userId, conversationId);
  }

  // Update conversation title
  static Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      // Update on backend first
      await ApiService.updateConversationTitle(
        conversationId: conversationId,
        newTitle: newTitle,
      );
      print('Conversation title updated on backend: $conversationId');
    } catch (e) {
      print('Failed to update title on backend: $e');
    }

    // Update locally (cache)
    try {
      final conversation = await ConversationDbService.getConversation(conversationId);
      if (conversation != null) {
        final updatedConversation = conversation.updateTitle(newTitle);
        await ConversationDbService.updateConversation(updatedConversation);
      }
    } catch (e) {
      print('Warning: Failed to update title locally: $e');
    }
  }

  // Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete from backend first
      await ApiService.deleteConversation(conversationId);
      print('Conversation deleted from backend: $conversationId');
    } catch (e) {
      print('Failed to delete conversation from backend: $e');
    }

    // Delete from local cache
    try {
      await ConversationDbService.deleteConversation(conversationId);
    } catch (e) {
      print('Warning: Failed to delete conversation locally: $e');
    }
  }

  // MESSAGE OPERATIONS

  // Add a user message to the active conversation
  static Future<ChatMessage> addUserMessage(String content) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get or create active conversation
    var activeConversation = await getActiveConversation();
    if (activeConversation == null) {
      activeConversation = await createNewConversation(firstMessage: content);
    }

    // Create user message
    final userMessage = ChatMessage.createUser(
      conversationId: activeConversation.id,
      content: content,
    );

    try {
      // Save to backend first
      await _saveMessageToBackend(userMessage);
      print('User message saved to backend: ${userMessage.id}');
    } catch (e) {
      print('Failed to save user message to backend: $e');
    }

    // Always cache locally for quick access
    try {
      await ConversationDbService.addMessage(userMessage);
    } catch (e) {
      print('Warning: Failed to cache user message locally: $e');
    }

    return userMessage;
  }

  // Add an AI response to the active conversation
  static Future<ChatMessage> addAIMessage(String content, {Map<String, dynamic>? metadata}) async {
    final activeConversation = await getActiveConversation();
    if (activeConversation == null) throw Exception('No active conversation');

    // Create AI message
    final aiMessage = ChatMessage.createAI(
      conversationId: activeConversation.id,
      content: content,
      metadata: metadata,
    );

    try {
      // Save to backend first
      await _saveMessageToBackend(aiMessage);
      print('AI message saved to backend: ${aiMessage.id}');
    } catch (e) {
      print('Failed to save AI message to backend: $e');
    }

    // Always cache locally for quick access
    try {
      await ConversationDbService.addMessage(aiMessage);
    } catch (e) {
      print('Warning: Failed to cache AI message locally: $e');
    }

    return aiMessage;
  }

  // Update message metadata (for suggestions)
  static Future<void> updateMessageMetadata(String messageId, Map<String, dynamic> metadata) async {
    await ConversationDbService.updateMessageMetadata(messageId, metadata);
  }

  // UTILITY OPERATIONS

  // Get conversation statistics
  static Future<Map<String, int>> getConversationStats() async {
    final userId = currentUserId;
    if (userId == null) return {};

    return await ConversationDbService.getConversationStats(userId);
  }

  // Search conversations
  static Future<List<ConversationSummary>> searchConversations(String query) async {
    final userId = currentUserId;
    if (userId == null) return [];

    return await ConversationDbService.searchConversations(userId, query);
  }

  // Clear all conversations for current user
  static Future<void> clearAllConversations() async {
    final userId = currentUserId;
    if (userId == null) return;

    await ConversationDbService.clearUserConversations(userId);

    // Try to clear from backend (non-blocking)
    _clearBackendConversations().catchError((e) {
      print('Warning: Failed to clear conversations from backend: $e');
    });
  }

  // BACKGROUND SYNC OPERATIONS

  // Save conversation to backend (private method)
  static Future<void> _saveConversationToBackend(Conversation conversation) async {
    try {
      final messages = conversation.messages.map((message) => message.toJson()).toList();
      await ApiService.saveConversation(
        conversationId: conversation.id,
        userId: conversation.userId,
        title: conversation.title,
        messages: messages,
      );
      print('Conversation saved to backend: ${conversation.id}');
    } catch (e) {
      print('Failed to save conversation to backend: $e');
      rethrow;
    }
  }

  // Save individual message to backend
  static Future<void> _saveMessageToBackend(ChatMessage message) async {
    try {
      // Get the conversation first
      final conversation = await ConversationDbService.getConversation(message.conversationId);
      if (conversation != null) {
        // Update conversation with new message and save to backend
        final updatedConversation = conversation.addMessage(message);
        await _saveConversationToBackend(updatedConversation);
      }
    } catch (e) {
      print('Failed to save message to backend: $e');
      rethrow;
    }
  }

  // Cache conversation locally for quick access
  static Future<void> _cacheConversationLocally(Conversation conversation) async {
    try {
      // Check if conversation exists locally
      final existingConversation = await ConversationDbService.getConversation(conversation.id);
      
      if (existingConversation == null) {
        // Create new conversation locally
        await ConversationDbService.createConversation(conversation);
        
        // Add all messages
        for (final message in conversation.messages) {
          await ConversationDbService.addMessage(message);
        }
      } else {
        // Update existing conversation
        await ConversationDbService.updateConversation(conversation);
      }
      
      // Set as active if needed
      if (conversation.isActive) {
        await ConversationDbService.setActiveConversation(conversation.userId, conversation.id);
      }
    } catch (e) {
      print('Failed to cache conversation locally: $e');
      rethrow;
    }
  }

  // Sync backend conversations to local cache
  static Future<void> _syncBackendToLocal(List<dynamic> backendConversations) async {
    for (final conversationData in backendConversations) {
      try {
        final conversation = Conversation.fromJson(conversationData);
        await _cacheConversationLocally(conversation);
      } catch (e) {
        print('Failed to cache conversation from backend: $e');
      }
    }
  }

  // Clear conversations from backend
  static Future<void> _clearBackendConversations() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final conversations = await ApiService.getConversationHistory(userId);
      for (final conversation in conversations) {
        await ApiService.deleteConversation(conversation['id']);
      }
    } catch (e) {
      print('Failed to clear backend conversations: $e');
    }
  }

  // PERIODIC SYNC (called by app)

  // Full two-way sync with backend
  static Future<void> syncWithBackend() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      print('Starting conversation sync with backend...');

      // Get local conversations
      final localConversations = await ConversationDbService.getUserConversations(userId);
      
      // Prepare local conversation data for sync
      final localConversationData = <Map<String, dynamic>>[];
      for (final summary in localConversations) {
        final conversation = await ConversationDbService.getConversation(summary.id);
        if (conversation != null) {
          localConversationData.add(conversation.toJson());
        }
      }

      // Sync with backend
      final syncResult = await ApiService.syncConversations(
        userId: userId,
        localConversations: localConversationData,
      );

      print('Sync completed successfully: ${syncResult['synced_count']} conversations');
    } catch (e) {
      print('Failed to sync with backend: $e');
    }
  }

  // Clean up old conversations (keep only recent ones)
  static Future<void> cleanupOldConversations() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final conversations = await ConversationDbService.getUserConversations(userId);
      
      if (conversations.length > MAX_LOCAL_CONVERSATIONS) {
        // Sort by last updated and keep only the most recent
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        final conversationsToDelete = conversations.skip(MAX_LOCAL_CONVERSATIONS);
        for (final conversation in conversationsToDelete) {
          await ConversationDbService.deleteConversation(conversation.id);
        }
        
        print('Cleaned up ${conversationsToDelete.length} old conversations');
      }
    } catch (e) {
      print('Failed to cleanup old conversations: $e');
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
}

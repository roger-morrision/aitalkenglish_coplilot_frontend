import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';
import 'dart:convert';

class ConversationDbService {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'conversations.db'),
      onCreate: (db, version) async {
        // Conversations table
        await db.execute('''
          CREATE TABLE conversations(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_active INTEGER DEFAULT 0
          )
        ''');

        // Messages table
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            content TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            metadata TEXT,
            FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
          )
        ''');

        // Indexes for performance
        await db.execute('CREATE INDEX idx_conversations_user_id ON conversations(user_id)');
        await db.execute('CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC)');
        await db.execute('CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)');
        await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp DESC)');
      },
      version: 1,
    );
    return _db!;
  }

  // CONVERSATION CRUD OPERATIONS

  // Create a new conversation
  static Future<String> createConversation(Conversation conversation) async {
    final db = await getDb();
    await db.insert('conversations', {
      'id': conversation.id,
      'user_id': conversation.userId,
      'title': conversation.title,
      'created_at': conversation.createdAt.toIso8601String(),
      'updated_at': conversation.updatedAt.toIso8601String(),
      'is_active': conversation.isActive ? 1 : 0,
    });
    return conversation.id;
  }

  // Get all conversations for a user
  static Future<List<ConversationSummary>> getUserConversations(String userId) async {
    final db = await getDb();
    final result = await db.rawQuery('''
      SELECT 
        c.*,
        COUNT(m.id) as message_count,
        (
          SELECT content 
          FROM messages m2 
          WHERE m2.conversation_id = c.id 
          ORDER BY m2.timestamp DESC 
          LIMIT 1
        ) as last_message_content,
        (
          SELECT is_user 
          FROM messages m2 
          WHERE m2.conversation_id = c.id 
          ORDER BY m2.timestamp DESC 
          LIMIT 1
        ) as last_message_is_user
      FROM conversations c
      LEFT JOIN messages m ON c.id = m.conversation_id
      WHERE c.user_id = ?
      GROUP BY c.id
      ORDER BY c.updated_at DESC
    ''', [userId]);

    return result.map((row) {
      final lastContent = row['last_message_content'] as String?;
      final lastIsUser = row['last_message_is_user'] as int?;
      
      String lastMessagePreview = 'No messages yet';
      if (lastContent != null) {
        final preview = lastContent.length > 50 
            ? '${lastContent.substring(0, 50)}...'
            : lastContent;
        lastMessagePreview = (lastIsUser == 1) ? 'You: $preview' : preview;
      }

      return ConversationSummary(
        id: row['id'] as String,
        title: row['title'] as String,
        lastMessagePreview: lastMessagePreview,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        messageCount: row['message_count'] as int,
        isActive: (row['is_active'] as int) == 1,
      );
    }).toList();
  }

  // Get full conversation with messages
  static Future<Conversation?> getConversation(String conversationId) async {
    final db = await getDb();
    
    // Get conversation
    final conversationResult = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    if (conversationResult.isEmpty) return null;

    final conversationData = conversationResult.first;

    // Get messages
    final messagesResult = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    final messages = messagesResult.map((messageData) {
      return ChatMessage(
        id: messageData['id'] as String,
        conversationId: messageData['conversation_id'] as String,
        content: messageData['content'] as String,
        isUser: (messageData['is_user'] as int) == 1,
        timestamp: DateTime.parse(messageData['timestamp'] as String),
        metadata: messageData['metadata'] != null 
            ? jsonDecode(messageData['metadata'] as String)
            : null,
      );
    }).toList();

    return Conversation(
      id: conversationData['id'] as String,
      userId: conversationData['user_id'] as String,
      title: conversationData['title'] as String,
      createdAt: DateTime.parse(conversationData['created_at'] as String),
      updatedAt: DateTime.parse(conversationData['updated_at'] as String),
      messages: messages,
      isActive: (conversationData['is_active'] as int) == 1,
    );
  }

  // Update conversation
  static Future<void> updateConversation(Conversation conversation) async {
    final db = await getDb();
    await db.update(
      'conversations',
      {
        'title': conversation.title,
        'updated_at': conversation.updatedAt.toIso8601String(),
        'is_active': conversation.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  // Delete conversation and all its messages
  static Future<void> deleteConversation(String conversationId) async {
    final db = await getDb();
    await db.transaction((txn) async {
      await txn.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
      await txn.delete('conversations', where: 'id = ?', whereArgs: [conversationId]);
    });
  }

  // Set active conversation (deactivate others first)
  static Future<void> setActiveConversation(String userId, String conversationId) async {
    final db = await getDb();
    await db.transaction((txn) async {
      // Deactivate all conversations for user
      await txn.update(
        'conversations',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      // Activate the selected conversation
      await txn.update(
        'conversations',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });
  }

  // Get active conversation for user
  static Future<Conversation?> getActiveConversation(String userId) async {
    final db = await getDb();
    final result = await db.query(
      'conversations',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return getConversation(result.first['id'] as String);
  }

  // MESSAGE CRUD OPERATIONS

  // Add message to conversation
  static Future<String> addMessage(ChatMessage message) async {
    final db = await getDb();
    await db.transaction((txn) async {
      // Insert message
      await txn.insert('messages', {
        'id': message.id,
        'conversation_id': message.conversationId,
        'content': message.content,
        'is_user': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.toIso8601String(),
        'metadata': message.metadata != null ? jsonEncode(message.metadata) : null,
      });

      // Update conversation's updated_at timestamp
      await txn.update(
        'conversations',
        {'updated_at': message.timestamp.toIso8601String()},
        where: 'id = ?',
        whereArgs: [message.conversationId],
      );
    });
    return message.id;
  }

  // Update message metadata (for suggestions)
  static Future<void> updateMessageMetadata(String messageId, Map<String, dynamic> metadata) async {
    final db = await getDb();
    await db.update(
      'messages',
      {'metadata': jsonEncode(metadata)},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Get messages for a conversation
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await getDb();
    final result = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return result.map((messageData) {
      return ChatMessage(
        id: messageData['id'] as String,
        conversationId: messageData['conversation_id'] as String,
        content: messageData['content'] as String,
        isUser: (messageData['is_user'] as int) == 1,
        timestamp: DateTime.parse(messageData['timestamp'] as String),
        metadata: messageData['metadata'] != null 
            ? jsonDecode(messageData['metadata'] as String)
            : null,
      );
    }).toList();
  }

  // UTILITY METHODS

  // Clear all conversations for a user
  static Future<void> clearUserConversations(String userId) async {
    final db = await getDb();
    await db.transaction((txn) async {
      // Get conversation IDs to delete
      final conversations = await txn.query(
        'conversations',
        columns: ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Delete all messages for these conversations
      for (final conv in conversations) {
        await txn.delete(
          'messages',
          where: 'conversation_id = ?',
          whereArgs: [conv['id']],
        );
      }

      // Delete all conversations for user
      await txn.delete(
        'conversations',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  // Get conversation statistics
  static Future<Map<String, int>> getConversationStats(String userId) async {
    final db = await getDb();
    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT c.id) as total_conversations,
        COUNT(m.id) as total_messages,
        COUNT(CASE WHEN m.is_user = 1 THEN m.id END) as user_messages,
        COUNT(CASE WHEN m.is_user = 0 THEN m.id END) as ai_messages
      FROM conversations c
      LEFT JOIN messages m ON c.id = m.conversation_id
      WHERE c.user_id = ?
    ''', [userId]);

    final row = result.first;
    return {
      'total_conversations': row['total_conversations'] as int,
      'total_messages': row['total_messages'] as int,
      'user_messages': row['user_messages'] as int,
      'ai_messages': row['ai_messages'] as int,
    };
  }

  // Search conversations by title or message content
  static Future<List<ConversationSummary>> searchConversations(
    String userId, 
    String query,
  ) async {
    final db = await getDb();
    final result = await db.rawQuery('''
      SELECT DISTINCT
        c.*,
        COUNT(m.id) as message_count
      FROM conversations c
      LEFT JOIN messages m ON c.id = m.conversation_id
      WHERE c.user_id = ? AND (
        c.title LIKE ? OR 
        EXISTS (
          SELECT 1 FROM messages m2 
          WHERE m2.conversation_id = c.id AND m2.content LIKE ?
        )
      )
      GROUP BY c.id
      ORDER BY c.updated_at DESC
    ''', [userId, '%$query%', '%$query%']);

    return result.map((row) {
      return ConversationSummary(
        id: row['id'] as String,
        title: row['title'] as String,
        lastMessagePreview: 'Found: $query',
        updatedAt: DateTime.parse(row['updated_at'] as String),
        messageCount: row['message_count'] as int,
        isActive: (row['is_active'] as int) == 1,
      );
    }).toList();
  }
}

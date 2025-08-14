import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lesson.dart';
import '../config/api_config.dart';

class ApiService {
  // Cache for suggestions to avoid repeated calls
  static final Map<String, Map<String, dynamic>> _suggestionsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10); // Cache for 10 minutes
  
  // Production backend URL
  static String get baseUrl {
    return ApiConfig.baseUrl;
  }

  // Get progress metrics
  static Future<List<dynamic>> getProgress() async {
    final response = await http.get(Uri.parse('$baseUrl/progress')).timeout(ApiConfig.generalApiTimeout);
    return jsonDecode(response.body);
  }

  // Get lesson plan
  static Future<Map<String, dynamic>> getLesson() async {
    final response = await http.get(Uri.parse('$baseUrl/lesson')).timeout(ApiConfig.generalApiTimeout);
    return jsonDecode(response.body);
  }

  // Legacy method - now uses combined endpoint
  static Future<String> sendChatMessage(String message, {String? conversationId}) async {
    final result = await sendChatMessageWithSuggestions(
      message,
      conversationId: conversationId,
      includeSuggestions: false,
    );
    return result['reply'] ?? 'Error';
  }

  // Combined chat and suggestions to reduce API calls
  static Future<Map<String, dynamic>> sendChatMessageWithSuggestions(
    String message, {
    String? conversationId,
    bool includeSuggestions = true,
  }) async {
    print('=== API SERVICE COMBINED DEBUG ===');
    print('API Service: sendChatMessageWithSuggestions called with message: $message');
    print('API Service: includeSuggestions: $includeSuggestions');
    
    try {
      final uri = Uri.parse('$baseUrl/chat-with-suggestions');
      print('API Service: Making combined request to: $uri');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'conversation_id': conversationId,
          'include_suggestions': includeSuggestions,
        }),
      ).timeout(ApiConfig.chatTimeout); // Use chat timeout for combined call
      
      print('API Service: Combined response status: ${response.statusCode}');
      print('API Service: Combined response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        print('API Service: Successfully parsed combined response');
        print('=== END API SERVICE COMBINED DEBUG ===');
        return parsed;
      } else {
        print('API Service: Combined HTTP error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('API Service: Combined request failed with error: $e');
      print('API Service: Error type: ${e.runtimeType}');
      print('=== END API SERVICE COMBINED DEBUG ===');
      rethrow;
    }
  }

  // Legacy method - now uses combined endpoint
  static Future<String> checkGrammar(String sentence) async {
    final result = await sendChatMessageWithSuggestions(
      sentence,
      includeSuggestions: true,
    );
    // Extract grammar correction from suggestions
    if (result['suggestions'] != null) {
      final suggestions = result['suggestions'];
      if (suggestions['alternative_expressions'] != null) {
        final alternatives = suggestions['alternative_expressions'];
        if (alternatives is List && alternatives.isNotEmpty) {
          return alternatives.first.toString();
        }
      }
    }
    return result['reply'] ?? 'Error';
  }

  // Legacy method - now uses combined endpoint
  static Future<Map<String, dynamic>> getMessageSuggestions(String message) async {
    print('=== API SERVICE DEBUG ===');
    print('API Service: getMessageSuggestions called with message: $message');
    
    // Check cache first
    final cacheKey = message.toLowerCase().trim();
    if (_suggestionsCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        print('API Service: Returning cached result for: $message');
        print('=== END API SERVICE DEBUG ===');
        return _suggestionsCache[cacheKey]!;
      } else {
        // Remove expired cache
        _suggestionsCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    print('API Service: Making fresh request for: $message');
    
    try {
      // Use combined endpoint instead of separate suggestions endpoint
      final result = await sendChatMessageWithSuggestions(
        message,
        includeSuggestions: true,
      );
      
      // Extract suggestions from combined response
      final suggestions = result['suggestions'] ?? {};
      
      // Cache the result
      _suggestionsCache[cacheKey] = suggestions;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      print('API Service: Successfully parsed and cached response: $suggestions');
      print('=== END API SERVICE DEBUG ===');
      return suggestions;
    } catch (e) {
      print('API Service: Request failed with error: $e');
      print('API Service: Error type: ${e.runtimeType}');
      print('=== END API SERVICE DEBUG ===');
      rethrow; // Let the UI handle the error
    }
  }

  // Clear suggestions cache (useful for testing or memory management)
  static void clearSuggestionsCache() {
    _suggestionsCache.clear();
    _cacheTimestamps.clear();
    print('API Service: Suggestions cache cleared');
  }

  // Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'cached_items': _suggestionsCache.length,
      'expired_items': _cacheTimestamps.values
          .where((timestamp) => DateTime.now().difference(timestamp) >= _cacheExpiry)
          .length,
    };
  }

  // Get vocabulary list
  static Future<List<dynamic>> getVocab() async {
    final response = await http.get(Uri.parse('$baseUrl/vocab'));
    return jsonDecode(response.body);
  }

  // Add new vocab
  static Future<void> addVocab(String word, String meaning) async {
    await http.post(
      Uri.parse('$baseUrl/vocab'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'word': word, 'meaning': meaning}),
    );
  }

  // Get personalized lessons
  static Future<List<Lesson>> getLessons() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lessons'));
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((lessonData) => Lesson.fromMap(lessonData)).toList();
    } catch (e) {
      // Return mock data for demo purposes
      return _getMockLessons();
    }
  }

  static List<Lesson> _getMockLessons() {
    return [
      Lesson(
        id: 1,
        title: 'Past Tense Mastery',
        description: 'Master the use of past tense in English conversations and writing.',
        scheduledAt: DateTime.now(),
        difficulty: 'Beginner',
        topic: 'Grammar',
        skillType: 'Grammar',
        estimatedDuration: 15,
        rating: 4.2,
        completedBy: 1547,
      ),
      Lesson(
        id: 2,
        title: 'Business English Essentials',
        description: 'Learn key vocabulary and phrases for professional environments.',
        scheduledAt: DateTime.now(),
        difficulty: 'Intermediate',
        topic: 'Business',
        skillType: 'Vocabulary',
        estimatedDuration: 25,
        rating: 4.5,
        completedBy: 892,
      ),
      Lesson(
        id: 3,
        title: 'Travel Conversations',
        description: 'Practice common travel scenarios and vocabulary.',
        scheduledAt: DateTime.now(),
        difficulty: 'Intermediate',
        topic: 'Travel',
        skillType: 'Speaking',
        estimatedDuration: 20,
        rating: 4.3,
        completedBy: 2103,
      ),
      Lesson(
        id: 4,
        title: 'Advanced Reading Comprehension',
        description: 'Improve your reading skills with complex texts and analysis.',
        scheduledAt: DateTime.now(),
        difficulty: 'Advanced',
        topic: 'General',
        skillType: 'Reading',
        estimatedDuration: 30,
        rating: 4.1,
        completedBy: 456,
      ),
      Lesson(
        id: 5,
        title: 'Technology Vocabulary',
        description: 'Learn modern technology terms and concepts in English.',
        scheduledAt: DateTime.now(),
        difficulty: 'Intermediate',
        topic: 'Technology',
        skillType: 'Vocabulary',
        estimatedDuration: 15,
        rating: 4.4,
        completedBy: 1320,
      ),
      Lesson(
        id: 6,
        title: 'Listening Skills for Beginners',
        description: 'Develop your listening comprehension with simple dialogues.',
        scheduledAt: DateTime.now(),
        difficulty: 'Beginner',
        topic: 'General',
        skillType: 'Listening',
        estimatedDuration: 20,
        rating: 4.0,
        completedBy: 2845,
      ),
    ];
  }

  // Settings API methods for AI model selection
  
  // Get available AI models
  static Future<Map<String, dynamic>> getAvailableModels() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/models')).timeout(ApiConfig.generalApiTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend returns {available: [...], message: "..."}
      // Transform to expected format: {models: [...]}
      return {
        'models': data['available'] ?? [],
        'message': data['message'] ?? 'Available AI models for selection'
      };
    } else {
      throw Exception('Failed to load available models: ${response.body}');
    }
  }

  // Get current selected model
  static Future<Map<String, dynamic>> getCurrentModel() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/current-model')).timeout(ApiConfig.generalApiTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load current model: ${response.body}');
    }
  }

  // Select a new AI model
  static Future<Map<String, dynamic>> selectModel(String modelId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings/select-model'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model_id': modelId}),
    ).timeout(ApiConfig.generalApiTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to select model: ${response.body}');
    }
  }

  // Voice Settings API methods
  
  // Get current voice settings
  static Future<Map<String, dynamic>> getVoiceSettings() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/voice')).timeout(ApiConfig.generalApiTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load voice settings: ${response.body}');
    }
  }

  // Update voice settings
  static Future<Map<String, dynamic>> updateVoiceSettings({
    required bool voiceAutoplayEnabled,
    required bool voiceInputEnabled,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings/voice'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'voice_autoplay_enabled': voiceAutoplayEnabled,
        'voice_input_enabled': voiceInputEnabled,
      }),
    ).timeout(ApiConfig.generalApiTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update voice settings: ${response.body}');
    }
  }

  // CONVERSATION HISTORY API METHODS

  // Save conversation to backend
  static Future<Map<String, dynamic>> saveConversation({
    required String conversationId,
    required String userId,
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    print('ApiService: Saving conversation $conversationId');
    print('ApiService: User ID: $userId');
    print('ApiService: Title: $title');
    print('ApiService: Messages count: ${messages.length}');
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      print('ApiService: Message $i: isUser=${msg['is_user']}, content="${msg['content']}"');
    }
    
    final requestBody = {
      'conversation_id': conversationId,
      'user_id': userId,
      'title': title,
      'messages': messages,
    };
    
    print('ApiService: Request body: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(ApiConfig.generalApiTimeout);
    
    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save conversation: ${response.body}');
    }
  }

  // Get user's conversation history
  static Future<List<dynamic>> getConversationHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$userId'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load conversation history: ${response.body}');
    }
  }

  // Get specific conversation with messages
  static Future<Map<String, dynamic>> getConversation(String conversationId) async {
    final url = '$baseUrl/conversations/details/$conversationId';
    print('ApiService: Getting conversation from URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
    ).timeout(ApiConfig.generalApiTimeout);
    
    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('ApiService: Parsed JSON data: $data');
      return data;
    } else {
      throw Exception('Failed to load conversation: ${response.body}');
    }
  }

  // Update conversation title
  static Future<Map<String, dynamic>> updateConversationTitle({
    required String conversationId,
    required String newTitle,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/conversations/$conversationId/title'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': newTitle}),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update conversation title: ${response.body}');
    }
  }

  // Delete conversation
  static Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/conversations/$conversationId'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete conversation: ${response.body}');
    }
  }

  // Activate conversation
  static Future<Map<String, dynamic>> activateConversation({
    required String conversationId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations/$conversationId/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to activate conversation: ${response.body}');
    }
  }

  // Search conversations
  static Future<List<dynamic>> searchConversations(String userId, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$userId/search?q=${Uri.encodeComponent(query)}'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search conversations: ${response.body}');
    }
  }

  // Sync local conversations with backend
  static Future<Map<String, dynamic>> syncConversations({
    required String userId,
    required List<Map<String, dynamic>> localConversations,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'local_conversations': localConversations,
      }),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync conversations: ${response.body}');
    }
  }

  // USER PROGRESS AND ACHIEVEMENTS API METHODS

  // Get user progress
  static Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/progress'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user progress: ${response.body}');
    }
  }

  // Save user progress
  static Future<Map<String, dynamic>> saveUserProgress(String userId, Map<String, dynamic> progressData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(progressData),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save user progress: ${response.body}');
    }
  }

  // Track message submission for progress
  static Future<Map<String, dynamic>> trackMessageSubmission({
    required String userId,
    required String messageContent,
    required String messageType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/track-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message_content': messageContent,
        'message_type': messageType,
      }),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to track message: ${response.body}');
    }
  }

  // Get user achievements
  static Future<List<dynamic>> getUserAchievements(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/achievements'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['achievements'] ?? [];
    } else {
      throw Exception('Failed to load user achievements: ${response.body}');
    }
  }

  // Add user achievement
  static Future<Map<String, dynamic>> addUserAchievement({
    required String userId,
    required String achievementId,
    required String title,
    required String description,
    required String iconName,
    required String achievementType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/achievements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'achievement_id': achievementId,
        'title': title,
        'description': description,
        'icon_name': iconName,
        'achievement_type': achievementType,
      }),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add achievement: ${response.body}');
    }
  }

  // USER SETTINGS API METHODS

  // Get user settings
  static Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/settings'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['settings'] ?? {};
    } else {
      throw Exception('Failed to load user settings: ${response.body}');
    }
  }

  // Save user settings
  static Future<Map<String, dynamic>> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save user settings: ${response.body}');
    }
  }

  // GRAMMAR STUDY API METHODS

  // Get all grammar categories
  static Future<List<dynamic>> getGrammarCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/grammar/categories'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both formats: {categories: [...]} or directly [...]
      if (data is List) {
        return data;
      } else if (data is Map && data['categories'] != null) {
        return data['categories'];
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load grammar categories: ${response.body}');
    }
  }

  // Get topics for a specific category
  static Future<List<dynamic>> getGrammarTopics(String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grammar/categories/$categoryId/topics'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both formats: {topics: [...]} or directly [...]
      if (data is List) {
        return data;
      } else if (data is Map && data['topics'] != null) {
        return data['topics'];
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load grammar topics: ${response.body}');
    }
  }

  // Get exercises for a specific topic
  static Future<List<dynamic>> getGrammarExercises(String topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grammar/topics/$topicId/exercises'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both formats: {exercises: [...]} or directly [...]
      if (data is List) {
        return data;
      } else if (data is Map && data['exercises'] != null) {
        return data['exercises'];
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load grammar exercises: ${response.body}');
    }
  }

  // Get complete grammar data structure (categories with topics and exercises)
  static Future<List<dynamic>> getCompleteGrammarData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/grammar/complete'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both formats: {categories: [...]} or directly [...]
      if (data is List) {
        return data;
      } else if (data is Map && data['categories'] != null) {
        return data['categories'];
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load complete grammar data: ${response.body}');
    }
  }

  // Save user grammar study result
  static Future<Map<String, dynamic>> saveGrammarStudyResult({
    required String userId,
    required String categoryId,
    required String topicId,
    required String exerciseId,
    required bool isCorrect,
    int? selectedAnswer,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/grammar/exercise/$exerciseId/result'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isCorrect': isCorrect,
        'selectedAnswer': selectedAnswer,
        'topicId': topicId,
        'categoryId': categoryId,
      }),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save grammar study result: ${response.body}');
    }
  }

  // Get exercises with user progress for a topic
  static Future<List<dynamic>> getGrammarExercisesWithProgress(String userId, String topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/grammar/topic/$topicId/exercises-with-progress'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exercises'] ?? [];
    } else {
      throw Exception('Failed to load exercises with progress: ${response.body}');
    }
  }

  // Get user grammar study statistics
  static Future<Map<String, dynamic>> getUserGrammarStats(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/grammar/stats'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load grammar stats: ${response.body}');
    }
  }

  // Get grammar topic explanation and examples
  static Future<Map<String, dynamic>> getGrammarTopicExplanation(String topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grammar/topics/$topicId/explanation'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load topic explanation: ${response.body}');
    }
  }

  // Get user grammar study results
  static Future<List<dynamic>> getUserGrammarStudyResults(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/grammar-study'),
    ).timeout(ApiConfig.generalApiTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load grammar study results: ${response.body}');
    }
  }
}

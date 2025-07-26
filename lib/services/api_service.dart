import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lesson.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ApiService {
  // Use configuration-based URL
  static String get baseUrl {
    return ApiConfig.baseUrl;
  }

  // Get progress metrics
  static Future<List<dynamic>> getProgress() async {
    final response = await http.get(Uri.parse('$baseUrl/progress'));
    return jsonDecode(response.body);
  }

  // Get lesson plan
  static Future<Map<String, dynamic>> getLesson() async {
    final response = await http.get(Uri.parse('$baseUrl/lesson'));
    return jsonDecode(response.body);
  }

  // Chat with AI
  static Future<String> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    final data = jsonDecode(response.body);
    return data['reply'] ?? 'Error';
  }

  // Grammar correction
  static Future<String> checkGrammar(String sentence) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grammar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sentence': sentence}),
    );
    final data = jsonDecode(response.body);
    return data['correction'] ?? 'Error';
  }

  // Get message suggestions (grammar, better versions, vocabulary)
  static Future<Map<String, dynamic>> getMessageSuggestions(String message) async {
    print('=== API SERVICE DEBUG ===');
    print('API Service: getMessageSuggestions called with message: $message');
    print('API Service: Using baseUrl: $baseUrl');
    print('API Service: Running on web: $kIsWeb');
    
    try {
      final uri = Uri.parse('$baseUrl/suggestions');
      print('API Service: Making request to: $uri');
      
      // Use the same simple configuration as working chat endpoint
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );
      
      print('API Service: Response status: ${response.statusCode}');
      print('API Service: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        print('API Service: Successfully parsed response: $parsed');
        print('=== END API SERVICE DEBUG ===');
        return parsed;
      } else {
        print('API Service: HTTP error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('API Service: Request failed with error: $e');
      print('API Service: Error type: ${e.runtimeType}');
      print('=== END API SERVICE DEBUG ===');
      rethrow; // Let the UI handle the error
    }
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
    final response = await http.get(Uri.parse('$baseUrl/settings/models'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load available models: ${response.body}');
    }
  }

  // Get current selected model
  static Future<Map<String, dynamic>> getCurrentModel() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/current-model'));
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
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to select model: ${response.body}');
    }
  }

  // Voice Settings API methods
  
  // Get current voice settings
  static Future<Map<String, dynamic>> getVoiceSettings() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/voice'));
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
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update voice settings: ${response.body}');
    }
  }
}

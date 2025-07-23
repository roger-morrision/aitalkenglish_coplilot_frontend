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
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

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
}

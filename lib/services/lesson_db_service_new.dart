// This service now uses backend APIs instead of local database
import '../models/lesson.dart';
import 'api_service.dart';

class LessonDbService {
  // These methods now use backend APIs instead of local database
  
  static Future<void> init() async {
    // No local database initialization needed
    print('LessonDbService: Initialized (backend-only mode)');
  }

  // Lesson methods using backend APIs
  static Future<List<Lesson>> getLessons() async {
    try {
      return await ApiService.getLessons();
    } catch (e) {
      print('LessonDbService: Failed to get lessons from backend: $e');
      return [];
    }
  }

  static Future<int> addLesson(Lesson lesson) async {
    print('LessonDbService: Local lesson creation not supported - use backend APIs');
    return 0; // Return placeholder ID
  }

  static Future<void> completeLesson(int id) async {
    print('LessonDbService: Lesson completion tracking moved to progress service');
    // Lesson completion is now tracked via progress service
  }

  // Legacy methods kept for compatibility
  static Future<int> updateStreak(DateTime date, int count) async {
    print('LessonDbService: Streak tracking moved to progress service');
    return 0;
  }

  static Future<int> getCurrentStreak() async {
    print('LessonDbService: Streak tracking moved to progress service');
    return 0;
  }

  static Future<int> addBadge(String name, String description, String icon) async {
    print('LessonDbService: Badge management moved to progress service');
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getBadges() async {
    print('LessonDbService: Badge management moved to progress service');
    return [];
  }
}

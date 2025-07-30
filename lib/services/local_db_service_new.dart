// This service is kept for compatibility but no longer stores data locally.
// All data is now stored in the backend via API calls.

class LocalDbService {
  // These methods are kept for compatibility but do not store data locally
  // All data is now handled by backend APIs
  
  static Future<void> init() async {
    // No initialization needed - all data is in backend
    print('LocalDbService: Initialized (backend-only mode)');
  }

  // Vocab methods - redirect to backend or return empty data
  static Future<int> addVocab(String word, String meaning) async {
    print('LocalDbService: Vocab operations moved to backend APIs');
    return 0; // Return placeholder ID
  }

  static Future<List<Map<String, dynamic>>> getVocab() async {
    print('LocalDbService: Vocab operations moved to backend APIs');
    return []; // Return empty list
  }

  static Future<int> deleteVocab(int id) async {
    print('LocalDbService: Vocab operations moved to backend APIs');
    return 0;
  }

  // Progress methods - redirect to backend or return empty data
  static Future<int> addProgress(int score, int streak) async {
    print('LocalDbService: Progress operations moved to backend APIs');
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getProgress() async {
    print('LocalDbService: Progress operations moved to backend APIs');
    return [];
  }
}

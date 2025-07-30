import 'dart:convert';
import '../models/user_progress.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  // Save user progress to backend
  static Future<void> saveProgress(UserProgress progress) async {
    try {
      await ApiService.saveUserProgress(progress.userId, progress.toJson());
      print('ProgressService: Progress saved to backend successfully');
    } catch (e) {
      print('ProgressService: Failed to save progress to backend: $e');
      throw e;
    }
  }

  // Load user progress from backend
  static Future<UserProgress> loadProgress(String userId) async {
    try {
      final response = await ApiService.getUserProgress(userId);
      final progressData = response['progress'];
      
      if (progressData != null) {
        // Convert backend format to frontend format
        final convertedData = _convertBackendToFrontend(progressData);
        return UserProgress.fromJson(convertedData);
      }
    } catch (e) {
      print('ProgressService: Failed to load progress from backend: $e');
    }
    
    // Return default progress for new users or on error
    return UserProgress(
      userId: userId,
      lastActivity: DateTime.now(),
      skillProgress: {
        'vocabulary': 0,
        'grammar': 0,
        'speaking': 0,
        'writing': 0,
      },
      weeklyStats: {
        'messagesThisWeek': 0,
        'lessonsThisWeek': 0,
        'streakThisWeek': 0,
      },
    );
  }

  // Convert backend snake_case format to frontend camelCase format
  static Map<String, dynamic> _convertBackendToFrontend(Map<String, dynamic> backendData) {
    return {
      'userId': backendData['user_id'] ?? '',
      'streak': backendData['streak'] ?? 0,
      'totalMessages': backendData['total_messages'] ?? 0,
      'vocabularyLevel': backendData['vocabulary_level'] ?? 1,
      'grammarLevel': backendData['grammar_level'] ?? 1,
      'speakingLevel': backendData['speaking_level'] ?? 1,
      'writingLevel': backendData['writing_level'] ?? 1,
      'lessonsCompleted': backendData['lessons_completed'] ?? 0,
      'badgesEarned': backendData['badges_earned'] ?? 0,
      'lastActivity': backendData['last_activity'] ?? DateTime.now().toIso8601String(),
      'recentAchievements': [],
      'weeklyStats': backendData['weekly_stats'] is String 
          ? jsonDecode(backendData['weekly_stats']) 
          : (backendData['weekly_stats'] ?? {}),
      'skillProgress': backendData['skill_progress'] is String 
          ? jsonDecode(backendData['skill_progress']) 
          : (backendData['skill_progress'] ?? {}),
    };
  }

  // Track user message submission using backend API
  static Future<UserProgress> trackMessageSubmission(
    UserProgress currentProgress,
    String messageContent,
    String messageType, // 'chat', 'grammar', 'vocabulary', etc.
  ) async {
    print('ProgressService: Tracking message submission via backend API...');
    print('Current progress: ${currentProgress.totalMessages} messages, streak: ${currentProgress.streak}');
    
    try {
      // Use backend API to track message
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final response = await ApiService.trackMessageSubmission(
          userId: user.uid,
          messageContent: messageContent,
          messageType: messageType,
        );
        
        if (response['success'] == true && response['progress'] != null) {
          // Convert backend response to UserProgress
          final updatedProgressData = _convertBackendToFrontend(response['progress']);
          final updatedProgress = UserProgress.fromJson(updatedProgressData);
          
          print('ProgressService: Message tracked successfully, new progress: ${updatedProgress.totalMessages} messages, streak: ${updatedProgress.streak}');
          
          // Check for new achievements
          await _checkForNewAchievements(updatedProgress);
          
          return updatedProgress;
        }
      }
    } catch (e) {
      print('ProgressService: Failed to track message via backend API: $e');
    }
    
    // Return current progress if backend tracking fails
    return currentProgress;
  }

  // Check for achievements using backend data
  static Future<void> _checkForNewAchievements(UserProgress progress) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newAchievements = <Achievement>[];

      // Streak achievements
      if (progress.streak >= 5 && !await _hasAchievement('streak_5')) {
        newAchievements.add(Achievement(
          id: 'streak_5',
          title: '5-Day Streak',
          description: 'Learned for 5 days in a row!',
          iconName: 'local_fire_department',
          earnedDate: DateTime.now(),
          type: AchievementType.streak,
        ));
      }

      if (progress.streak >= 10 && !await _hasAchievement('streak_10')) {
        newAchievements.add(Achievement(
          id: 'streak_10',
          title: '10-Day Streak',
          description: 'Amazing consistency!',
          iconName: 'local_fire_department',
          earnedDate: DateTime.now(),
          type: AchievementType.streak,
        ));
      }

      // Message achievements
      if (progress.totalMessages >= 50 && !await _hasAchievement('chatty_learner')) {
        newAchievements.add(Achievement(
          id: 'chatty_learner',
          title: 'Chatty Learner',
          description: 'Sent 50 messages!',
          iconName: 'chat',
          earnedDate: DateTime.now(),
          type: AchievementType.general,
        ));
      }

      // Skill-based achievements
      final vocabScore = progress.skillProgress['vocabulary'] ?? 0;
      if (vocabScore >= 100 && !await _hasAchievement('vocab_master')) {
        newAchievements.add(Achievement(
          id: 'vocab_master',
          title: 'Vocabulary Master',
          description: 'Excellent vocabulary progress!',
          iconName: 'book',
          earnedDate: DateTime.now(),
          type: AchievementType.vocabulary,
        ));
      }

      if (newAchievements.isNotEmpty) {
        await _saveNewAchievements(newAchievements);
      }
    } catch (e) {
      print('ProgressService: Error checking achievements: $e');
    }
  }

  // Save new achievements to backend
  static Future<void> _saveNewAchievements(List<Achievement> achievements) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      for (final achievement in achievements) {
        await ApiService.addUserAchievement(
          userId: user.uid,
          achievementId: achievement.id,
          title: achievement.title,
          description: achievement.description,
          iconName: achievement.iconName,
          achievementType: achievement.type.toString(),
        );
      }
      
      print('ProgressService: ${achievements.length} new achievements saved to backend');
    } catch (e) {
      print('ProgressService: Failed to save achievements to backend: $e');
    }
  }

  // Load user achievements from backend
  static Future<List<Achievement>> loadAchievements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final achievementsData = await ApiService.getUserAchievements(user.uid);
      
      return achievementsData.map<Achievement>((data) {
        return Achievement(
          id: data['achievement_id'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          iconName: data['icon_name'] ?? 'star',
          earnedDate: DateTime.tryParse(data['earned_date'] ?? '') ?? DateTime.now(),
          type: AchievementType.values.firstWhere(
            (e) => e.toString() == data['achievement_type'],
            orElse: () => AchievementType.general,
          ),
        );
      }).toList();
    } catch (e) {
      print('ProgressService: Failed to load achievements from backend: $e');
      return [];
    }
  }

  // Check if user has specific achievement
  static Future<bool> _hasAchievement(String achievementId) async {
    final achievements = await loadAchievements();
    return achievements.any((a) => a.id == achievementId);
  }

  // Generate skill analysis
  static Future<List<SkillAnalysis>> generateSkillAnalysis(UserProgress progress) async {
    final analyses = <SkillAnalysis>[];
    
    // Vocabulary analysis
    final vocabScore = progress.skillProgress['vocabulary'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Vocabulary',
      currentLevel: (vocabScore / 10).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(vocabScore),
      strengthAreas: _getStrengthAreas('vocabulary', vocabScore),
      improvementAreas: _getImprovementAreas('vocabulary', vocabScore),
      recommendation: _getRecommendation('vocabulary', vocabScore),
    ));

    // Grammar analysis
    final grammarScore = progress.skillProgress['grammar'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Grammar',
      currentLevel: (grammarScore / 10).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(grammarScore),
      strengthAreas: _getStrengthAreas('grammar', grammarScore),
      improvementAreas: _getImprovementAreas('grammar', grammarScore),
      recommendation: _getRecommendation('grammar', grammarScore),
    ));

    // Speaking analysis
    final speakingScore = progress.skillProgress['speaking'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Speaking',
      currentLevel: (speakingScore / 10).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(speakingScore),
      strengthAreas: _getStrengthAreas('speaking', speakingScore),
      improvementAreas: _getImprovementAreas('speaking', speakingScore),
      recommendation: _getRecommendation('speaking', speakingScore),
    ));

    // Writing analysis
    final writingScore = progress.skillProgress['writing'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Writing',
      currentLevel: (writingScore / 10).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(writingScore),
      strengthAreas: _getStrengthAreas('writing', writingScore),
      improvementAreas: _getImprovementAreas('writing', writingScore),
      recommendation: _getRecommendation('writing', writingScore),
    ));

    return analyses;
  }

  static double _calculateImprovementPercentage(int score) {
    // Simple calculation based on score
    if (score < 10) return 5.0;
    if (score < 50) return 15.0;
    if (score < 100) return 25.0;
    return 35.0;
  }

  static List<String> _getStrengthAreas(String skill, int score) {
    if (score >= 50) {
      switch (skill) {
        case 'vocabulary':
          return ['Word Recognition', 'Context Understanding'];
        case 'grammar':
          return ['Sentence Structure', 'Tense Usage'];
        case 'speaking':
          return ['Pronunciation', 'Fluency'];
        case 'writing':
          return ['Spelling', 'Expression'];
      }
    }
    return ['Basic Understanding'];
  }

  static List<String> _getImprovementAreas(String skill, int score) {
    if (score < 50) {
      switch (skill) {
        case 'vocabulary':
          return ['Advanced Words', 'Idioms'];
        case 'grammar':
          return ['Complex Structures', 'Articles'];
        case 'speaking':
          return ['Confidence', 'Natural Flow'];
        case 'writing':
          return ['Advanced Grammar', 'Style'];
      }
    }
    return ['Consistency'];
  }

  static String _getRecommendation(String skill, int score) {
    switch (skill) {
      case 'vocabulary':
        return score < 50 ? 'Read more English content daily' : 'Practice using new words in sentences';
      case 'grammar':
        return score < 50 ? 'Focus on basic grammar rules' : 'Study advanced grammar patterns';
      case 'speaking':
        return score < 50 ? 'Practice speaking with AI daily' : 'Work on natural conversation flow';
      case 'writing':
        return score < 50 ? 'Write simple sentences daily' : 'Practice complex writing structures';
      default:
        return 'Keep practicing regularly';
    }
  }
}

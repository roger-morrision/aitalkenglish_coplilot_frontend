import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';

class ProgressService {
  static const String _progressKey = 'user_progress';
  static const String _achievementsKey = 'user_achievements';

  // Save user progress
  static Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  // Load user progress
  static Future<UserProgress> loadProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);
    
    if (progressJson != null) {
      return UserProgress.fromJson(jsonDecode(progressJson));
    }
    
    // Return default progress for new users
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

  // Track user message submission
  static Future<UserProgress> trackMessageSubmission(
    UserProgress currentProgress,
    String messageContent,
    String messageType, // 'chat', 'grammar', 'vocabulary', etc.
  ) async {
    print('ProgressService: Tracking message submission...');
    print('Current progress: ${currentProgress.totalMessages} messages, streak: ${currentProgress.streak}');
    
    final now = DateTime.now();
    final updatedProgress = currentProgress.copyWith(
      totalMessages: currentProgress.totalMessages + 1,
      lastActivity: now,
    );

    // Analyze message for skill improvements
    final skillGains = _analyzeMessageForSkills(messageContent, messageType);
    print('ProgressService: Skill gains calculated: $skillGains');
    
    // Update skill progress
    final newSkillProgress = Map<String, int>.from(currentProgress.skillProgress);
    skillGains.forEach((skill, gain) {
      newSkillProgress[skill] = (newSkillProgress[skill] ?? 0) + gain;
    });
    print('ProgressService: Updated skill progress: $newSkillProgress');

    // Update weekly stats
    final weeklyStats = Map<String, dynamic>.from(currentProgress.weeklyStats);
    weeklyStats['messagesThisWeek'] = (weeklyStats['messagesThisWeek'] ?? 0) + 1;

    // Check for streak updates
    final daysSinceLastActivity = now.difference(currentProgress.lastActivity).inDays;
    int newStreak = currentProgress.streak;
    
    if (daysSinceLastActivity == 1) {
      newStreak++; // Continue streak
    } else if (daysSinceLastActivity > 1) {
      newStreak = 1; // Reset streak
    }
    // If same day, keep current streak

    final finalProgress = updatedProgress.copyWith(
      streak: newStreak,
      skillProgress: newSkillProgress,
      weeklyStats: weeklyStats,
    );

    print('ProgressService: Final progress - Messages: ${finalProgress.totalMessages}, Streak: ${finalProgress.streak}');
    await saveProgress(finalProgress);
    await _checkForNewAchievements(finalProgress);
    
    print('ProgressService: Progress saved successfully');
    return finalProgress;
  }

  // Analyze message content for skill improvements
  static Map<String, int> _analyzeMessageForSkills(String content, String type) {
    final skills = <String, int>{};
    
    // Basic analysis - in a real app, you'd use more sophisticated NLP
    final wordCount = content.trim().split(' ').length;
    
    switch (type) {
      case 'chat':
        skills['speaking'] = (wordCount / 10).ceil(); // Speaking improvement
        skills['vocabulary'] = (wordCount / 15).ceil(); // Vocabulary usage
        break;
      case 'grammar':
        skills['grammar'] = (wordCount / 8).ceil();
        skills['writing'] = (wordCount / 12).ceil();
        break;
      case 'vocabulary':
        skills['vocabulary'] = (wordCount / 5).ceil();
        break;
      case 'lesson':
        skills['grammar'] = 1;
        skills['vocabulary'] = 1;
        skills['writing'] = 1;
        break;
    }
    
    return skills;
  }

  // Check and award new achievements
  static Future<void> _checkForNewAchievements(UserProgress progress) async {
    final newAchievements = <Achievement>[];
    
    // Streak achievements
    if (progress.streak >= 7 && !await _hasAchievement('week_streak')) {
      newAchievements.add(Achievement(
        id: 'week_streak',
        title: 'Week Warrior',
        description: 'Keep a 7-day learning streak!',
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
  }

  // Save new achievements
  static Future<void> _saveNewAchievements(List<Achievement> achievements) async {
    final existingAchievements = await loadAchievements();
    existingAchievements.addAll(achievements);
    
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = achievements.map((a) => a.toJson()).toList();
    await prefs.setString(_achievementsKey, jsonEncode(achievementsJson));
  }

  // Load user achievements
  static Future<List<Achievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString(_achievementsKey);
    
    if (achievementsJson != null) {
      final List<dynamic> achievementsList = jsonDecode(achievementsJson);
      return achievementsList.map((json) => Achievement.fromJson(json)).toList();
    }
    
    return [];
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
      currentLevel: (vocabScore / 20).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(vocabScore),
      strengthAreas: vocabScore > 50 ? ['Word usage', 'Context understanding'] : [],
      improvementAreas: vocabScore < 30 ? ['Expand word bank', 'Practice synonyms'] : [],
      recommendation: _getVocabularyRecommendation(vocabScore),
    ));

    // Grammar analysis
    final grammarScore = progress.skillProgress['grammar'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Grammar',
      currentLevel: (grammarScore / 20).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(grammarScore),
      strengthAreas: grammarScore > 50 ? ['Sentence structure', 'Tense usage'] : [],
      improvementAreas: grammarScore < 30 ? ['Basic grammar rules', 'Sentence formation'] : [],
      recommendation: _getGrammarRecommendation(grammarScore),
    ));

    // Speaking analysis
    final speakingScore = progress.skillProgress['speaking'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Speaking',
      currentLevel: (speakingScore / 20).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(speakingScore),
      strengthAreas: speakingScore > 50 ? ['Conversation flow', 'Natural expressions'] : [],
      improvementAreas: speakingScore < 30 ? ['Pronunciation', 'Fluency'] : [],
      recommendation: _getSpeakingRecommendation(speakingScore),
    ));

    // Writing analysis
    final writingScore = progress.skillProgress['writing'] ?? 0;
    analyses.add(SkillAnalysis(
      skillName: 'Writing',
      currentLevel: (writingScore / 20).clamp(0.0, 10.0),
      improvementPercentage: _calculateImprovementPercentage(writingScore),
      strengthAreas: writingScore > 50 ? ['Clarity', 'Structure'] : [],
      improvementAreas: writingScore < 30 ? ['Basic writing skills', 'Coherence'] : [],
      recommendation: _getWritingRecommendation(writingScore),
    ));

    return analyses;
  }

  static double _calculateImprovementPercentage(int score) {
    // Simple calculation - in real app, compare with previous periods
    return (score * 2.5).clamp(0.0, 100.0);
  }

  static String _getVocabularyRecommendation(int score) {
    if (score < 20) return 'Focus on learning 5 new words daily through our vocabulary exercises.';
    if (score < 50) return 'Great progress! Try using new words in conversations.';
    return 'Excellent vocabulary! Challenge yourself with advanced word usage.';
  }

  static String _getGrammarRecommendation(int score) {
    if (score < 20) return 'Start with basic grammar lessons to build a strong foundation.';
    if (score < 50) return 'Good improvement! Practice complex sentence structures.';
    return 'Outstanding grammar skills! Focus on advanced writing techniques.';
  }

  static String _getSpeakingRecommendation(int score) {
    if (score < 20) return 'Practice speaking daily with our AI chatbot to build confidence.';
    if (score < 50) return 'Great speaking progress! Try longer conversations.';
    return 'Excellent speaking skills! Focus on advanced topics and nuances.';
  }

  static String _getWritingRecommendation(int score) {
    if (score < 20) return 'Start with short writing exercises to develop basic skills.';
    if (score < 50) return 'Good writing development! Practice different text types.';
    return 'Superb writing abilities! Experiment with creative and professional writing.';
  }
}

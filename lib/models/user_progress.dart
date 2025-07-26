class UserProgress {
  final String userId;
  final int streak;
  final int totalMessages;
  final int vocabularyLevel;
  final int grammarLevel;
  final int speakingLevel;
  final int writingLevel;
  final int lessonsCompleted;
  final int badgesEarned;
  final DateTime lastActivity;
  final List<String> recentAchievements;
  final Map<String, dynamic> weeklyStats;
  final Map<String, int> skillProgress;

  UserProgress({
    required this.userId,
    this.streak = 0,
    this.totalMessages = 0,
    this.vocabularyLevel = 1,
    this.grammarLevel = 1,
    this.speakingLevel = 1,
    this.writingLevel = 1,
    this.lessonsCompleted = 0,
    this.badgesEarned = 0,
    required this.lastActivity,
    this.recentAchievements = const [],
    this.weeklyStats = const {},
    this.skillProgress = const {},
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      streak: json['streak'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      vocabularyLevel: json['vocabularyLevel'] ?? 1,
      grammarLevel: json['grammarLevel'] ?? 1,
      speakingLevel: json['speakingLevel'] ?? 1,
      writingLevel: json['writingLevel'] ?? 1,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      badgesEarned: json['badgesEarned'] ?? 0,
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
      recentAchievements: List<String>.from(json['recentAchievements'] ?? []),
      weeklyStats: Map<String, dynamic>.from(json['weeklyStats'] ?? {}),
      skillProgress: Map<String, int>.from(json['skillProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'streak': streak,
      'totalMessages': totalMessages,
      'vocabularyLevel': vocabularyLevel,
      'grammarLevel': grammarLevel,
      'speakingLevel': speakingLevel,
      'writingLevel': writingLevel,
      'lessonsCompleted': lessonsCompleted,
      'badgesEarned': badgesEarned,
      'lastActivity': lastActivity.toIso8601String(),
      'recentAchievements': recentAchievements,
      'weeklyStats': weeklyStats,
      'skillProgress': skillProgress,
    };
  }

  UserProgress copyWith({
    String? userId,
    int? streak,
    int? totalMessages,
    int? vocabularyLevel,
    int? grammarLevel,
    int? speakingLevel,
    int? writingLevel,
    int? lessonsCompleted,
    int? badgesEarned,
    DateTime? lastActivity,
    List<String>? recentAchievements,
    Map<String, dynamic>? weeklyStats,
    Map<String, int>? skillProgress,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      streak: streak ?? this.streak,
      totalMessages: totalMessages ?? this.totalMessages,
      vocabularyLevel: vocabularyLevel ?? this.vocabularyLevel,
      grammarLevel: grammarLevel ?? this.grammarLevel,
      speakingLevel: speakingLevel ?? this.speakingLevel,
      writingLevel: writingLevel ?? this.writingLevel,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      lastActivity: lastActivity ?? this.lastActivity,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      skillProgress: skillProgress ?? this.skillProgress,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime earnedDate;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.earnedDate,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'star',
      earnedDate: DateTime.tryParse(json['earnedDate'] ?? '') ?? DateTime.now(),
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AchievementType.general,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'earnedDate': earnedDate.toIso8601String(),
      'type': type.toString(),
    };
  }
}

enum AchievementType {
  streak,
  vocabulary,
  grammar,
  speaking,
  writing,
  lessons,
  general,
}

class SkillAnalysis {
  final String skillName;
  final double currentLevel;
  final double improvementPercentage;
  final List<String> strengthAreas;
  final List<String> improvementAreas;
  final String recommendation;

  SkillAnalysis({
    required this.skillName,
    required this.currentLevel,
    required this.improvementPercentage,
    required this.strengthAreas,
    required this.improvementAreas,
    required this.recommendation,
  });

  factory SkillAnalysis.fromJson(Map<String, dynamic> json) {
    return SkillAnalysis(
      skillName: json['skillName'] ?? '',
      currentLevel: (json['currentLevel'] ?? 0.0).toDouble(),
      improvementPercentage: (json['improvementPercentage'] ?? 0.0).toDouble(),
      strengthAreas: List<String>.from(json['strengthAreas'] ?? []),
      improvementAreas: List<String>.from(json['improvementAreas'] ?? []),
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillName': skillName,
      'currentLevel': currentLevel,
      'improvementPercentage': improvementPercentage,
      'strengthAreas': strengthAreas,
      'improvementAreas': improvementAreas,
      'recommendation': recommendation,
    };
  }
}

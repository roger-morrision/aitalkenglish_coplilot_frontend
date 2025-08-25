class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double priceMonthly;
  final double? priceYearly;
  final List<String> features;
  final int maxDailyMessages;
  final int maxMonthlyMessages;
  final List<String> grammarCategoriesAccess;
  final bool isActive;
  final DateTime createdAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMonthly,
    this.priceYearly,
    required this.features,
    required this.maxDailyMessages,
    required this.maxMonthlyMessages,
    required this.grammarCategoriesAccess,
    required this.isActive,
    required this.createdAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      priceMonthly: (json['price_monthly'] ?? 0).toDouble(),
      priceYearly: json['price_yearly']?.toDouble(),
      features: List<String>.from(json['features'] ?? []),
      maxDailyMessages: json['max_daily_messages'] ?? 0,
      maxMonthlyMessages: json['max_monthly_messages'] ?? 0,
      grammarCategoriesAccess: List<String>.from(json['grammar_categories_access'] ?? []),
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUnlimited => maxDailyMessages == -1;
  bool get isFree => id == 'free';
  bool get isPremium => !isFree;
}

class UserSubscription {
  final String? id;
  final String userId;
  final String planId;
  final String status;
  final String billingCycle;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentMethod;
  final String planName;
  final List<String> features;
  final int maxDailyMessages;
  final int maxMonthlyMessages;
  final List<String> grammarCategoriesAccess;
  final double priceMonthly;

  UserSubscription({
    this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.billingCycle,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.paymentMethod,
    required this.planName,
    required this.features,
    required this.maxDailyMessages,
    required this.maxMonthlyMessages,
    required this.grammarCategoriesAccess,
    required this.priceMonthly,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id']?.toString(),
      userId: json['user_id'],
      planId: json['plan_id'],
      status: json['status'],
      billingCycle: json['billing_cycle'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      autoRenew: json['auto_renew'] == 1 || json['auto_renew'] == true,
      paymentMethod: json['payment_method'],
      planName: json['plan_name'],
      features: List<String>.from(json['features'] ?? []),
      maxDailyMessages: json['max_daily_messages'] ?? 0,
      maxMonthlyMessages: json['max_monthly_messages'] ?? 0,
      grammarCategoriesAccess: List<String>.from(json['grammar_categories_access'] ?? []),
      priceMonthly: (json['price_monthly'] ?? 0).toDouble(),
    );
  }

  bool get isUnlimited => maxDailyMessages == -1;
  bool get isFree => planId == 'free';
  bool get isPremium => !isFree;
  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}

class UsageCheck {
  final bool canUse;
  final int todayUsage;
  final int dailyLimit;
  final int monthlyLimit;
  final String planId;
  final bool isUnlimited;
  final List<String> grammarCategoriesAccess;
  final int remainingToday;

  UsageCheck({
    required this.canUse,
    required this.todayUsage,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.planId,
    required this.isUnlimited,
    required this.grammarCategoriesAccess,
    required this.remainingToday,
  });

  factory UsageCheck.fromJson(Map<String, dynamic> json) {
    return UsageCheck(
      canUse: json['can_use'],
      todayUsage: json['today_usage'],
      dailyLimit: json['daily_limit'],
      monthlyLimit: json['monthly_limit'],
      planId: json['plan_id'],
      isUnlimited: json['is_unlimited'],
      grammarCategoriesAccess: List<String>.from(json['grammar_categories_access'] ?? []),
      remainingToday: json['remaining_today'],
    );
  }

  bool get hasRemainingMessages => isUnlimited || remainingToday > 0;
}

class SubscriptionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? subscription;

  SubscriptionResult({
    required this.success,
    required this.message,
    this.subscription,
  });

  factory SubscriptionResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      subscription: json['subscription'],
    );
  }
}

class GrammarCategory {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final DateTime createdAt;
  final bool isLocked;
  final bool requiresPremium;

  GrammarCategory({
    required this.id,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.isLocked,
    required this.requiresPremium,
  });

  factory GrammarCategory.fromJson(Map<String, dynamic> json) {
    return GrammarCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      displayOrder: json['display_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      isLocked: json['is_locked'] ?? false,
      requiresPremium: json['requires_premium'] ?? false,
    );
  }
}

class GrammarCategoriesResponse {
  final List<GrammarCategory> categories;
  final String userPlan;
  final List<String> allowedCategories;

  GrammarCategoriesResponse({
    required this.categories,
    required this.userPlan,
    required this.allowedCategories,
  });

  factory GrammarCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return GrammarCategoriesResponse(
      categories: (json['categories'] as List)
          .map((category) => GrammarCategory.fromJson(category))
          .toList(),
      userPlan: json['user_plan'] ?? 'Free',
      allowedCategories: List<String>.from(json['allowed_categories'] ?? []),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';

class SubscriptionService {
  static const String baseUrl = 'http://localhost:3000';
  
  // Get all available subscription plans
  static Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final plans = (data['plans'] as List)
            .map((plan) => SubscriptionPlan.fromJson(plan))
            .toList();
        return plans;
      } else {
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      print('Error fetching subscription plans: $e');
      rethrow;
    }
  }

  // Get user's current subscription
  static Future<UserSubscription> getUserSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/subscription'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserSubscription.fromJson(data['subscription']);
      } else {
        throw Exception('Failed to load user subscription');
      }
    } catch (e) {
      print('Error fetching user subscription: $e');
      rethrow;
    }
  }

  // Subscribe user to a plan
  static Future<SubscriptionResult> subscribeUserToPlan(
    String userId,
    String planId, {
    String billingCycle = 'monthly',
    String paymentMethod = 'demo',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/subscription/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plan_id': planId,
          'billing_cycle': billingCycle,
          'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionResult.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to subscribe');
      }
    } catch (e) {
      print('Error subscribing user: $e');
      rethrow;
    }
  }

  // Check user's usage limits
  static Future<UsageCheck> checkUserUsage(String userId, {String type = 'chat'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/usage/check?type=$type'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UsageCheck.fromJson(data['usage_check']);
      } else {
        throw Exception('Failed to check usage');
      }
    } catch (e) {
      print('Error checking usage: $e');
      rethrow;
    }
  }

  // Track user usage (typically called automatically by other services)
  static Future<bool> trackUserUsage(String userId, {String type = 'chat', int increment = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/usage/track'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': type,
          'increment': increment,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error tracking usage: $e');
      return false;
    }
  }

  // Get grammar categories with subscription access control
  static Future<GrammarCategoriesResponse> getGrammarCategories(String? userId) async {
    try {
      String url = '$baseUrl/grammar/categories';
      if (userId != null) {
        url += '?userId=$userId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GrammarCategoriesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load grammar categories');
      }
    } catch (e) {
      print('Error fetching grammar categories: $e');
      rethrow;
    }
  }

  // Get topics for a category with access control
  static Future<List<dynamic>> getGrammarTopics(String categoryId, String? userId) async {
    try {
      String url = '$baseUrl/grammar/categories/$categoryId/topics';
      if (userId != null) {
        url += '?userId=$userId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['topics'] ?? [];
      } else if (response.statusCode == 403) {
        final error = json.decode(response.body);
        throw SubscriptionRequiredException(error['message'] ?? 'Premium subscription required');
      } else {
        throw Exception('Failed to load grammar topics');
      }
    } catch (e) {
      print('Error fetching grammar topics: $e');
      rethrow;
    }
  }
}

// Custom exception for subscription requirements
class SubscriptionRequiredException implements Exception {
  final String message;
  SubscriptionRequiredException(this.message);
  
  @override
  String toString() => message;
}

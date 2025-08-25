import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionProvider with ChangeNotifier {
  UserSubscription? _userSubscription;
  List<SubscriptionPlan> _availablePlans = [];
  UsageCheck? _currentUsage;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  
  // Payment state for web
  String? _pendingClientSecret;
  String? _pendingPlanName;
  String? _pendingPlanId;
  String? _pendingBillingCycle;
  double? _pendingAmount;

  // Getters
  UserSubscription? get userSubscription => _userSubscription;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  UsageCheck? get currentUsage => _currentUsage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _userSubscription?.isPremium ?? false;
  
  // Payment UI getters for web
  String? get pendingClientSecret => _pendingClientSecret;
  String? get pendingPlanName => _pendingPlanName;
  String? get pendingPlanId => _pendingPlanId;
  String? get pendingBillingCycle => _pendingBillingCycle;
  double? get pendingAmount => _pendingAmount;
  bool get needsPaymentUI => _pendingClientSecret != null;
  bool get isFree => _userSubscription?.isFree ?? true;
  bool get hasUnlimitedMessages => _userSubscription?.isUnlimited ?? false;
  int get remainingMessages => _currentUsage?.remainingToday ?? 0;
  bool get canSendMessage => _currentUsage?.canUse ?? false;

  // Initialize the provider with a user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await loadUserSubscription();
    await loadAvailablePlans();
    await checkUsage();
  }

  // Load user's current subscription
  Future<void> loadUserSubscription() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    try {
      _userSubscription = await SubscriptionService.getUserSubscription(_currentUserId!);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading user subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load available subscription plans
  Future<void> loadAvailablePlans() async {
    _setLoading(true);
    try {
      _availablePlans = await SubscriptionService.getSubscriptionPlans();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading subscription plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check current usage limits
  Future<void> checkUsage() async {
    if (_currentUserId == null) return;
    
    try {
      _currentUsage = await SubscriptionService.checkUserUsage(_currentUserId!);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error checking usage: $e');
    }
  }

  // Process payment and subscribe to plan
  Future<bool> processPaymentAndSubscribe(String planId, {String billingCycle = 'monthly'}) async {
    print('🚀 processPaymentAndSubscribe called with planId: $planId, billingCycle: $billingCycle');
    print('👤 Current user ID: $_currentUserId');
    print('📦 Available plans count: ${_availablePlans.length}');
    print('📦 Available plan IDs: ${_availablePlans.map((p) => p.id).toList()}');
    
    if (_currentUserId == null) {
      print('❌ No current user ID');
      _error = 'User not logged in';
      return false;
    }
    
    _setLoading(true);
    try {
      print('🔄 Starting payment process for plan: $planId, billing: $billingCycle');
      
      // Step 1: Create payment intent
      final paymentData = await PaymentService.createPaymentIntent(
        planId: planId,
        billingCycle: billingCycle,
        userId: _currentUserId!,
      );

      print('💳 Payment intent result: $paymentData');

      if (paymentData == null) {
        _error = 'Failed to create payment intent';
        print('❌ Payment intent creation failed');
        return false;
      }

      // Step 2: Get plan info for display
      try {
        final plan = _availablePlans.firstWhere((p) => p.id == planId);
        print('📋 Found plan: ${plan.name} (${plan.id})');
        
        // Step 3: Process payment with Stripe
        final paymentSuccess = await PaymentService.processStripePayment(
          clientSecret: paymentData['clientSecret'],
          planName: plan.name,
        );

        print('💰 Payment processing result: $paymentSuccess');

        if (paymentSuccess == null) {
          // Web payment requires UI - store pending payment data
          print('🌐 Web payment requires UI - storing pending payment data');
          _pendingClientSecret = paymentData['clientSecret'];
          _pendingPlanName = plan.name;
          _pendingPlanId = planId;
          _pendingBillingCycle = billingCycle;
          _pendingAmount = plan.monthlyPrice;
          notifyListeners();
          return false; // Indicates UI is needed
        }

        if (!paymentSuccess) {
          _error = 'Payment was cancelled or failed';
          print('❌ Payment processing failed');
          return false;
        }

        // Step 4: Confirm payment on backend
        final confirmSuccess = await PaymentService.confirmPayment(
          paymentIntentId: paymentData['paymentIntentId'],
          planId: planId,
          billingCycle: billingCycle,
          userId: _currentUserId!,
        );

        print('✅ Payment confirmation result: $confirmSuccess');

        if (!confirmSuccess) {
          _error = 'Payment processed but subscription activation failed';
          print('❌ Subscription activation failed');
          return false;
        }

        // Step 5: Reload subscription data
        await loadUserSubscription();
        await checkUsage();
        _error = null;
        print('🎉 Payment and subscription completed successfully!');
        return true;
        
      } catch (planError) {
        print('❌ Error finding plan with ID $planId: $planError');
        _error = 'Plan not found: $planId';
        return false;
      }

    } catch (e) {
      _error = e.toString();
      print('❌ Error processing payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete pending payment after card input (for web)
  Future<bool> completePendingPayment(bool paymentSuccess) async {
    if (_pendingClientSecret == null || _pendingPlanId == null) {
      print('❌ No pending payment to complete');
      return false;
    }

    try {
      if (!paymentSuccess) {
        _error = 'Payment was cancelled or failed';
        print('❌ Payment was not successful');
        _clearPendingPayment();
        notifyListeners();
        return false;
      }

      // Step 4: Confirm payment on backend
      final confirmSuccess = await PaymentService.confirmPayment(
        paymentIntentId: _pendingClientSecret!.split('_secret_')[0], // Extract payment intent ID
        planId: _pendingPlanId!,
        billingCycle: _pendingBillingCycle!,
        userId: _currentUserId!,
      );

      print('✅ Payment confirmation result: $confirmSuccess');

      if (!confirmSuccess) {
        _error = 'Payment processed but subscription activation failed';
        print('❌ Subscription activation failed');
        _clearPendingPayment();
        notifyListeners();
        return false;
      }

      // Step 5: Reload subscription data
      await loadUserSubscription();
      await checkUsage();
      _error = null;
      _clearPendingPayment();
      print('🎉 Payment and subscription completed successfully!');
      notifyListeners();
      return true;

    } catch (e) {
      print('❌ Error completing payment: $e');
      _error = 'Failed to complete payment: ${e.toString()}';
      _clearPendingPayment();
      notifyListeners();
      return false;
    }
  }

  void _clearPendingPayment() {
    _pendingClientSecret = null;
    _pendingPlanName = null;
    _pendingPlanId = null;
    _pendingBillingCycle = null;
    _pendingAmount = null;
  }

  // Subscribe to a plan (legacy method for demo/free subscriptions)
  Future<bool> subscribeToPlan(String planId, {String billingCycle = 'monthly'}) async {
    if (_currentUserId == null) return false;
    
    _setLoading(true);
    try {
      final result = await SubscriptionService.subscribeUserToPlan(
        _currentUserId!,
        planId,
        billingCycle: billingCycle,
      );
      
      if (result.success) {
        // Reload subscription data
        await loadUserSubscription();
        await checkUsage();
        _error = null;
        return true;
      } else {
        _error = result.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('Error subscribing to plan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Track message usage (call this after sending a message)
  Future<void> trackMessageUsage() async {
    if (_currentUserId == null) return;
    
    try {
      await SubscriptionService.trackUserUsage(_currentUserId!);
      // Refresh usage data
      await checkUsage();
    } catch (e) {
      print('Error tracking message usage: $e');
    }
  }

  // Check if user has access to a grammar category
  bool hasAccessToCategory(String categoryId) {
    if (_userSubscription == null) return categoryId == 'foundations';
    
    final allowedCategories = _userSubscription!.grammarCategoriesAccess;
    return allowedCategories.contains('all') || allowedCategories.contains(categoryId);
  }

  // Get subscription status message for UI
  String getSubscriptionStatusMessage() {
    if (_userSubscription == null) return 'Loading subscription...';
    
    if (_userSubscription!.isFree) {
      final remaining = _currentUsage?.remainingToday ?? 0;
      if (remaining > 0) {
        return 'Free Plan: $remaining messages remaining today';
      } else {
        return 'Free Plan: Daily limit reached. Upgrade for unlimited messages!';
      }
    } else {
      return '${_userSubscription!.planName}: Unlimited messages';
    }
  }

  // Get upgrade prompt message
  String getUpgradePromptMessage() {
    if (_userSubscription?.isFree ?? true) {
      return 'Upgrade to Premium for unlimited messages and access to all grammar categories!';
    }
    return '';
  }

  // Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh all subscription data
  Future<void> refresh() async {
    if (_currentUserId != null) {
      await initialize(_currentUserId!);
    }
  }
}

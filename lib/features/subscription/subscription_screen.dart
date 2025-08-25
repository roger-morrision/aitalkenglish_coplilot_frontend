import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/subscription_widgets.dart';
import '../../widgets/web_stripe_payment_widget.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🔄 SubscriptionScreen: Initializing provider...');
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        print('👤 SubscriptionScreen: Current user: ${user.email}');
        print('👤 SubscriptionScreen: Initializing with UID: ${user.uid}');
        await provider.initialize(user.uid);
        print('✅ SubscriptionScreen: Provider initialized');
      } else {
        print('❌ SubscriptionScreen: No user logged in');
        if (provider.availablePlans.isEmpty) {
          provider.loadAvailablePlans();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.availablePlans.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.availablePlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load subscription plans',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadAvailablePlans(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      size: 48,
                      color: Colors.yellow.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock unlimited AI conversations and access to all grammar categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Current subscription status
              if (provider.userSubscription != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Plan: ${provider.userSubscription!.planName}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            if (provider.currentUsage != null)
                              Text(
                                provider.getSubscriptionStatusMessage(),
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Plans list
              Expanded(
                child: ListView.builder(
                  itemCount: provider.availablePlans.length,
                  itemBuilder: (context, index) {
                    final plan = provider.availablePlans[index];
                    final isCurrentPlan = provider.userSubscription?.planId == plan.id;
                    final isPopular = plan.id == 'premium_monthly';

                    return SubscriptionPlanCard(
                      plan: plan,
                      isCurrentPlan: isCurrentPlan,
                      isPopular: isPopular,
                      onSubscribe: plan.isFree ? null : () => _subscribeToPlan(context, plan),
                    );
                  },
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '✓ Cancel anytime  ✓ Secure payment  ✓ Instant access',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Demo mode: Subscriptions are simulated for testing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _subscribeToPlan(BuildContext context, plan) async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    // For free plans, use the simple subscription method
    if (plan.isFree) {
      final success = await provider.subscribeToPlan(plan.id);
      if (success) {
        _showSuccessDialog(context, plan);
      } else {
        _showErrorDialog(context, provider.error ?? 'Failed to subscribe');
      }
      return;
    }

    // For paid plans, show payment options dialog
    final paymentMethod = await _showPaymentMethodDialog(context, plan);
    if (paymentMethod == null) return;

    // Show billing cycle selection for non-free plans
    String? selectedBilling = 'monthly';
    if (plan.priceYearly != null && plan.priceYearly! > 0) {
      selectedBilling = await _showBillingCycleDialog(context, plan);
    }

    if (selectedBilling == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing payment...'),
          ],
        ),
      ),
    );

    bool success = false;

    try {
      print('💰 Processing payment with method: $paymentMethod, billing: $selectedBilling');
      
      if (paymentMethod == 'stripe') {
        // Process with Stripe
        print('🔄 Calling processPaymentAndSubscribe for plan: ${plan.id}');
        success = await provider.processPaymentAndSubscribe(
          plan.id, 
          billingCycle: selectedBilling,
        );
        print('✅ processPaymentAndSubscribe returned: $success');
        
        // Check if web payment UI is needed
        if (!success && provider.needsPaymentUI) {
          print('🌐 Web payment UI required - closing loading dialog and showing payment widget');
          Navigator.pop(context); // Close loading dialog
          
          // Show web payment widget
          await _showWebPaymentDialog(context, provider);
          return; // Exit early, dialog will handle the rest
        }
      } else if (paymentMethod == 'demo') {
        // Demo subscription (legacy method)
        print('🎭 Calling subscribeToPlan (demo) for plan: ${plan.id}');
        success = await provider.subscribeToPlan(
          plan.id, 
          billingCycle: selectedBilling,
        );
        print('✅ subscribeToPlan returned: $success');
      }
      
      print('🎯 Final success status: $success');
      
      if (provider.error != null) {
        print('❌ Provider error: ${provider.error}');
      }
      
    } catch (e) {
      print('❌ Payment error caught: $e');
      success = false;
    }

    // Close loading dialog
    Navigator.pop(context);

    // Show result
    print('🎭 Showing result dialog - success: $success, error: ${provider.error}');
    
    if (success) {
      print('🎉 Showing success dialog');
      _showSuccessDialog(context, plan);
    } else {
      final errorMessage = provider.error ?? 'Payment failed';
      print('💥 Showing error dialog with message: $errorMessage');
      _showErrorDialog(context, errorMessage);
    }
  }

  Future<String?> _showPaymentMethodDialog(BuildContext context, plan) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Plan: ${plan.name}'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: Text('Credit Card (Stripe Test)'),
              subtitle: Text('Real Stripe integration with test cards'),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.orange),
              title: Text('Demo Payment'),
              subtitle: Text('Simulated payment for testing'),
              onTap: () => Navigator.pop(context, 'demo'),
            ),
            SizedBox(height: 16),
            ExpansionTile(
              title: Text('Test Card Numbers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Successful Payments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('• Visa: 4242 4242 4242 4242', style: TextStyle(fontSize: 11)),
                      Text('• Mastercard: 5555 5555 5555 4444', style: TextStyle(fontSize: 11)),
                      Text('• Amex: 3782 822463 10005', style: TextStyle(fontSize: 11)),
                      SizedBox(height: 8),
                      Text('Declined Payments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('• Generic decline: 4000 0000 0000 0002', style: TextStyle(fontSize: 11)),
                      Text('• Insufficient funds: 4000 0000 0000 9995', style: TextStyle(fontSize: 11)),
                      SizedBox(height: 8),
                      Text('Use any future expiry (12/34) and CVC (123)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showBillingCycleDialog(BuildContext context, plan) async {
    String selectedBilling = 'monthly';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Billing Cycle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Monthly'),
              subtitle: Text('\$${plan.priceMonthly.toStringAsFixed(2)}/month'),
              leading: Radio<String>(
                value: 'monthly',
                groupValue: selectedBilling,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              onTap: () => Navigator.pop(context, 'monthly'),
            ),
            ListTile(
              title: Text('Yearly (Save 17%)'),
              subtitle: Text('\$${plan.priceYearly!.toStringAsFixed(2)}/year'),
              leading: Radio<String>(
                value: 'yearly',
                groupValue: selectedBilling,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              onTap: () => Navigator.pop(context, 'yearly'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Text('Welcome to ${plan.name}! You now have access to all premium features.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWebPaymentDialog(BuildContext context, SubscriptionProvider provider) async {
    if (!kIsWeb || !provider.needsPaymentUI) {
      print('❌ Web payment dialog not needed or not on web platform');
      return;
    }

    final completer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: WebStripePaymentWidget(
            clientSecret: provider.pendingClientSecret!,
            planName: provider.pendingPlanName!,
            amount: provider.pendingAmount!,
            onPaymentComplete: (success) {
              Navigator.pop(context, success);
            },
          ),
        ),
      ),
    );

    // Complete the payment after the dialog closes
    if (completer != null) {
      print('🔄 Completing payment with result: $completer');
      
      // Show loading again
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Confirming payment...'),
            ],
          ),
        ),
      );

      final success = await provider.completePendingPayment(completer);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show result
      if (success) {
        final plan = provider.availablePlans.firstWhere(
          (p) => p.id == provider.pendingPlanId,
          orElse: () => provider.availablePlans.first,
        );
        _showSuccessDialog(context, plan);
      } else {
        final errorMessage = provider.error ?? 'Payment confirmation failed';
        _showErrorDialog(context, errorMessage);
      }
    } else {
      print('💔 Payment dialog was dismissed without completion');
      _showErrorDialog(context, 'Payment was cancelled');
    }
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class WebStripePaymentWidget extends StatefulWidget {
  final String clientSecret;
  final Function(bool) onPaymentComplete;
  final String planName;
  final double amount;

  const WebStripePaymentWidget({
    super.key,
    required this.clientSecret,
    required this.onPaymentComplete,
    required this.planName,
    required this.amount,
  });

  @override
  State<WebStripePaymentWidget> createState() => _WebStripePaymentWidgetState();
}

class _WebStripePaymentWidgetState extends State<WebStripePaymentWidget> {
  bool _isProcessing = false;
  String? _error;
  
  // Test cards for quick selection
  final List<Map<String, String>> _testCards = [
    {
      'name': 'Visa (Success)',
      'number': '4242 4242 4242 4242',
      'expiry': '12/34',
      'cvc': '123',
      'description': 'Default successful card'
    },
    {
      'name': 'Visa (Decline)',
      'number': '4000 0000 0000 0002',
      'expiry': '12/34',
      'cvc': '123',
      'description': 'Generic decline'
    },
    {
      'name': 'Mastercard',
      'number': '5555 5555 5555 4444',
      'expiry': '12/34',
      'cvc': '123',
      'description': 'Successful payment'
    },
    {
      'name': 'American Express',
      'number': '3782 822463 10005',
      'expiry': '12/34',
      'cvc': '1234',
      'description': 'Amex successful payment'
    },
    {
      'name': 'Insufficient Funds',
      'number': '4000 0000 0000 9995',
      'expiry': '12/34',
      'cvc': '123',
      'description': 'Decline - insufficient funds'
    },
  ];

  String _selectedCardNumber = '4242 4242 4242 4242';
  String _selectedExpiry = '12/34';
  String _selectedCvc = '123';

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  void _initializeStripe() {
    if (kIsWeb) {
      // Initialize Stripe.js
      js.context.callMethod('eval', ['''
        if (typeof window.stripe === 'undefined') {
          window.stripe = Stripe('pk_test_51Rylr1B8BWXiYZ7YFpwd2XzBgOqWP0fKuehGPvnXh7lK2cuIEhOG2erXpSJasxRSTk7hboWSV2FcA3Id98FFE7gc00vER550eJ');
          console.log('Stripe.js initialized');
        }
      ''']);
    }
  }

  void _selectTestCard(Map<String, String> card) {
    setState(() {
      _selectedCardNumber = card['number']!;
      _selectedExpiry = card['expiry']!;
      _selectedCvc = card['cvc']!;
      _error = null;
    });
  }

  Future<void> _processPayment() async {
    if (!kIsWeb) {
      setState(() {
        _error = 'This widget is only available on web';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      print('🔄 Processing payment with card: ${_selectedCardNumber.substring(0, 4)}...');
      
      // Parse card details
      final cardNumber = _selectedCardNumber.replaceAll(' ', '');
      final expiryParts = _selectedExpiry.split('/');
      final expMonth = int.parse(expiryParts[0]);
      final expYear = int.parse('20${expiryParts[1]}');
      
      // Create payment method and confirm payment
      final paymentResult = await _confirmCardPayment(
        widget.clientSecret,
        cardNumber,
        expMonth,
        expYear,
        _selectedCvc,
      );

      if (paymentResult) {
        print('✅ Payment successful!');
        widget.onPaymentComplete(true);
      } else {
        setState(() {
          _error = 'Payment failed. Please try again with a different card.';
        });
        widget.onPaymentComplete(false);
      }
    } catch (e) {
      print('❌ Payment error: $e');
      setState(() {
        _error = 'Payment error: ${e.toString()}';
      });
      widget.onPaymentComplete(false);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _confirmCardPayment(
    String clientSecret,
    String cardNumber,
    int expMonth,
    int expYear,
    String cvc,
  ) async {
    try {
      // Use Stripe.js to confirm the payment
      final result = js.context.callMethod('eval', ['''
        (function() {
          return window.stripe.confirmCardPayment('$clientSecret', {
            payment_method: {
              card: {
                number: '$cardNumber',
                exp_month: $expMonth,
                exp_year: $expYear,
                cvc: '$cvc',
              },
              billing_details: {
                name: 'Test User',
                address: {
                  postal_code: '12345',
                },
              },
            }
          }).then(function(result) {
            if (result.error) {
              console.error('Payment failed:', result.error.message);
              window.paymentResult = { success: false, error: result.error.message };
            } else if (result.paymentIntent && result.paymentIntent.status === 'succeeded') {
              console.log('Payment succeeded!');
              window.paymentResult = { success: true };
            } else {
              console.log('Payment status:', result.paymentIntent?.status);
              window.paymentResult = { success: false, error: 'Unexpected payment status' };
            }
            return window.paymentResult;
          }).catch(function(error) {
            console.error('Payment error:', error);
            window.paymentResult = { success: false, error: error.message };
            return window.paymentResult;
          });
        })()
      ''']);

      // Wait for the payment to process
      await Future.delayed(const Duration(seconds: 3));
      
      // Check the result
      final resultObj = js.context['paymentResult'];
      if (resultObj != null) {
        final success = resultObj['success'] as bool? ?? false;
        if (!success) {
          final error = resultObj['error'] as String? ?? 'Unknown error';
          print('❌ Payment failed: $error');
        }
        return success;
      }
      
      return false;
    } catch (e) {
      print('❌ Payment confirmation error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.planName} - \$${widget.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Test Cards Section
          Text(
            'Test Cards (Select one):',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _testCards.length,
              itemBuilder: (context, index) {
                final card = _testCards[index];
                final isSelected = card['number'] == _selectedCardNumber;
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    child: InkWell(
                      onTap: () => _selectTestCard(card),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card['number']!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card['description']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),

          // Selected Card Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Card:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Card: $_selectedCardNumber',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    Text(
                      'Exp: $_selectedExpiry',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'CVC: $_selectedCvc',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Error Display
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          
          if (_error != null) const SizedBox(height: 16),

          // Process Payment Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing Payment...'),
                      ],
                    )
                  : Text(
                      'Pay \$${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Security Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a test environment. These cards are for testing only and will not be charged.',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

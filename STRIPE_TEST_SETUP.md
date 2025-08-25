# Stripe Test Environment Setup

## Overview
The application now supports real Stripe payment integration with comprehensive test card support for development and testing.

## Configuration

### Backend Configuration
- **Stripe Secret Key**: Configured in `.env` file as `STRIPE_SECRET_KEY`
- **Test Mode**: Uses `sk_test_*` key for safe testing
- **Webhook Secret**: Configured for payment event handling

### Frontend Configuration
- **Stripe Publishable Key**: `pk_test_51Rylr1B8BWXiYZ7YFpwd2XzBgOqWP0fKuehGPvnXh7lK2cuIEhOG2erXpSJasxRSTk7hboWSV2FcA3Id98FFE7gc00vER550eJ`
- **Platform Support**: Web (Stripe.js simulation) and Mobile (Flutter Stripe SDK)

## Test Credit Card Numbers

### ✅ Successful Payment Cards
| Card Type | Number | Description |
|-----------|--------|-------------|
| Visa | `4242 4242 4242 4242` | Standard successful payment |
| Visa (Debit) | `4000 0566 5566 5556` | Debit card payment |
| Mastercard | `5555 5555 5555 4444` | Standard Mastercard |
| Mastercard (2-series) | `2223 0031 2200 3222` | New Mastercard format |
| Mastercard (Debit) | `5200 8282 8282 8210` | Debit Mastercard |
| American Express | `3782 822463 10005` | Amex standard |
| American Express | `3714 496353 98431` | Alternative Amex |
| Discover | `6011 1111 1111 1117` | Discover card |
| Diners Club | `3056 9300 0902 0004` | Diners Club card |

### ❌ Declined Payment Cards (Error Testing)
| Card Type | Number | Error Type |
|-----------|--------|------------|
| Generic Decline | `4000 0000 0000 0002` | Your card was declined |
| Insufficient Funds | `4000 0000 0000 9995` | Insufficient funds |
| Lost Card | `4000 0000 0000 9987` | Lost card |
| Stolen Card | `4000 0000 0000 9979` | Stolen card |
| Expired Card | `4000 0000 0000 0069` | Expired card |
| Incorrect CVC | `4000 0000 0000 0127` | Incorrect CVC |
| Processing Error | `4000 0000 0000 0119` | Processing error |

### 🔐 3D Secure Authentication Cards
| Card Type | Number | Description |
|-----------|--------|-------------|
| Authentication Required | `4000 0025 0000 3155` | Requires 3D Secure auth |
| Authentication Fails | `4000 0000 0000 3220` | 3D Secure auth fails |

### 💳 Card Details for Testing
- **Expiry Date**: Use any future date (e.g., `12/34`)
- **CVC**: Use any 3-digit number (e.g., `123`)
- **ZIP Code**: Use any ZIP code (e.g., `12345`)

## Payment Flow Testing

### 1. Demo Payment Mode
- Select "Demo Payment" in payment method dialog
- Simulates payment without Stripe processing
- Always succeeds for testing subscription flow

### 2. Stripe Test Mode
- Select "Credit Card (Stripe Test)" in payment method dialog
- Creates real Stripe payment intent
- Use test card numbers above
- Processes through Stripe test environment

## Development Features

### Payment Method Dialog
- **Enhanced UI**: Shows test card numbers for easy reference
- **Dual Mode**: Supports both demo and real Stripe payments
- **Educational**: Displays common test scenarios

### Debug Logging
- Comprehensive payment flow logging
- Stripe API response tracking
- Error handling with fallback to demo mode

### Error Handling
- Graceful degradation to demo mode if Stripe fails
- Comprehensive error messages
- Database schema compatibility

## Testing Scenarios

### Successful Payment Test
1. Navigate to Subscription screen
2. Select a paid plan
3. Choose "Credit Card (Stripe Test)"
4. Use Visa test card: `4242 4242 4242 4242`
5. Verify subscription activation

### Declined Payment Test
1. Navigate to Subscription screen
2. Select a paid plan
3. Choose "Credit Card (Stripe Test)"
4. Use declined card: `4000 0000 0000 0002`
5. Verify error handling

### Demo Mode Test
1. Navigate to Subscription screen
2. Select a paid plan
3. Choose "Demo Payment"
4. Verify immediate subscription activation

## Production Deployment Notes

For production deployment:
1. Replace test Stripe keys with live keys
2. Update `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` in environment
3. Configure webhook endpoints for live environment
4. Remove demo payment option from production builds
5. Implement proper card input forms for web platform

## Security Considerations

- Test keys are safe for development (prefixed with `sk_test_` and `pk_test_`)
- No real money is processed in test mode
- All test transactions appear in Stripe test dashboard
- Production keys should never be committed to version control

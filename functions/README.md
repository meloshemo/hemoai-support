# HemoAI Payment Functions

Firebase Functions for handling Stripe payments and premium activation.

## Setup

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase Functions (if not already):
   ```bash
   firebase init functions
   ```

4. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

5. Set configuration:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_live_YOUR_STRIPE_SECRET_KEY"
   firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
   firebase functions:config:set stripe.price_monthly="price_MONTHLY_PRICE_ID"
   firebase functions:config:set stripe.price_yearly="price_YEARLY_PRICE_ID"
   firebase functions:config:set stripe.price_lifetime="price_LIFETIME_PRICE_ID"
   firebase functions:config:set app.success_url="https://hemoai.app/payment-success"
   firebase functions:config:set app.cancel_url="https://hemoai.app/payment-cancel"
   ```

6. Deploy:
   ```bash
   firebase deploy --only functions
   ```

## Endpoints

### Create Checkout Session
```
POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createStripeCheckoutSession

Body:
{
  "planType": "monthly" | "yearly" | "lifetime",
  "userEmail": "user@example.com",
  "userName": "User Name",
  "userId": "user123"
}
```

### Check Premium Status
```
GET https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/checkPremiumStatus?userId=user123
```

### Stripe Webhook
```
POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook
```

## Testing

1. Start emulator:
   ```bash
   firebase emulators:start --only functions
   ```

2. Test locally using the emulator URL


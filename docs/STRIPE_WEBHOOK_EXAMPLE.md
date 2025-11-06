# 🔗 Stripe Webhook Backend Örneği

Bu dosya, Stripe ödemelerini doğrulamak ve kullanıcı premium durumunu güncellemek için backend servis örnekleri içerir.

## 🚀 Node.js/Express Örneği

### Kurulum

```bash
npm init -y
npm install express stripe body-parser dotenv
```

### server.js

```javascript
require('dotenv').config();
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const app = express();

// Webhook için raw body gerekli
app.use('/webhook', express.raw({type: 'application/json'}));
app.use(express.json());

// Stripe webhook endpoint
app.post('/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    // Webhook'u doğrula
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Ödeme başarılı olduğunda
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    
    console.log('Payment successful:', {
      customerEmail: session.customer_email,
      amount: session.amount_total / 100,
      currency: session.currency,
      metadata: session.metadata
    });

    // Kullanıcının premium durumunu güncelle
    await updateUserPremiumStatus(
      session.customer_email,
      session.metadata
    );
  }

  // Abonelik oluşturulduğunda (recurring payments)
  if (event.type === 'customer.subscription.created') {
    const subscription = event.data.object;
    console.log('Subscription created:', subscription.id);
    
    // Kullanıcıyı premium yap
    await activatePremiumSubscription(
      subscription.customer,
      subscription.items.data[0].price.id
    );
  }

  // Abonelik yenilendiğinde
  if (event.type === 'customer.subscription.updated') {
    const subscription = event.data.object;
    
    if (subscription.status === 'active') {
      // Abonelik aktif, premium'u uzat
      await extendPremiumSubscription(
        subscription.customer,
        subscription.current_period_end
      );
    } else if (subscription.status === 'canceled') {
      // Abonelik iptal edildi, premium'u kaldır
      await deactivatePremium(subscription.customer);
    }
  }

  // Abonelik iptal edildiğinde
  if (event.type === 'customer.subscription.deleted') {
    const subscription = event.data.object;
    console.log('Subscription canceled:', subscription.id);
    await deactivatePremium(subscription.customer);
  }

  res.json({received: true});
});

// Kullanıcı premium durumunu güncelle
async function updateUserPremiumStatus(email, metadata) {
  // TODO: Veritabanınızı güncelleyin
  // Örnek:
  // const user = await db.users.findOne({ email });
  // if (!user) return;
  
  const planType = metadata?.plan_type || 'monthly'; // monthly, yearly, lifetime
  const expiryDate = calculateExpiryDate(planType);
  
  // await db.users.updateOne(
  //   { email },
  //   {
  //     $set: {
  //       premium: true,
  //       premiumTier: 'premium',
  //       premiumExpiry: expiryDate,
  //       lastPaymentDate: new Date()
  //     }
  //   }
  // );
  
  console.log(`Premium activated for ${email} until ${expiryDate}`);
}

// Premium aboneliği aktif et
async function activatePremiumSubscription(customerId, priceId) {
  // Stripe'dan müşteri bilgilerini al
  const customer = await stripe.customers.retrieve(customerId);
  const email = customer.email;
  
  // Veritabanını güncelle
  await updateUserPremiumStatus(email, { plan_type: 'recurring' });
}

// Premium aboneliği uzat
async function extendPremiumSubscription(customerId, expiryTimestamp) {
  const customer = await stripe.customers.retrieve(customerId);
  const expiryDate = new Date(expiryTimestamp * 1000);
  
  // TODO: Veritabanını güncelleyin
  console.log(`Premium extended for ${customer.email} until ${expiryDate}`);
}

// Premium'u kaldır
async function deactivatePremium(customerId) {
  const customer = await stripe.customers.retrieve(customerId);
  
  // TODO: Veritabanını güncelleyin
  // await db.users.updateOne(
  //   { email: customer.email },
  //   { $set: { premium: false, premiumTier: 'free' } }
  // );
  
  console.log(`Premium deactivated for ${customer.email}`);
}

// Expiry date hesapla
function calculateExpiryDate(planType) {
  const now = new Date();
  switch (planType) {
    case 'lifetime':
      return null; // Lifetime, expiry yok
    case 'yearly':
      return new Date(now.setFullYear(now.getFullYear() + 1));
    case 'monthly':
    default:
      return new Date(now.setMonth(now.getMonth() + 1));
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API endpoint: Kullanıcının premium durumunu kontrol et
app.get('/api/user/:userId/premium-status', async (req, res) => {
  // TODO: Veritabanından kullanıcıyı bul
  // const user = await db.users.findOne({ id: req.params.userId });
  
  res.json({
    isPremium: true, // user?.premium || false
    tier: 'premium', // user?.premiumTier || 'free'
    expiryDate: null, // user?.premiumExpiry || null
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Webhook server running on port ${PORT}`);
});
```

### .env

```env
STRIPE_SECRET_KEY=sk_live_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
PORT=3000
```

---

## 🐍 Python/Flask Örneği

```python
from flask import Flask, request, jsonify
import stripe
import os
from datetime import datetime, timedelta

app = Flask(__name__)

# Stripe API key
stripe.api_key = os.environ.get('STRIPE_SECRET_KEY')
webhook_secret = os.environ.get('STRIPE_WEBHOOK_SECRET')

@app.route('/webhook', methods=['POST'])
def webhook():
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, webhook_secret
        )
    except ValueError:
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError:
        return jsonify({'error': 'Invalid signature'}), 400
    
    # Ödeme tamamlandı
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        update_user_premium_status(
            session['customer_email'],
            session.get('metadata', {})
        )
    
    # Abonelik güncellemeleri
    elif event['type'] == 'customer.subscription.updated':
        subscription = event['data']['object']
        if subscription['status'] == 'active':
            extend_premium(subscription['customer'])
        elif subscription['status'] == 'canceled':
            deactivate_premium(subscription['customer'])
    
    return jsonify({'received': True})

def update_user_premium_status(email, metadata):
    # TODO: Veritabanı güncelleme
    plan_type = metadata.get('plan_type', 'monthly')
    expiry = calculate_expiry(plan_type)
    print(f'Premium activated for {email} until {expiry}')

def calculate_expiry(plan_type):
    now = datetime.now()
    if plan_type == 'lifetime':
        return None
    elif plan_type == 'yearly':
        return now + timedelta(days=365)
    else:
        return now + timedelta(days=30)

if __name__ == '__main__':
    app.run(port=3000)
```

---

## 🔧 Supabase Edge Functions Örneği

Supabase kullanıyorsanız, Edge Function ile webhook'u yönetebilirsiniz:

### supabase/functions/stripe-webhook/index.ts

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@13.6.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response('No signature', { status: 400 })
  }

  const body = await req.text()
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') || ''

  let event: Stripe.Event
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret
    )
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  // Ödeme tamamlandı
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    
    // Supabase veritabanını güncelle
    const { data, error } = await supabase
      .from('users')
      .update({
        premium: true,
        premium_expiry: calculateExpiry(session.metadata?.plan_type),
      })
      .eq('email', session.customer_email)
    
    if (error) {
      console.error('Database update error:', error)
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})

function calculateExpiry(planType: string): Date | null {
  const now = new Date()
  switch (planType) {
    case 'lifetime':
      return null
    case 'yearly':
      return new Date(now.setFullYear(now.getFullYear() + 1))
    default:
      return new Date(now.setMonth(now.getMonth() + 1))
  }
}
```

---

## 🔒 Güvenlik Notları

1. **Webhook Secret**: Mutlaka kullanın, webhook'ları doğrulayın
2. **HTTPS**: Production'da HTTPS zorunludur
3. **Rate Limiting**: Webhook endpoint'inize rate limiting ekleyin
4. **Idempotency**: Aynı event'i birden fazla kez işlemeyin (idempotency key kullanın)
5. **Logging**: Tüm webhook event'lerini loglayın

---

## 🧪 Test Etme

### Stripe CLI ile Local Test

```bash
# Stripe CLI'ı yükleyin
# https://stripe.com/docs/stripe-cli

# Webhook'u local olarak test et
stripe listen --forward-to localhost:3000/webhook

# Test event gönder
stripe trigger checkout.session.completed
```

### Production Test

1. Stripe Dashboard'da test ödeme yapın
2. Webhook event'lerini kontrol edin (Developers > Webhooks > Events)
3. Backend loglarını kontrol edin
4. Kullanıcının premium durumunun güncellendiğini doğrulayın

---

**Not**: Bu örnekler temel yapı sağlar. Gerçek implementasyonda kendi veritabanı yapınıza göre güncelleme yapmanız gerekir.


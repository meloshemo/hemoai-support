/**
 * Firebase Functions for HemoAI Payment Processing
 * 
 * Handles:
 * - Stripe Checkout session creation
 * - Stripe webhook processing
 * - Premium activation via webhook
 * 
 * Setup:
 * 1. npm install
 * 2. firebase functions:config:set stripe.secret_key="sk_live_..."
 * 3. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Get Stripe secret key from config
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripe = stripeSecretKey ? require('stripe')(stripeSecretKey) : null;

// Stripe Checkout session creation endpoint
exports.createStripeCheckoutSession = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  // Validate Stripe configuration
  if (!stripe || !stripeSecretKey) {
    logError('Stripe secret key not configured', new Error('Missing configuration'));
    res.status(500).json({ error: 'Payment service not configured' });
    return;
  }

  try {
    // Validate request
    const validation = validateRequest(req, ['planType', 'userEmail']);
    if (!validation.valid) {
      res.status(400).json({ 
        error: 'Validation failed',
        details: validation.errors,
      });
      return;
    }

    const { planType, userEmail, userName, userId } = req.body;

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(userEmail)) {
      res.status(400).json({ error: 'Invalid email format' });
      return;
    }

    // Validate plan type
    const validPlanTypes = ['monthly', 'yearly', 'lifetime'];
    if (!validPlanTypes.includes(planType)) {
      res.status(400).json({ 
        error: 'Invalid plan type',
        validTypes: validPlanTypes,
      });
      return;
    }

    // Determine price ID based on plan type
    let priceId;
    const config = functions.config().stripe || {};

    switch (planType) {
      case 'monthly':
        priceId = config.price_monthly;
        break;
      case 'yearly':
        priceId = config.price_yearly;
        break;
      case 'lifetime':
        priceId = config.price_lifetime;
        break;
    }

    if (!priceId) {
      logError('Price ID not configured for plan type', new Error('Missing price ID'), { planType });
      res.status(500).json({ 
        error: 'Price not configured for this plan type',
        planType,
      });
      return;
    }

    logInfo('Creating Stripe Checkout session', { planType, userEmail, userId });

    // Create Stripe Checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: planType === 'lifetime' ? 'payment' : 'subscription',
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      customer_email: userEmail,
      metadata: {
        userId: userId || '',
        userName: userName || '',
        planType: planType,
      },
      success_url: `${functions.config().app?.success_url || 'https://hemoai.app'}/payment-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${functions.config().app?.cancel_url || 'https://hemoai.app'}/payment-cancel`,
    });

    logInfo('Stripe Checkout session created', { sessionId: session.id, planType });

    res.json({
      sessionId: session.id,
      url: session.url,
    });
  } catch (error) {
    logError('Error creating checkout session', error, { 
      planType: req.body?.planType,
      userEmail: req.body?.userEmail,
    });
    res.status(500).json({ 
      error: 'Failed to create checkout session',
      message: error.message,
    });
  }
});

// Stripe webhook handler
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe?.webhook_secret;

  if (!webhookSecret) {
    logError('Webhook secret not configured', new Error('Missing configuration'));
    return res.status(500).json({ error: 'Webhook not configured' });
  }

  if (!sig) {
    logError('Missing Stripe signature header', new Error('Missing signature'));
    return res.status(400).json({ error: 'Missing signature' });
  }

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    logInfo('Webhook event received', { type: event.type, id: event.id });
  } catch (err) {
    logError('Webhook signature verification failed', err);
    return res.status(400).json({ 
      error: 'Webhook signature verification failed',
      message: err.message,
    });
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        const session = event.data.object;
        await handleCheckoutCompleted(session);
        break;

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        const subscription = event.data.object;
        await handleSubscriptionUpdate(subscription);
        break;

      case 'customer.subscription.deleted':
        const deletedSubscription = event.data.object;
        await handleSubscriptionCancelled(deletedSubscription);
        break;

      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        await handlePaymentSuccess(paymentIntent);
        break;

      default:
        logInfo(`Unhandled event type`, { type: event.type });
    }

    res.json({ received: true, eventId: event.id });
  } catch (error) {
    logError('Error handling webhook event', error, { 
      eventType: event.type,
      eventId: event.id,
    });
    // Still return 200 to Stripe to prevent retries for processing errors
    res.status(200).json({ 
      received: true, 
      error: 'Processing failed',
      eventId: event.id,
    });
  }
});

// Handle checkout.session.completed
async function handleCheckoutCompleted(session) {
  try {
    const { userId, userName, planType } = session.metadata || {};

    if (!planType) {
      logError('Missing planType in checkout session metadata', new Error('Missing metadata'), { 
        sessionId: session.id,
      });
      return;
    }

    if (!userId) {
      logError('Missing userId in checkout session metadata', new Error('Missing metadata'), { 
        sessionId: session.id,
        planType,
      });
      // Try to extract from customer email if available
      if (!session.customer_email) {
        return;
      }
    }

    // Determine expiry date
    let expiryDate = null;
    if (planType === 'monthly') {
      expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
    } else if (planType === 'yearly') {
      expiryDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 365 days
    } else if (planType === 'lifetime') {
      expiryDate = null; // Lifetime, no expiry
    }

    // Store premium status in Firestore
    const premiumData = {
      userId: userId || session.customer_email, // Fallback to email if userId missing
      email: session.customer_email,
      tier: planType === 'lifetime' ? 'lifetime' : 'premium',
      planType: planType,
      activatedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiryDate: expiryDate ? admin.firestore.Timestamp.fromDate(expiryDate) : null,
      stripeSessionId: session.id,
      stripeCustomerId: session.customer,
      status: 'active',
      paymentStatus: session.payment_status,
    };

    const docId = userId || session.customer_email;
    await admin.firestore()
      .collection('premium_subscriptions')
      .doc(docId)
      .set(premiumData, { merge: true });

    logInfo('Premium activated', { userId: docId, planType, sessionId: session.id });
  } catch (error) {
    logError('Error handling checkout completed', error, { 
      sessionId: session.id,
    });
    throw error; // Re-throw to be caught by webhook handler
  }
}

// Handle subscription updates
async function handleSubscriptionUpdate(subscription) {
  try {
    const customerId = subscription.customer;
    
    if (!customerId) {
      logError('Missing customer ID in subscription', new Error('Missing customer ID'), { 
        subscriptionId: subscription.id,
      });
      return;
    }
    
    logInfo('Processing subscription update', { 
      subscriptionId: subscription.id,
      customerId,
      status: subscription.status,
    });
    
    // Find user by customer ID
    const snapshot = await admin.firestore()
      .collection('premium_subscriptions')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      logError('User not found for customer', new Error('User not found'), { customerId });
      return;
    }

    const doc = snapshot.docs[0];
    const userId = doc.id;

    // Update subscription status
    const updateData = {
      status: subscription.status === 'active' ? 'active' : 'inactive',
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await doc.ref.update(updateData);

    logInfo('Subscription updated', { userId, status: subscription.status });
  } catch (error) {
    logError('Error handling subscription update', error, { 
      subscriptionId: subscription.id,
    });
    throw error;
  }
}

// Handle subscription cancellation
async function handleSubscriptionCancelled(subscription) {
  try {
    const customerId = subscription.customer;
    
    if (!customerId) {
      logError('Missing customer ID in subscription', new Error('Missing customer ID'), { 
        subscriptionId: subscription.id,
      });
      return;
    }
    
    logInfo('Processing subscription cancellation', { 
      subscriptionId: subscription.id,
      customerId,
    });
    
    const snapshot = await admin.firestore()
      .collection('premium_subscriptions')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      logError('User not found for customer', new Error('User not found'), { customerId });
      return;
    }

    const doc = snapshot.docs[0];
    const userId = doc.id;

    await doc.ref.update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo('Subscription cancelled', { userId });
  } catch (error) {
    logError('Error handling subscription cancellation', error, { 
      subscriptionId: subscription.id,
    });
    throw error;
  }
}

// Handle payment success (for one-time payments like lifetime)
async function handlePaymentSuccess(paymentIntent) {
  try {
    // This is handled by checkout.session.completed for Checkout sessions
    // But can be used for direct payment intents if needed
    logInfo('Payment intent succeeded', { 
      paymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
    });
  } catch (error) {
    logError('Error handling payment success', error, { 
      paymentIntentId: paymentIntent.id,
    });
    throw error;
  }
}

// API endpoint to check premium status
exports.checkPremiumStatus = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { userId, email } = req.query;

    if (!userId && !email) {
      res.status(400).json({ error: 'Missing userId or email' });
      return;
    }

    const docId = userId || email;
    logInfo('Checking premium status', { userId: docId });

    const doc = await admin.firestore()
      .collection('premium_subscriptions')
      .doc(docId)
      .get();

    if (!doc.exists) {
      logInfo('Premium status not found', { userId: docId });
      res.json({ isPremium: false, tier: 'free' });
      return;
    }

    const data = doc.data();
    const now = new Date();
    const expiryDate = data.expiryDate?.toDate();

    // Check if subscription is active and not expired
    const isActive = data.status === 'active' && 
                     (data.tier === 'lifetime' || !expiryDate || expiryDate > now);

    logInfo('Premium status retrieved', { 
      userId: docId, 
      isPremium: isActive,
      tier: data.tier,
    });

    res.json({
      isPremium: isActive,
      tier: data.tier || 'free',
      planType: data.planType,
      expiryDate: expiryDate?.toISOString(),
      status: data.status,
    });
  } catch (error) {
    logError('Error checking premium status', error, { 
      userId: req.query?.userId,
      email: req.query?.email,
    });
    res.status(500).json({ 
      error: 'Failed to check premium status',
      message: error.message,
    });
  }
});

// Health check endpoint
exports.healthCheck = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      firestore: 'connected',
      stripe: stripeSecretKey ? 'configured' : 'not_configured',
    },
  };

  res.json(health);
});

// Helper functions
function validateRequest(req, requiredFields) {
  const errors = [];
  const body = req.body || {};
  
  for (const field of requiredFields) {
    if (!body[field] || (typeof body[field] === 'string' && body[field].trim() === '')) {
      errors.push(`Missing required field: ${field}`);
    }
  }
  
  return {
    valid: errors.length === 0,
    errors: errors,
  };
}

function logInfo(message, data = {}) {
  console.log(JSON.stringify({
    level: 'info',
    message: message,
    timestamp: new Date().toISOString(),
    data: data,
  }));
}

function logError(message, error, data = {}) {
  console.error(JSON.stringify({
    level: 'error',
    message: message,
    timestamp: new Date().toISOString(),
    error: error.message || String(error),
    stack: error.stack,
    data: data,
  }));
}

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

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const crypto = require('crypto');
const sendgrid = require('@sendgrid/mail');

admin.initializeApp();

// SendGrid configuration
const sendgridConfig = functions.config().sendgrid || {};
const sendgridApiKey = sendgridConfig.api_key;
const sendgridFromEmail = sendgridConfig.from_email;
const sendgridFromName = sendgridConfig.from_name || 'HemoAI';
const sendgridSupportEmail =
  sendgridConfig.support_email || sendgridFromEmail || 'support@hemoai.app';
const sendgridLogoUrl =
  sendgridConfig.logo_url || 'https://assets.hemoai.com/email/logo.png';

if (sendgridApiKey) {
  sendgrid.setApiKey(sendgridApiKey);
}

const emailTemplates = {
  passwordReset:
    sendgridConfig.template_password_reset ||
    'd-52e50c2cf27744f4e81133dde96a80647',
  weeklyReport:
    sendgridConfig.template_weekly_report ||
    'd-b8081e4aabd74004b985909000ebe1ed',
  criticalAlert:
    sendgridConfig.template_critical_alert ||
    'd-69eea4fb32784371a96c5c6f168e65ce',
  subscriptionReceipt:
    sendgridConfig.template_subscription_receipt ||
    'd-9e5926033631459a4f133b6ea6a1831b',
  invite:
    sendgridConfig.template_invite ||
    'd-7bf8970922641ee99f986b6efa58d9722',
};

const subscriptionReceiptCopy = {
  en: {
    subject: 'Your HemoAI subscription receipt',
    headline: 'Subscription Confirmation',
    introText: 'Hi {{userName}}, thank you for subscribing to the {{planName}} plan.',
    planLabel: 'Plan',
    amountLabel: 'Amount',
    renewalLabel: 'Renews on',
    renewalNoExpiryLabel: 'No renewal (lifetime access)',
    invoiceLabel: 'Invoice ID',
    paymentMethodLabel: 'Payment method',
    paymentMethodValue: 'Card',
    managementText:
      'You can manage your membership from Settings > Premium in the app.',
    supportNote: 'Need help? Reach us at',
    disclaimer: 'This email serves as your receipt.',
    userFallbackName: 'there',
    planNames: {
      monthly: 'Monthly Premium',
      yearly: 'Annual Premium',
      lifetime: 'Lifetime Premium',
    },
  },
  tr: {
    subject: 'HemoAI abonelik makbuzun',
    headline: 'Aboneliğin Onaylandı',
    introText:
      'Merhaba {{userName}}, {{planName}} paketini satın aldığın için teşekkür ederiz.',
    planLabel: 'Paket',
    amountLabel: 'Tutar',
    renewalLabel: 'Yenileme tarihi',
    renewalNoExpiryLabel: 'Yenileme yok (ömür boyu erişim)',
    invoiceLabel: 'Fatura No',
    paymentMethodLabel: 'Ödeme yöntemi',
    paymentMethodValue: 'Kart',
    managementText:
      'Üyeliğini uygulamada Ayarlar > Premium bölümünden yönetebilirsin.',
    supportNote: 'Yardım gerekir mi? Bize ulaş:',
    disclaimer: 'Bu e-posta makbuz yerine geçer.',
    userFallbackName: 'oradaki',
    planNames: {
      monthly: 'Aylık Premium',
      yearly: 'Yıllık Premium',
      lifetime: 'Ömür Boyu Premium',
    },
  },
  es: {
    subject: 'Recibo de suscripción de HemoAI',
    headline: 'Confirmación de suscripción',
    introText:
      'Hola {{userName}}, gracias por suscribirte al plan {{planName}}.',
    planLabel: 'Plan',
    amountLabel: 'Importe',
    renewalLabel: 'Renueva el',
    renewalNoExpiryLabel: 'Sin renovación (acceso de por vida)',
    invoiceLabel: 'N.º de factura',
    paymentMethodLabel: 'Método de pago',
    paymentMethodValue: 'Tarjeta',
    managementText:
      'Puedes gestionar tu suscripción desde Ajustes > Premium en la app.',
    supportNote: '¿Necesitas ayuda? Escríbenos a',
    disclaimer: 'Este correo actúa como recibo.',
    userFallbackName: 'allí',
    planNames: {
      monthly: 'Premium Mensual',
      yearly: 'Premium Anual',
      lifetime: 'Premium de Por Vida',
    },
  },
  fr: {
    subject: 'Reçu de votre abonnement HemoAI',
    headline: 'Confirmation de l’abonnement',
    introText:
      'Bonjour {{userName}}, merci de vous être abonné au plan {{planName}}.',
    planLabel: 'Formule',
    amountLabel: 'Montant',
    renewalLabel: 'Renouvellement le',
    renewalNoExpiryLabel: 'Pas de renouvellement (accès à vie)',
    invoiceLabel: 'N° de facture',
    paymentMethodLabel: 'Moyen de paiement',
    paymentMethodValue: 'Carte',
    managementText:
      "Vous pouvez gérer votre abonnement dans l'application, rubrique Réglages > Premium.",
    supportNote: 'Besoin d’aide ? Contactez-nous à',
    disclaimer: 'Cet e-mail tient lieu de reçu.',
    userFallbackName: 'là',
    planNames: {
      monthly: 'Premium Mensuel',
      yearly: 'Premium Annuel',
      lifetime: 'Premium À Vie',
    },
  },
  de: {
    subject: 'Dein HemoAI-Abonnementbeleg',
    headline: 'Abonnement bestätigt',
    introText:
      'Hallo {{userName}}, danke für dein Abonnement des {{planName}}-Tarifs.',
    planLabel: 'Tarif',
    amountLabel: 'Betrag',
    renewalLabel: 'Verlängert sich am',
    renewalNoExpiryLabel: 'Keine Verlängerung (lebenslanger Zugang)',
    invoiceLabel: 'Rechnungsnummer',
    paymentMethodLabel: 'Zahlungsmethode',
    paymentMethodValue: 'Karte',
    managementText:
      'Du kannst dein Abo in der App unter Einstellungen > Premium verwalten.',
    supportNote: 'Braucht du Hilfe? Kontaktiere uns unter',
    disclaimer: 'Diese E-Mail gilt als Beleg.',
    userFallbackName: 'dort',
    planNames: {
      monthly: 'Monatliches Premium',
      yearly: 'Jährliches Premium',
      lifetime: 'Lebenslanges Premium',
    },
  },
  ar: {
    subject: 'إيصال اشتراكك في HemoAI',
    headline: 'تأكيد الاشتراك',
    introText:
      'مرحبًا {{userName}}، شكرًا لاشتراكك في خطة {{planName}}.',
    planLabel: 'الخطة',
    amountLabel: 'المبلغ',
    renewalLabel: 'تجدد في',
    renewalNoExpiryLabel: 'لا يوجد تجديد (وصول مدى الحياة)',
    invoiceLabel: 'رقم الفاتورة',
    paymentMethodLabel: 'طريقة الدفع',
    paymentMethodValue: 'بطاقة',
    managementText:
      'يمكنك إدارة اشتراكك من الإعدادات > بريميوم داخل التطبيق.',
    supportNote: 'هل تحتاج مساعدة؟ تواصل معنا على',
    disclaimer: 'تعتبر هذه الرسالة إيصالًا.',
    userFallbackName: 'هناك',
    planNames: {
      monthly: 'بريميوم شهري',
      yearly: 'بريميوم سنوي',
      lifetime: 'بريميوم مدى الحياة',
    },
  },
  it: {
    subject: 'Ricevuta di abbonamento HemoAI',
    headline: "Conferma dell'abbonamento",
    introText:
      'Ciao {{userName}}, grazie per esserti abbonato al piano {{planName}}.',
    planLabel: 'Piano',
    amountLabel: 'Importo',
    renewalLabel: 'Si rinnova il',
    renewalNoExpiryLabel: 'Nessun rinnovo (accesso a vita)',
    invoiceLabel: 'Numero fattura',
    paymentMethodLabel: 'Metodo di pagamento',
    paymentMethodValue: 'Carta',
    managementText:
      "Puoi gestire l'abbonamento da Impostazioni > Premium nell'app.",
    supportNote: 'Hai bisogno di aiuto? Contattaci su',
    disclaimer: 'Questa e-mail vale come ricevuta.',
    userFallbackName: 'lì',
    planNames: {
      monthly: 'Premium Mensile',
      yearly: 'Premium Annuale',
      lifetime: 'Premium Perpetuo',
    },
  },
  pt: {
    subject: 'Recibo da sua assinatura HemoAI',
    headline: 'Confirmação de assinatura',
    introText:
      'Olá {{userName}}, obrigado por assinar o plano {{planName}}.',
    planLabel: 'Plano',
    amountLabel: 'Valor',
    renewalLabel: 'Renova em',
    renewalNoExpiryLabel: 'Sem renovação (acesso vitalício)',
    invoiceLabel: 'ID da fatura',
    paymentMethodLabel: 'Forma de pagamento',
    paymentMethodValue: 'Cartão',
    managementText:
      'Você pode gerenciar a assinatura em Configurações > Premium no app.',
    supportNote: 'Precisa de ajuda? Fale conosco em',
    disclaimer: 'Este e-mail serve como recibo.',
    userFallbackName: 'aí',
    planNames: {
      monthly: 'Premium Mensal',
      yearly: 'Premium Anual',
      lifetime: 'Premium Vitalício',
    },
  },
  ru: {
    subject: 'Квитанция по подписке HemoAI',
    headline: 'Подписка подтверждена',
    introText:
      'Здравствуйте, {{userName}}! Спасибо за оформление плана {{planName}}.',
    planLabel: 'Тариф',
    amountLabel: 'Сумма',
    renewalLabel: 'Дата продления',
    renewalNoExpiryLabel: 'Без продления (пожизненный доступ)',
    invoiceLabel: 'Номер счета',
    paymentMethodLabel: 'Способ оплаты',
    paymentMethodValue: 'Карта',
    managementText:
      'Управлять подпиской можно в приложении, раздел Настройки > Premium.',
    supportNote: 'Нужна помощь? Напишите нам на',
    disclaimer: 'Это письмо является вашим чеком.',
    userFallbackName: 'там',
    planNames: {
      monthly: 'Ежемесячный Premium',
      yearly: 'Ежегодный Premium',
      lifetime: 'Пожизненный Premium',
    },
  },
};

// Get Stripe secret key from config
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripe = stripeSecretKey ? require('stripe')(stripeSecretKey) : null;

// Stripe Checkout session creation endpoint
exports.createStripeCheckoutSession = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  const baseContext = buildRequestContext(req, { operation: 'createCheckout' });

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
    logError('Stripe secret key not configured', new Error('Missing configuration'), baseContext);
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

    const context = { ...baseContext };
    const { planType, userEmail, userName, userId } = req.body;

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(userEmail)) {
      logError('Invalid email format', new Error('Validation failed'), { ...context, userEmail });
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
      logError('Price ID not configured for plan type', new Error('Missing price ID'), { ...context, planType });
      res.status(500).json({ 
        error: 'Price not configured for this plan type',
        planType,
      });
      return;
    }

    logInfo('Creating Stripe Checkout session', { ...context, planType, userEmail, userId });

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

    logInfo('Stripe Checkout session created', { ...context, sessionId: session.id, planType });

    res.json({
      sessionId: session.id,
      url: session.url,
    });
  } catch (error) {
    logError('Error creating checkout session', error, { 
      ...buildRequestContext(req, { operation: 'createCheckout' }),
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

  const context = buildRequestContext(req, { operation: 'stripeWebhook' });

  if (!webhookSecret) {
    logError('Webhook secret not configured', new Error('Missing configuration'), context);
    return res.status(500).json({ error: 'Webhook not configured' });
  }

  if (!sig) {
    logError('Missing Stripe signature header', new Error('Missing signature'), context);
    return res.status(400).json({ error: 'Missing signature' });
  }

  let event;

  try {
    // Verify webhook signature using the raw request body
    const rawBody = req.rawBody;
    if (!rawBody) {
      logError('Missing rawBody for webhook verification', new Error('Missing raw body'), context);
      return res.status(400).json({ error: 'Missing raw request body' });
    }

    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
    context.eventType = event.type;
    context.eventId = event.id;
    logInfo('Webhook event received', context);
  } catch (err) {
    logError('Webhook signature verification failed', err, context);
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
        await handleCheckoutCompleted(session, context);
        break;

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        const subscription = event.data.object;
        await handleSubscriptionUpdate(subscription, context);
        break;

      case 'customer.subscription.deleted':
        const deletedSubscription = event.data.object;
        await handleSubscriptionCancelled(deletedSubscription, context);
        break;

      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        await handlePaymentSuccess(paymentIntent, context);
        break;

      default:
        logInfo(`Unhandled event type`, context);
    }

    res.json({ received: true, eventId: event.id });
  } catch (error) {
    logError('Error handling webhook event', error, context);
    // Still return 200 to Stripe to prevent retries for processing errors
    res.status(200).json({ 
      received: true, 
      error: 'Processing failed',
      eventId: event.id,
    });
  }
});

// Handle checkout.session.completed
async function handleCheckoutCompleted(session, parentContext = {}) {
  try {
    const { userId, userName, planType } = session.metadata || {};
    const context = {
      ...parentContext,
      operation: 'handleCheckoutCompleted',
      sessionId: session.id,
      planType,
    };

    if (!planType) {
      logError('Missing planType in checkout session metadata', new Error('Missing metadata'), context);
      return;
    }

    if (!userId) {
      logError('Missing userId in checkout session metadata', new Error('Missing metadata'), context);
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

    logInfo('Premium activated', { ...context, userId: docId });

    if (isEmailServiceConfigured() && session.customer_email) {
      const locale =
        normalizeLocale(
          session.locale ||
            session.customer_details?.locale ||
            session.customer_details?.address?.country,
        );

      try {
        const receiptPayload = buildSubscriptionReceiptTemplateData({
          locale,
          planType,
          userName: userName || session.customer_details?.name,
          amountTotal: session.amount_total,
          currency: session.currency,
          expiryDate,
          sessionId: session.id,
        });

        await sendTemplatedEmail('subscriptionReceipt', {
          to: session.customer_email,
          subject: receiptPayload.subject,
          locale,
          dynamicTemplateData: receiptPayload.dynamicTemplateData,
        });

        logInfo('Subscription receipt email sent', {
          ...context,
          email: session.customer_email,
          locale,
        });
      } catch (emailError) {
        logError('Failed to send subscription receipt email', emailError, {
          ...context,
          email: session.customer_email,
        });
      }
    }
  } catch (error) {
    logError('Error handling checkout completed', error, {
      ...parentContext,
      operation: 'handleCheckoutCompleted',
      sessionId: session.id,
    });
    throw error; // Re-throw to be caught by webhook handler
  }
}

// Handle subscription updates
async function handleSubscriptionUpdate(subscription, parentContext = {}) {
  try {
    const customerId = subscription.customer;
    const context = {
      ...parentContext,
      operation: 'handleSubscriptionUpdate',
      subscriptionId: subscription.id,
      customerId,
    };
    
    if (!customerId) {
      logError('Missing customer ID in subscription', new Error('Missing customer ID'), context);
      return;
    }
    
    logInfo('Processing subscription update', { ...context, status: subscription.status });
    
    // Find user by customer ID
    const snapshot = await admin.firestore()
      .collection('premium_subscriptions')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      logError('User not found for customer', new Error('User not found'), context);
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

    logInfo('Subscription updated', { ...context, userId, status: subscription.status });
  } catch (error) {
    logError('Error handling subscription update', error, {
      ...parentContext,
      operation: 'handleSubscriptionUpdate',
      subscriptionId: subscription.id,
    });
    throw error;
  }
}

// Handle subscription cancellation
async function handleSubscriptionCancelled(subscription, parentContext = {}) {
  try {
    const customerId = subscription.customer;
    const context = {
      ...parentContext,
      operation: 'handleSubscriptionCancelled',
      subscriptionId: subscription.id,
      customerId,
    };
    
    if (!customerId) {
      logError('Missing customer ID in subscription', new Error('Missing customer ID'), context);
      return;
    }
    
    logInfo('Processing subscription cancellation', context);
    
    const snapshot = await admin.firestore()
      .collection('premium_subscriptions')
      .where('stripeCustomerId', '==', customerId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      logError('User not found for customer', new Error('User not found'), context);
      return;
    }

    const doc = snapshot.docs[0];
    const userId = doc.id;

    await doc.ref.update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo('Subscription cancelled', { ...context, userId });
  } catch (error) {
    logError('Error handling subscription cancellation', error, {
      ...parentContext,
      operation: 'handleSubscriptionCancelled',
      subscriptionId: subscription.id,
    });
    throw error;
  }
}

// Handle payment success (for one-time payments like lifetime)
async function handlePaymentSuccess(paymentIntent, parentContext = {}) {
  try {
    const context = {
      ...parentContext,
      operation: 'handlePaymentSuccess',
      paymentIntentId: paymentIntent.id,
    };
    // This is handled by checkout.session.completed for Checkout sessions
    // But can be used for direct payment intents if needed
    logInfo('Payment intent succeeded', { 
      ...context,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
    });
  } catch (error) {
    logError('Error handling payment success', error, {
      ...parentContext,
      operation: 'handlePaymentSuccess',
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
    const context = buildRequestContext(req, { operation: 'checkPremiumStatus', userId: userId || email });

    if (!userId && !email) {
      res.status(400).json({ error: 'Missing userId or email' });
      return;
    }

    const docId = userId || email;
    logInfo('Checking premium status', { ...context, userId: docId });

    const doc = await admin.firestore()
      .collection('premium_subscriptions')
      .doc(docId)
      .get();

    if (!doc.exists) {
      logInfo('Premium status not found', { ...context, userId: docId });
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
      ...context,
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
      ...buildRequestContext(req, { operation: 'checkPremiumStatus' }),
      userId: req.query?.userId,
      email: req.query?.email,
    });
    res.status(500).json({ 
      error: 'Failed to check premium status',
      message: error.message,
    });
  }
});

exports.sendPasswordResetEmail = functions.https.onRequest((req, res) =>
  handleEmailHttpRequest(req, res, {
    templateKey: 'passwordReset',
    requiredFields: ['dynamicData.resetLink'],
  }),
);

exports.sendWeeklyReportEmail = functions.https.onRequest((req, res) =>
  handleEmailHttpRequest(req, res, {
    templateKey: 'weeklyReport',
    requiredFields: ['dynamicData.weekRange', 'dynamicData.headline'],
  }),
);

exports.sendCriticalAlertEmail = functions.https.onRequest((req, res) =>
  handleEmailHttpRequest(req, res, {
    templateKey: 'criticalAlert',
    requiredFields: ['dynamicData.criticalMetrics'],
  }),
);

exports.sendInviteEmail = functions.https.onRequest((req, res) =>
  handleEmailHttpRequest(req, res, {
    templateKey: 'invite',
    requiredFields: ['dynamicData.planFocus', 'dynamicData.ctaLink'],
  }),
);

exports.sendSubscriptionReceiptEmail = functions.https.onRequest((req, res) =>
  handleEmailHttpRequest(req, res, {
    templateKey: 'subscriptionReceipt',
    requiredFields: ['dynamicData.planType', 'dynamicData.amount'],
  }),
);

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
function isEmailServiceConfigured() {
  return Boolean(sendgridApiKey && sendgridFromEmail);
}

async function handleEmailHttpRequest(req, res, { templateKey, requiredFields = [] }) {
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

  if (!isEmailServiceConfigured()) {
    res.status(503).json({ error: 'Email service not configured' });
    return;
  }

  const body = req.body || {};
  const missing = [];

  if (!body.email || (typeof body.email === 'string' && body.email.trim() === '')) {
    missing.push('email');
  }

  const dynamicData =
    body.dynamicData && typeof body.dynamicData === 'object'
      ? body.dynamicData
      : {};

  for (const field of requiredFields) {
    if (field.startsWith('dynamicData.')) {
      const key = field.split('.').slice(1).join('.');
      const value = dynamicData[key];
      if (
        value === undefined ||
        value === null ||
        (typeof value === 'string' && value.trim() === '') ||
        (Array.isArray(value) && value.length === 0)
      ) {
        missing.push(field);
      }
    } else {
      const value = body[field];
      if (
        value === undefined ||
        value === null ||
        (typeof value === 'string' && value.trim() === '') ||
        (Array.isArray(value) && value.length === 0)
      ) {
        missing.push(field);
      }
    }
  }

  if (missing.length > 0) {
    res.status(400).json({
      error: 'Validation failed',
      missing,
    });
    return;
  }

  try {
    await sendTemplatedEmail(templateKey, {
      to: body.email,
      subject: body.subject,
      locale: body.locale || 'en',
      replyTo: body.replyTo,
      dynamicTemplateData: dynamicData,
    });

    logInfo('Templated email dispatched', {
      templateKey,
      email: body.email,
    });

    res.json({ success: true });
  } catch (error) {
    logError('Failed to dispatch templated email', error, {
      templateKey,
      email: body.email,
      sendgridStatusCode: error?.code || error?.response?.statusCode,
      sendgridResponseBody: error?.response?.body,
    });
    res.status(500).json({
      error: 'Failed to send email',
      message: error.message,
      sendgridStatusCode: error?.code || error?.response?.statusCode,
      sendgridResponse: error?.response?.body,
    });
  }
}

async function sendTemplatedEmail(templateKey, options = {}) {
  if (!isEmailServiceConfigured()) {
    throw new Error('Email service not configured');
  }

  const templateId = emailTemplates[templateKey];
  if (!templateId) {
    throw new Error(`Template ID not configured for ${templateKey}`);
  }

  const {
    to,
    subject,
    locale: rawLocale = 'en',
    dynamicTemplateData = {},
    replyTo,
  } = options;

  if (!to || (typeof to === 'string' && to.trim() === '')) {
    throw new Error('Recipient email is required');
  }

  const locale = normalizeLocale(rawLocale);

  const templateDataPayload = {
    locale,
    logoUrl: sendgridLogoUrl,
    supportEmail: sendgridSupportEmail,
    year: new Date().getFullYear(),
    ...dynamicTemplateData,
  };

  if (subject && !templateDataPayload.subject) {
    templateDataPayload.subject = subject;
  }

  const message = {
    to,
    from: {
      email: sendgridFromEmail,
      name: sendgridFromName,
    },
    templateId,
    dynamic_template_data: templateDataPayload,
  };

  if (replyTo) {
    message.replyTo = replyTo;
  }

  if (subject) {
    message.subject = subject;
  }

  try {
    await sendgrid.send(message);
  } catch (error) {
    logError('SendGrid send failed', error, {
      templateKey,
      sendgridStatusCode: error?.code || error?.response?.statusCode,
      sendgridResponseBody: error?.response?.body,
      to,
    });
    throw error;
  }
}

function normalizeLocale(locale) {
  if (!locale || typeof locale !== 'string') {
    return 'en';
  }
  return locale.toLowerCase().split(/[-_]/)[0];
}

function buildSubscriptionReceiptTemplateData({
  locale = 'en',
  planType,
  userName,
  amountTotal,
  currency,
  expiryDate,
  sessionId,
}) {
  const normalizedLocale = normalizeLocale(locale);
  const copy =
    subscriptionReceiptCopy[normalizedLocale] || subscriptionReceiptCopy.en;
  const planName =
    copy.planNames?.[planType] ||
    copy.planNames?.monthly ||
    planType ||
    'Premium';
  const safeName =
    (typeof userName === 'string' && userName.trim()) ||
    copy.userFallbackName ||
    '';

  const introText = copy.introText
    .replace('{{userName}}', safeName)
    .replace('{{planName}}', planName);

  const amount = typeof amountTotal === 'number'
    ? formatCurrencyForLocale(amountTotal, currency, normalizedLocale)
    : '';

  const renewal =
    expiryDate instanceof Date
      ? formatDateForLocale(expiryDate, normalizedLocale)
      : copy.renewalNoExpiryLabel;

  const dynamicTemplateData = {
    subject: copy.subject,
    headline: copy.headline,
    introText,
    planLabel: copy.planLabel,
    planType: planName,
    amountLabel: copy.amountLabel,
    amount,
    renewalLabel: copy.renewalLabel,
    renewalDate: renewal,
    invoiceLabel: copy.invoiceLabel,
    invoiceId: sessionId,
    paymentMethodLabel: copy.paymentMethodLabel,
    paymentMethod: copy.paymentMethodValue,
    managementText: copy.managementText,
    supportNote: copy.supportNote,
    disclaimer: copy.disclaimer,
  };

  return {
    subject: copy.subject,
    dynamicTemplateData,
  };
}

function formatCurrencyForLocale(amount, currency, locale) {
  if (typeof amount !== 'number') {
    return '';
  }

  const currencyCode =
    typeof currency === 'string' && currency.length
      ? currency.toUpperCase()
      : 'USD';

  try {
    return new Intl.NumberFormat(locale || 'en', {
      style: 'currency',
      currency: currencyCode,
    }).format(amount / 100);
  } catch (error) {
    return `${(amount / 100).toFixed(2)} ${currencyCode}`;
  }
}

function formatDateForLocale(date, locale) {
  if (!(date instanceof Date)) {
    return '';
  }

  try {
    return date.toLocaleDateString(locale || 'en', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  } catch (error) {
    return date.toISOString().split('T')[0];
  }
}

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

function logInfo(message, data = {}, context = {}) {
  const payload = {
    message,
    severity: 'INFO',
    timestamp: new Date().toISOString(),
    ...context,
    ...data,
  };
  functions.logger.info(payload);
}

function logError(message, error, context = {}) {
  const payload = {
    message,
    severity: 'ERROR',
    timestamp: new Date().toISOString(),
    error: error?.message || String(error),
    stack: error?.stack,
    ...context,
  };
  functions.logger.error(payload);
}

function buildRequestContext(req, overrides = {}) {
  const requestId =
    req?.get?.('x-request-id') ||
    req?.headers?.['x-request-id'] ||
    crypto.randomUUID();
  const ip =
    req?.headers?.['x-forwarded-for']?.split(',')[0]?.trim() ||
    req?.ip ||
    req?.connection?.remoteAddress;
  const userAgent = req?.headers?.['user-agent'];

  return {
    requestId,
    ip,
    userAgent,
    ...overrides,
  };
}

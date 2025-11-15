# 📧 Email Service Setup Guide - HemoAI

## Overview

HemoAI uses **SendGrid** for professional transactional email delivery. The email service is production-ready with:
- ✅ Secure API key storage (flutter_secure_storage)
- ✅ Retry mechanism (3 attempts with exponential backoff)
- ✅ Rate limiting (10 emails/minute, 100 emails/hour)
- ✅ Professional HTML email templates
- ✅ Multi-language support (9 languages)
- ✅ Error handling and logging

## 🚀 Quick Setup

### Step 1: Create SendGrid Account

1. Sign up at https://sendgrid.com (Free tier: 100 emails/day)
2. Complete email verification
3. Verify your sender email address

### Step 2: Create API Key

1. Go to **Settings** → **API Keys**
2. Click **Create API Key**
3. Name: `HemoAI Production`
4. Permissions: **Full Access** (or **Restricted Access** with "Mail Send" permission)
5. Click **Create & View**
6. **Copy the API key** (starts with `SG.` - you'll only see it once!)

### Step 3: Verify Sender Email

1. Go to **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in:
   - **From Email:** `noreply@hemoai.com` (or your domain)
   - **From Name:** `HemoAI`
   - **Reply To:** `support@hemoai.org`
4. Verify the email address (check inbox)

### Step 4: Configure in HemoAI

#### Option A: Environment Variables (Recommended for Production)

**Build Command:**
```bash
flutter build apk --release \
  --dart-define=SENDGRID_API_KEY=SG.your_api_key_here \
  --dart-define=SENDGRID_FROM_EMAIL=noreply@hemoai.com \
  --dart-define=SENDGRID_FROM_NAME=HemoAI
```

**Run Command:**
```bash
flutter run --release \
  --dart-define=SENDGRID_API_KEY=SG.your_api_key_here \
  --dart-define=SENDGRID_FROM_EMAIL=noreply@hemoai.com \
  --dart-define=SENDGRID_FROM_NAME=HemoAI
```

#### Option B: Programmatic Configuration (Development)

```dart
await EmailService().initialize(
  apiKey: 'SG.your_api_key_here',
  fromEmail: 'noreply@hemoai.com',
  fromName: 'HemoAI',
  preferSecureStorage: true, // API key will be stored securely
);
```

#### Option C: Secure Storage (After First Setup)

Once configured via Option A or B, the API key is automatically stored in `flutter_secure_storage` and will be reused on subsequent app launches. You don't need to provide it again.

## 📱 Usage in Code

### Send Password Reset Email

```dart
final emailService = EmailService();
final success = await emailService.sendPasswordResetEmail(
  toEmail: 'user@example.com',
  resetToken: 'abc123xyz',
  locale: 'tr', // or 'en', 'es', etc.
);

if (success) {
  print('Email sent successfully!');
}
```

### Send Welcome Email

```dart
final emailService = EmailService();
final success = await emailService.sendWelcomeEmail(
  toEmail: 'user@example.com',
  userName: 'John Doe',
  locale: 'en',
);
```

### Send Premium Activation Email

```dart
final emailService = EmailService();
final success = await emailService.sendPremiumActivationEmail(
  toEmail: 'user@example.com',
  userName: 'John Doe',
  tier: 'yearly', // 'monthly', 'yearly', or 'lifetime'
  locale: 'en',
  expiryDate: DateTime.now().add(Duration(days: 365)),
);
```

### Check Service Status

```dart
final emailService = EmailService();
final status = emailService.getStatus();
print('Configured: ${status['isConfigured']}');
print('Test Mode: ${status['isTestMode']}');
print('Rate Limit: ${status['rateLimit']}');
```

## 🔒 Security Best Practices

1. **Never commit API keys to version control**
   - Use environment variables or secure storage
   - API keys are automatically stored securely after first use

2. **Use restricted API keys when possible**
   - Create API keys with only "Mail Send" permission
   - Rotate keys regularly (every 90 days recommended)

3. **Monitor usage**
   - Check SendGrid dashboard regularly
   - Set up alerts for unusual activity

## 🧪 Testing

### Test Mode (Default when API key not configured)

When no API key is provided, the service runs in test mode:
- Emails are logged to console instead of being sent
- All email methods return `true` (simulated success)
- Useful for development and testing

### Production Testing

1. Use SendGrid's test mode first
2. Send test emails to your own address
3. Verify HTML rendering and links
4. Check spam folder
5. Monitor SendGrid dashboard for delivery status

## 📊 Monitoring

### SendGrid Dashboard

- **Activity Feed:** See all sent emails
- **Statistics:** Track delivery rates, opens, clicks
- **Bounce Management:** Handle bounced emails
- **Suppression Lists:** Manage unsubscribes

### Rate Limiting

The service automatically enforces rate limits:
- **10 emails per minute** (prevents spam)
- **100 emails per hour** (prevents abuse)

If limits are exceeded, emails will fail gracefully with logging.

## 🐛 Troubleshooting

### Email Not Sending

1. **Check API key:**
   ```dart
   final status = EmailService().getStatus();
   print(status); // Check 'hasApiKey' and 'isConfigured'
   ```

2. **Check SendGrid logs:**
   - Go to SendGrid Dashboard → Activity
   - Look for error messages

3. **Verify sender email:**
   - Sender must be verified in SendGrid
   - Check spam folder

4. **Check rate limits:**
   ```dart
   final status = EmailService().getStatus();
   print(status['rateLimit']); // Check current usage
   ```

### Common Errors

**401 Unauthorized:**
- Invalid API key
- API key expired or revoked
- Solution: Create new API key and update

**403 Forbidden:**
- API key doesn't have "Mail Send" permission
- Solution: Update API key permissions

**422 Unprocessable Entity:**
- Invalid email address
- Unverified sender
- Solution: Verify sender email in SendGrid

**429 Too Many Requests:**
- Rate limit exceeded
- Solution: Wait and retry (automatic retry handles this)

## 📝 Email Templates

### Supported Languages

- ✅ Turkish (TR)
- ✅ English (EN)
- ✅ Spanish (ES)
- ✅ French (FR)
- ✅ German (DE)
- ✅ Arabic (AR) - RTL support
- ✅ Italian (IT)
- ✅ Portuguese (PT)
- ✅ Russian (RU)

### Template Types

1. **Password Reset Email**
   - Professional HTML design
   - Reset link with 24-hour expiry
   - Security warnings
   - Multi-language support

2. **Welcome Email**
   - Onboarding information
   - Feature highlights
   - Getting started guide

3. **Premium Activation Email**
   - Subscription details
   - Premium feature list
   - Expiry date (if applicable)
   - Upgrade options

## 🔄 Updating API Key

### Update via Code

```dart
final emailService = EmailService();
final success = await emailService.updateApiKey('SG.new_api_key_here');
if (success) {
  print('API key updated successfully!');
}
```

### Clear API Key (Security)

```dart
final emailService = EmailService();
await emailService.clearApiKey(); // Removes from secure storage
```

## 📈 Production Checklist

Before going live:

- [ ] SendGrid account created and verified
- [ ] API key created with appropriate permissions
- [ ] Sender email verified
- [ ] Test emails sent and received
- [ ] HTML templates render correctly
- [ ] Links work (password reset, etc.)
- [ ] Multi-language templates tested
- [ ] Rate limiting tested
- [ ] Error handling tested
- [ ] Monitoring set up (SendGrid dashboard)
- [ ] Backup API key created (for rotation)

## 💰 Pricing

**SendGrid Free Tier:**
- 100 emails/day forever
- Perfect for MVP and small apps

**SendGrid Paid Plans:**
- Essentials: $15/month (40,000 emails)
- Pro: $90/month (100,000 emails)
- More at https://sendgrid.com/pricing

## 📞 Support

**SendGrid Support:**
- Documentation: https://docs.sendgrid.com
- Support: support@sendgrid.com
- Status: https://status.sendgrid.com

**HemoAI Email Issues:**
- Check logs: `EmailService` logs all operations
- Check status: `EmailService().getStatus()`
- Review this guide

---

**Last Updated:** 2025-01-04  
**Version:** 1.0  
**Status:** ✅ Production Ready


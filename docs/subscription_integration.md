# Subscription Integration Guide

This guide explains how HemoAI integrates mobile/web payments and subscriptions across iOS, Android, and Web.

## Overview
- Mobile (iOS/Android): In-App Purchases via `in_app_purchase`.
- Web: Stripe Checkout (server-hosted session).
- Server: Verifies receipts/tokens and stores subscription state; webhooks (Apple ASN v2, Google RTDN) keep state in sync.
- Client Services:
  - `PaymentService`: Orchestrates purchase/restore; requests server verification.
  - `PurchaseVerificationService`: HTTP client for `POST /iap/verify` (falls back to optimistic mapping if not configured).
  - `PremiumService`: Stores tier, lifetime flag, and expiry; revalidates on startup/login.

## Products
- hemoai_premium_monthly
- hemoai_premium_yearly
- hemoai_premium_lifetime

Configure these in App Store Connect and Google Play Console with localized pricing.

## Client Workflow
1. Initialize `PaymentService.initialize()` (lazy; safe in tests). It loads products and listens to purchase updates.
2. User purchases a plan:
   - Mobile: `buyNonConsumable` with the selected `ProductDetails`.
   - Web: Calls server to create Stripe Checkout; user is redirected.
3. On purchase update, `PaymentService` calls `PurchaseVerificationService.verifyReceipt(...)`.
4. Backend returns `{ valid, tier, expiry }`. On success, `PremiumService` is updated:
   - `setTier(SubscriptionTier.premium or lifetime)`
   - `setSubscriptionExpiry(expiry)` for monthly/yearly
   - Persisted keys: `premium_tier`, `subscription_expiry`, `lifetime_purchase`.
5. On app start/login, `PremiumService.initialize()` and `revalidateNow()` ensure consistency and auto-downgrade on expiry.

## Restore Purchases (Mobile)
- `PaymentService.restorePurchases()` triggers store to re-deliver transaction history.
- `PaymentService` handles `PurchaseStatus.restored` in `_onPurchaseUpdate` and verifies/activates accordingly.

## Server API Contract
- POST /iap/verify
  - Request: `{ platform, productId, token, appAccountId?, userEmail? }`
  - Response: `{ valid: boolean, tier: 'monthly'|'yearly'|'lifetime'|'free', expiry?: ISO8601 }`
- Webhooks: See `docs/webhook_strategy.md`.

## Security
- All verification over HTTPS with auth (e.g., Bearer service token).
- Webhooks use HMAC secrets and platform signature validation (Apple JWS, Google JWT).
- Client only activates premium after successful server response.

## Error Handling
- If verification fails: show non-blocking error; keep user on free tier.
- For web purchases: UI shows a pending state after redirect; success is confirmed via webhook and next app session.
- Implement retry with exponential backoff on transient network errors.

## Testing
- Use iOS sandbox users and Android test cards.
- Exercise purchase, restore, refund, revoke, renewal, price change.
- Validate that `PremiumService` downgrades on expiry and persists state across restarts.

## Configuration
- `--dart-define=PURCHASE_VERIFY_URL=https://api.example.com/iap/verify`
- `--dart-define=STRIPE_CHECKOUT_URL=https://.../createStripeCheckoutSession`
- Android: Ensure `BillingClient` depends transitively via `in_app_purchase`.
- iOS: Enable In-App Purchases capability; add products in App Store Connect.

## Future Enhancements
- Device push on subscription changes via FCM topic `user-{userId}`.
- Grace period UI and billing retry nudges.
- Server-driven entitlements mapping by feature flags.

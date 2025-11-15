# Webhook Strategy for Subscriptions (Apple + Google)

This document outlines a production-ready webhook and verification strategy to keep subscription status in sync across devices and platforms. It supports:
- Apple Server Notifications v2 (ASN v2)
- Google Play: Real-time Developer Notifications (RTDN) via Pub/Sub + purchase verification API polling

HemoAI client behavior integrates with server verification via `PurchaseVerificationService` and performs local revalidation at startup/login via `PremiumService.revalidateNow()`.

## Goals
- Verify purchases server-side to prevent fraud.
- Maintain a single source of truth (SSoT) for subscription tier and expiry.
- Update client promptly on lifecycle changes (renewal, grace, pause, refund, revoke, price changes).
- Idempotent, secure, and auditable webhook processing.

## High-level Flow
1. App initiates purchase → receives platform token/receipt.
2. Client sends token to backend `POST /iap/verify`.
3. Backend verifies with Apple/Google, maps to `{tier, expiry, userId, productId}` and stores in DB.
4. Backend returns `{valid, tier, expiry}` to client; client activates premium accordingly.
5. Lifecycle changes are pushed to backend via ASN v2 (Apple) and RTDN (Google). Backend updates DB and notifies devices if needed.
6. On app start/login, the client calls `revalidate` (or `verify` if the token is fresh) to correct drift.

## Endpoints
- POST /iap/verify
  - Body: `{ platform: 'ios'|'android', productId, token, appAccountId?, userEmail? }`
  - Response: `{ valid: boolean, tier: 'monthly'|'yearly'|'lifetime'|'free', expiry?: ISO8601 }`
  - Notes: Use idempotency key (e.g., purchase token + productId) to dedupe.

- POST /webhooks/apple
  - ASN v2 JSON payload with signed JWS.
  - Validate signature with Apple root cert; decode `signedPayload` to extract `notificationType`, `subtype`, `data`. Map to subscription record.

- POST /webhooks/google
  - RTDN push from Pub/Sub (verify JWT). Payload contains `subscriptionNotification` or `oneTimeProductNotification`.
  - Use `purchaseToken` and `subscriptionId` to call Google Play Developer API to verify and fetch status.

## Apple: ASN v2 Details
- Validate the JWS signature chain against Apple.
- Parse `notificationType`/`subtype`:
  - SUBSCRIBED, DID_RENEW, DID_CHANGE_RENEWAL_STATUS, DID_FAIL_TO_RENEW, EXPIRED, REFUND, REVOKE, etc.
- Retrieve `transactionId`, `originalTransactionId`, `productId`, and `signedRenewalInfo`.
- Fetch current subscription status if needed via App Store Server API.
- Map to our tier:
  - hemoai_premium_monthly → monthly
  - hemoai_premium_yearly → yearly
  - hemoai_premium_lifetime → lifetime (non-renewing)
- Update DB row: `{ userId, store='ios', productId, tier, expiry, originalTransactionId, lastEventAt }`.
- Mark events idempotent using `originalTransactionId` + `signedDate`.

## Google: RTDN + Verification Details
- RTDN arrives via Pub/Sub. Validate JWT from Google.
- Extract `purchaseToken`, `subscriptionId`.
- Call Google Play Developer API:
  - `purchases.subscriptionsv2.get` for new API (recommended) or `purchases.subscriptions.get` legacy.
  - Derive `expiryTimeMillis`, `cancelReason`, `paymentState`, `priceChangeState`.
- Map to tier by productId and update DB: `{ userId, store='android', productId, tier, expiry, purchaseToken, lastEventAt }`.
- Idempotency key: `purchaseToken` + `eventTime`.

## Security
- Require HTTPS and HMAC verification for webhooks (private secret per route).
- Validate all signatures (Apple JWS, Google Pub/Sub JWT).
- Rate limit and log all webhook calls; store raw payloads for audit (rotated, PII-minimized).
- Enforce idempotency; handle out-of-order delivery.

## Error Handling
- If verification with store fails transiently, enqueue retry with exponential backoff.
- For unknown productIds, flag and alert.
- If user mapping is missing, store orphaned events with `pendingUserLink=true` and reconcile after user login by `originalTransactionId` (Apple) or `purchaseToken` (Google).

## Device Update Strategy
- After DB write, publish a lightweight event to user devices (optional):
  - FCM topic `user-{userId}`: `{ type: 'SUBSCRIPTION_UPDATE', tier, expiry }`
  - Client receives it and calls `PremiumService.revalidateNow()` or `PurchaseVerificationService.verifyReceipt()` as needed.

## Data Model (Server)
- Table: subscriptions
  - id (PK)
  - user_id (FK)
  - platform ('ios'|'android')
  - product_id
  - tier ('monthly'|'yearly'|'lifetime')
  - expiry (nullable for lifetime)
  - original_transaction_id (Apple, nullable)
  - purchase_token (Google, nullable)
  - is_active (derived)
  - created_at, updated_at, last_event_at
  - idempotency_key

## Local Client Interop
- `PaymentService` persists `last_purchase_product_id` and `last_purchase_token` (if available).
- `PremiumService.initialize()` revalidates on boot; `revalidateNow()` is called on login.
- If backend is not configured, the client falls back to optimistic mapping (debug only), returning valid results for known productIds.

## Testing Checklist
- iOS sandbox purchases; simulate ASN v2 events via App Store Connect.
- Android test card purchases; simulate RTDN via Pub/Sub emulator.
- Verify idempotency: replay the same webhook; no duplicate effects.
- Force out-of-order events; ensure final state is correct.
- Network failures and recovery in verification calls.

## Rollout Plan
- Start in staging with test products and limited users.
- Validate dashboards (Crashlytics, logs) and monitoring.
- Gradually enable in production; monitor error rates and refunds.

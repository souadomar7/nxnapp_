# NXN Warehouses — Supabase Edge Functions

This directory contains the production serverless functions implementing the authoritative backend business layer for the NXN Warehouses platform.

## Architecture Rule
**Flutter is the presentation client layer.**  
Supabase PostgreSQL and Edge Functions are the **authoritative business layer**.  
The client is **never trusted** for:
- Pricing and VAT calculation
- Payment processing & Stripe PaymentIntent creation
- Inventory balance & movement authorization
- Wallet transaction entries
- Seller & KYC approvals
- Administrative privilege checks

---

## Functions Reference

| Function | Endpoint | Description |
|---|---|---|
| `create-payment-intent` | `/functions/v1/create-payment-intent` | Authoritative pricing calculation & Stripe PaymentIntent creation |
| `stripe-webhook` | `/functions/v1/stripe-webhook` | Secure webhook handler for Stripe events (`payment_intent.succeeded`) |
| `confirm-booking` | `/functions/v1/confirm-booking` | Post-payment shelf subscription activation & invoice issuance |
| `wallet-topup` | `/functions/v1/wallet-topup` | Initiates double-entry wallet top-up via Stripe |
| `inventory-receive` | `/functions/v1/inventory-receive` | Validated inbound stock intake with immutable movement log |
| `inventory-dispatch` | `/functions/v1/inventory-dispatch` | Validated outbound dispatch with negative stock prevention |
| `approve-seller` | `/functions/v1/approve-seller` | RBAC-checked merchant approval, shop activation, & audit log |
| `review-kyc` | `/functions/v1/review-kyc` | RBAC-checked KYC review & verification state transition |
| `notify-user` | `/functions/v1/notify-user` | Dispatches in-app notification & FCM push notification |
| `ai-action-execute` | `/functions/v1/ai-action-execute` | Validates & confirms structured AI copilot action requests |

---

## Required Environment Secrets

Set these in Supabase Dashboard -> **Project Settings** -> **Edge Functions** -> **Secrets**:

```bash
STRIPE_SECRET_KEY=sk_live_...              # or sk_test_... for staging
STRIPE_WEBHOOK_SECRET=whsec_...            # from Stripe Webhooks Dashboard
FCM_SERVER_KEY=AAAA...                     # Firebase Cloud Messaging server key
```

---

## Deployment Instructions

```bash
# Deploy all functions to your linked Supabase project
supabase functions deploy

# Or deploy an individual function
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook
```

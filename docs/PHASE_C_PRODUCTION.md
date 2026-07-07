# Phase C — Production Go-Live

Complete these steps when you have a **bKash merchant account** and a **VPS** for the ML worker.

## 1. bKash production credentials

1. Complete [bKash merchant onboarding](https://developer.bka.sh/docs/product-overview)
2. Receive production app key, secret, username, password
3. Set edge secret `BKASH_API_URL` to `https://tokenized.pay.bka.sh/v1.2.0-beta/tokenized`
4. Update `BKASH_*` secrets via `npm run wire-production`
5. Validate tokenized flow on staging before public launch

## 2. ML worker on VPS

1. Deploy `kyc_service/main.py` to Railway, Fly.io, or your VPS (Python 3.11)
2. Set `ML_WORKER_URL` on Vercel to the permanent HTTPS URL
3. Stop using ngrok for production traffic
4. Verify `https://kycservice.vercel.app/health` → `ml_worker_configured: true`

## 3. App URLs

- `CLIENT_APP_URL` → production web URL or `gadgetchai://` deep link
- Supabase Auth redirect URLs → production domain

## 4. Security

- Rotate `CRON_SECRET`, Supabase service role, ngrok tokens
- Enable Supabase leaked password protection (if not already)
- Remove sandbox credentials from committed files

## 5. bKash IPN (recommended)

Implement [Instant Payment Notification](https://developer.bka.sh/docs/webhooks.md) as backup to redirect callbacks.

## 6. Recurring billing validation

Confirm with bKash whether **Tokenized Checkout** `mode 0001` server-side execute is allowed for monthly charges, or migrate to the **Subscriptions** product before relying on `charge-rentals` cron.

## 7. Pre-launch checklist

- [ ] Full E2E on staging: email auth → KYC → bKash live → dispatch → recurring charge
- [ ] Security advisors re-run on Supabase
- [ ] `npm run health-check` all green

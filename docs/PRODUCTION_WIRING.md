# GadgetChai Production Wiring — Quick Reference

> **Full documentation:** [PRODUCTION_SETUP.md](./PRODUCTION_SETUP.md)  
> **Auth setup:** [SUPABASE_AUTH_SETUP.md](./SUPABASE_AUTH_SETUP.md)

## Phase A — Free beta (current)

- **Client:** **Android first**; web optional
- **Auth:** Email + password with email confirmation (no SMS provider)
- **Payments:** bKash tokenized **sandbox** only
- **KYC:** Vercel gateway + ML worker on your PC via ngrok

## Start sandbox dev — Android (primary)

```bash
scripts\start-ml-worker.bat          # 1. ML worker :8000
scripts\start-ngrok.bat              # 2. ngrok tunnel
npm run sync-ngrok -- --deploy       # 3. sync URL → Vercel (after ngrok restart)
cd app && flutter run --dart-define-from-file=.env   # 4. Android device/emulator
```

Set `CLIENT_APP_URL=gadgetchai://` in `app/.env` and run `npm run wire-production` so Supabase edge secrets match Android deep links.

## Start sandbox dev — Web (optional)

```bash
cd app && flutter run -d chrome --dart-define=CLIENT_APP_URL=http://localhost:3000 --dart-define-from-file=.env
```

## One-time setup

```bash
# 1. Configure Supabase Auth (dashboard) — see docs/SUPABASE_AUTH_SETUP.md
# 2. Wire secrets
set SUPABASE_ACCESS_TOKEN=sbp_...
npm run wire-production
```

## Verify

```bash
npm run health-check
npm run charge-rentals                # → 200
```

## Key URLs

| Service | URL |
|---------|-----|
| Supabase | `https://fsdfqcnjcjtdmdjshrvu.supabase.co` |
| KYC gateway | `https://kycservice.vercel.app` |
| bKash sandbox API | `https://tokenized.sandbox.bka.sh/v1.2.0-beta/tokenized` |

## bKash sandbox test wallets

| Source | Wallet | PIN | OTP |
|--------|--------|-----|-----|
| [Merchant demo](https://merchantdemo.sandbox.bka.sh/) | `01770618575` | `12121` | `123456` |
| Project docs | `01929918378` | `12121` | `123456` |

## Phase B / C

See [PRODUCTION_SETUP.md](./PRODUCTION_SETUP.md#launch-phases) for sandbox hardening and production go-live.

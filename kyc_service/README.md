# GadgetChai e-KYC Service

FastAPI service for NID OCR and facial verification.

**Full setup guide:** [../docs/PRODUCTION_SETUP.md](../docs/PRODUCTION_SETUP.md#e-kyc-flow)

## Architecture

| Layer | File | Host |
|-------|------|------|
| Auth gateway | `api/gateway.py` | Vercel (`kycservice.vercel.app`) |
| ML engine | `main.py` | Local machine + ngrok (sandbox) or Railway/Fly (production) |

The gateway validates Supabase JWTs and proxies `/verify_kyc` to `ML_WORKER_URL`.

## First-time ML worker setup (Python 3.11)

```bash
cd kyc_service

# Create venv with Python 3.11 (not 3.14)
python3.11 -m venv .venv          # or uv-managed 3.11 path on Windows

.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\pip install tf-keras "websockets>=13,<16" "supabase>=2.10"
```

Set env vars (from root `.env`):

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`
- `KYC_ALLOW_MOCK=false`

## Run locally

```bash
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Or from repo root: `scripts\start-ml-worker.bat`

Health: `GET http://127.0.0.1:8000/health`

## Deploy gateway to Vercel

```bash
cd kyc_service
vercel --prod
```

Env vars set via `npm run wire-production` or `npm run sync-ngrok` from repo root.

## API

### `GET /health`

Returns service status.

### `POST /verify_kyc`

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | form | Must match JWT `sub` |
| `nid_front` | file | NID front image |
| `nid_back` | file | NID back image |
| `selfie` | file | Live selfie |
| `Authorization` | header | `Bearer <supabase_access_token>` |

Response: `{ "status": "verified" \| "rejected" \| "pending", "score": number, ... }`

## Dependencies note

EasyOCR + DeepFace + TensorFlow are large (~2–7 GB installed). First request triggers model downloads. Use `KYC_ALLOW_MOCK=true` only for local UI testing without ML.

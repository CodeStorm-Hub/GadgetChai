# ML Worker VPS Deployment (Phase 1)

Replace the ngrok tunnel with a persistent VPS for production KYC.

## Requirements

| Resource | Minimum |
|----------|---------|
| CPU | 2 vCPU |
| RAM | 8 GB (16 GB recommended for EasyOCR + DeepFace) |
| Disk | 40 GB SSD |
| OS | Ubuntu 22.04 LTS |
| Python | 3.11 |

## Quick deploy

```bash
# On VPS
sudo apt update && sudo apt install -y python3.11 python3.11-venv nginx

git clone <repo-url> /opt/gadgetchai
cd /opt/gadgetchai/kyc_service
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install tf-keras "websockets>=13,<16" "supabase>=2.10"

# Environment (never commit secrets)
cat > /opt/gadgetchai/kyc_service/.env <<'EOF'
SUPABASE_URL=https://fsdfqcnjcjtdmdjshrvu.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
SUPABASE_ANON_KEY=<your-anon-key>
KYC_ALLOW_MOCK=false
EOF
```

## systemd service

```ini
# /etc/systemd/system/gadgetchai-kyc.service
[Unit]
Description=GadgetChai KYC ML Worker
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/gadgetchai/kyc_service
EnvironmentFile=/opt/gadgetchai/kyc_service/.env
ExecStart=/opt/gadgetchai/kyc_service/.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gadgetchai-kyc
```

## nginx reverse proxy (HTTPS)

```nginx
server {
    listen 443 ssl;
    server_name kyc.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/kyc.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/kyc.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 20M;
    }
}
```

## Wire to Vercel gateway

From repo root with `ML_WORKER_URL` in `.env`:

```bash
# Set ML_WORKER_URL=https://kyc.yourdomain.com in .env
npm run wire-production
# Or update Vercel env only:
npm run sync-ngrok -- --deploy  # replace ngrok URL with VPS URL manually first
```

Update `ML_WORKER_URL` on Vercel to `https://kyc.yourdomain.com`.

## Health check

```bash
curl https://kyc.yourdomain.com/health
# {"status":"ok","mock_enabled":false}
```

## Local dev (unchanged)

For development, continue using `scripts/start-ml-worker.bat` + ngrok + `npm run sync-ngrok -- --deploy`.

See also [docs/PHASE_C_PRODUCTION.md](PHASE_C_PRODUCTION.md) for full go-live checklist.

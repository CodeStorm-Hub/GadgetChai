import os
from typing import Optional

import httpx
from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

app = FastAPI(title="GadgetChai e-KYC Gateway", version="2.0.0")

ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:8000",
    ).split(",")
    if origin.strip()
]

ML_WORKER_URL = os.getenv("ML_WORKER_URL", os.getenv("KYC_SERVICE_URL", "")).rstrip("/")
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


async def verify_supabase_user(authorization: Optional[str], expected_user_id: str) -> None:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization header")

    token = authorization.removeprefix("Bearer ").strip()
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise HTTPException(status_code=503, detail="Auth configuration missing")

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.get(
            f"{SUPABASE_URL}/auth/v1/user",
            headers={"Authorization": f"Bearer {token}", "apikey": SUPABASE_ANON_KEY},
        )

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid or expired session")

    user = response.json()
    if user.get("id") != expected_user_id:
        raise HTTPException(status_code=403, detail="User ID mismatch")


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "mode": "vercel-gateway",
        "ml_worker_configured": bool(ML_WORKER_URL),
    }


@app.post("/verify_kyc")
async def verify_kyc(
    user_id: str = Form(...),
    nid_front: UploadFile = File(...),
    nid_back: UploadFile = File(...),
    selfie: UploadFile = File(...),
    authorization: Optional[str] = Header(default=None),
):
    await verify_supabase_user(authorization, user_id)

    if not ML_WORKER_URL:
        raise HTTPException(
            status_code=503,
            detail="ML_WORKER_URL is not configured. Deploy main.py to Railway/Fly or run locally.",
        )

    front_bytes = await nid_front.read()
    back_bytes = await nid_back.read()
    selfie_bytes = await selfie.read()

    files = {
        "nid_front": (nid_front.filename or "nid_front.jpg", front_bytes, nid_front.content_type or "image/jpeg"),
        "nid_back": (nid_back.filename or "nid_back.jpg", back_bytes, nid_back.content_type or "image/jpeg"),
        "selfie": (selfie.filename or "selfie.jpg", selfie_bytes, selfie.content_type or "image/jpeg"),
    }
    data = {"user_id": user_id}

    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{ML_WORKER_URL}/verify_kyc",
            data=data,
            files=files,
            headers={"Authorization": authorization or ""},
        )

    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)

    return response.json()


handler = Mangum(app)

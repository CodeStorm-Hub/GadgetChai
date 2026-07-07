import os
from typing import Optional

import httpx
from fastapi import Header, HTTPException


def allowed_origins() -> list[str]:
    raw = os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:8000",
    )
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


async def verify_supabase_user(
    authorization: Optional[str],
    expected_user_id: str,
) -> None:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization header")

    token = authorization.removeprefix("Bearer ").strip()
    supabase_url = os.getenv("SUPABASE_URL", "")
    anon_key = os.getenv("SUPABASE_ANON_KEY", "")

    if not supabase_url or not anon_key:
        raise HTTPException(status_code=503, detail="Auth configuration missing")

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.get(
            f"{supabase_url}/auth/v1/user",
            headers={
                "Authorization": f"Bearer {token}",
                "apikey": anon_key,
            },
        )

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid or expired session")

    user = response.json()
    if user.get("id") != expected_user_id:
        raise HTTPException(status_code=403, detail="User ID mismatch")

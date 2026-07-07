import os
import re
import tempfile
from typing import Optional

import httpx
import cv2
import numpy as np
from deepface import DeepFace
import easyocr
from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from supabase import Client, create_client

from auth import allowed_origins, verify_supabase_user

app = FastAPI(title="GadgetChai e-KYC Engine", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
KYC_ALLOW_MOCK = os.getenv("KYC_ALLOW_MOCK", "false").lower() == "true"
NID_VERIFY_URL = os.getenv("NID_VERIFY_URL", "")
NID_VERIFY_API_KEY = os.getenv("NID_VERIFY_API_KEY", "")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

_reader: Optional[easyocr.Reader] = None


def get_ocr_reader() -> easyocr.Reader:
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(["bn", "en"], gpu=False)
    return _reader


def is_image_blurry(image_bytes: bytes, threshold: float = 80.0) -> tuple[bool, float]:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise ValueError("Invalid image file")
    variance = cv2.Laplacian(img, cv2.CV_64F).var()
    return variance < threshold, variance


def parse_nid_details(ocr_text_list: list[str]) -> dict:
    full_text = " ".join(ocr_text_list)

    nid_pattern = r"\b(\d{10}|\d{13}|\d{17})\b"
    nid_match = re.search(nid_pattern, full_text)
    nid_number = nid_match.group(1) if nid_match else None

    dob_pattern = r"\b(\d{2}[-/\s]\d{2}[-/\s]\d{4}|\d{2}[-/\s][A-Za-z]{3,9}[-/\s]\d{4})\b"
    dob_match = re.search(dob_pattern, full_text)
    dob_date = dob_match.group(1) if dob_match else None

    name_pattern = r"(?:Name|নাম)\s*[:：]?\s*([A-Za-z\s]+|[a-zA-Z\u0980-\u09FF\s]+)"
    name_match = re.search(name_pattern, full_text, re.IGNORECASE)
    name = name_match.group(1).strip() if name_match else None

    return {
        "nid_number": nid_number,
        "date_of_birth": dob_date,
        "name": name,
        "raw_text": full_text,
    }


async def verify_nid_with_server(nid_number: Optional[str], name: Optional[str]) -> dict:
    """Optional Election Commission NID server check (BFIU compliance path)."""
    if not NID_VERIFY_URL or not nid_number:
        return {"verified": None, "skipped": True}

    headers = {"Content-Type": "application/json"}
    if NID_VERIFY_API_KEY:
        headers["Authorization"] = f"Bearer {NID_VERIFY_API_KEY}"

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                NID_VERIFY_URL,
                json={"nid_number": nid_number, "name": name},
                headers=headers,
            )
        if response.status_code != 200:
            return {"verified": False, "error": response.text}
        data = response.json()
        return {"verified": data.get("verified", data.get("match", False)), "raw": data}
    except Exception as exc:
        return {"verified": False, "error": str(exc)}


def upload_kyc_document(user_id: str, label: str, content: bytes, content_type: str) -> str:
    path = f"{user_id}/{label}-{os.urandom(4).hex()}.jpg"
    supabase.storage.from_("kyc-documents").upload(
        path,
        content,
        file_options={"content-type": content_type, "upsert": True},
    )
    return path


@app.get("/health")
async def health():
    return {"status": "ok", "mock_enabled": KYC_ALLOW_MOCK}


@app.post("/verify_kyc")
async def verify_kyc(
    user_id: str = Form(...),
    nid_front: UploadFile = File(...),
    nid_back: UploadFile = File(...),
    selfie: UploadFile = File(...),
    authorization: Optional[str] = Header(default=None),
):
    await verify_supabase_user(authorization, user_id)

    limit_result = supabase.rpc(
        "check_and_record_kyc_attempt", {"p_user_id": user_id}
    ).execute()
    limit_data = limit_result.data
    if isinstance(limit_data, list) and limit_data:
        limit_data = limit_data[0]
    if isinstance(limit_data, dict) and not limit_data.get("allowed", True):
        raise HTTPException(
            status_code=429,
            detail=limit_data.get(
                "reason",
                "KYC attempt limit reached. Please try again later or contact support.",
            ),
        )

    front_bytes = await nid_front.read()
    back_bytes = await nid_back.read()
    selfie_bytes = await selfie.read()

    is_front_blurry, front_var = is_image_blurry(front_bytes)
    is_selfie_blurry, selfie_var = is_image_blurry(selfie_bytes)

    if is_front_blurry or is_selfie_blurry:
        return {
            "verified": False,
            "status": "rejected",
            "reason": (
                f"Image is too blurry. Front NID variance: {front_var:.2f}, "
                f"Selfie variance: {selfie_var:.2f}. Min threshold is 80.0."
            ),
        }

    parsed_data: dict = {}
    try:
        nparr = np.frombuffer(front_bytes, np.uint8)
        front_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        reader = get_ocr_reader()
        ocr_result = reader.readtext(front_img, detail=0)
        parsed_data = parse_nid_details(list(ocr_result))
    except Exception as ocr_err:
        if KYC_ALLOW_MOCK:
            parsed_data = {
                "nid_number": "19942608930412345",
                "date_of_birth": "26 Aug 1994",
                "name": "Mock User",
                "raw_text": "MOCK OCR",
            }
        else:
            raise HTTPException(
                status_code=422,
                detail=f"OCR extraction failed: {ocr_err}",
            ) from ocr_err

    nid_server = await verify_nid_with_server(
        parsed_data.get("nid_number"),
        parsed_data.get("name"),
    )
    if nid_server.get("verified") is False and not KYC_ALLOW_MOCK:
        return {
            "verified": False,
            "status": "rejected",
            "reason": "NID could not be verified against the national database.",
            "nid_server": nid_server,
        }

    similarity_score = 0.0
    status = "pending"

    with tempfile.TemporaryDirectory() as tmp_dir:
        front_path = os.path.join(tmp_dir, "front.jpg")
        selfie_path = os.path.join(tmp_dir, "selfie.jpg")
        with open(front_path, "wb") as front_file:
            front_file.write(front_bytes)
        with open(selfie_path, "wb") as selfie_file:
            selfie_file.write(selfie_bytes)

        try:
            result = DeepFace.verify(
                img1_path=front_path,
                img2_path=selfie_path,
                model_name="VGG-Face",
                detector_backend="opencv",
                enforce_detection=False,
            )
            distance = result.get("distance", 1.0)
            similarity_score = 1.0 - distance

            if distance < 0.4:
                status = "approved"
            elif distance > 0.6:
                status = "rejected"
            else:
                status = "pending"
        except Exception as face_err:
            if KYC_ALLOW_MOCK:
                similarity_score = 0.85
                status = "approved"
            else:
                raise HTTPException(
                    status_code=422,
                    detail=f"Facial verification failed: {face_err}",
                ) from face_err

    nid_front_path = upload_kyc_document(
        user_id, "nid-front", front_bytes, nid_front.content_type or "image/jpeg"
    )
    nid_back_path = upload_kyc_document(
        user_id, "nid-back", back_bytes, nid_back.content_type or "image/jpeg"
    )
    selfie_path_storage = upload_kyc_document(
        user_id, "selfie", selfie_bytes, selfie.content_type or "image/jpeg"
    )

    profile_response = supabase.table("profiles").select("id").eq("id", user_id).execute()
    if not profile_response.data:
        supabase.table("profiles").insert({"id": user_id, "role": "customer"}).execute()

    review_status = (
        "pending"
        if status == "pending"
        else ("approved" if status == "approved" else "rejected")
    )

    supabase.table("kyc_reviews").insert(
        {
            "user_id": user_id,
            "nid_number": parsed_data.get("nid_number"),
            "nid_front_url": nid_front_path,
            "nid_back_url": nid_back_path,
            "selfie_url": selfie_path_storage,
            "similarity_score": similarity_score,
            "ocr_data": parsed_data,
            "status": review_status,
            "review_notes": f"Biometric confidence score: {similarity_score:.2f}.",
        }
    ).execute()

    kyc_status_map = {
        "approved": "verified",
        "rejected": "rejected",
        "pending": "pending",
    }
    trust_score = 50
    if status == "approved":
        trust_score = 80
    elif status == "rejected":
        trust_score = 20

    supabase.table("profiles").update(
        {
            "kyc_status": kyc_status_map[status],
            "trust_score": trust_score,
        }
    ).eq("id", user_id).execute()

    return {
        "verified": status == "approved",
        "status": status,
        "similarity_score": similarity_score,
        "extracted_data": parsed_data,
        "message": "KYC process completed successfully.",
    }

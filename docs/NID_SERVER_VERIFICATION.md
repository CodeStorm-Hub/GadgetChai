# NID Server Verification (BFIU Compliance)

GadgetChai supports optional **Election Commission NID database** verification for BFIU e-KYC compliance.

## Configuration

Set in root `.env` and ML worker environment:

```env
NID_VERIFY_URL=https://your-nid-gateway.example/verify
NID_VERIFY_API_KEY=your-api-key
```

When configured, the ML worker (`kyc_service/main.py`) calls this endpoint after OCR extraction. If verification fails, KYC is rejected unless `KYC_ALLOW_MOCK=true`.

## Expected API contract

**POST** `NID_VERIFY_URL`

```json
{
  "nid_number": "1234567890123",
  "name": "Full Name"
}
```

**Response (200)**

```json
{
  "verified": true,
  "match": true
}
```

## Providers

Consider integrating with BFIU-compliant vendors such as [Joinble](https://joinble.io) or your bank's approved NID gateway once merchant onboarding is complete.

## Deadline

BFIU e-KYC guidelines target **31 December 2026** for non-bank entities. Plan production NID server integration before go-live.

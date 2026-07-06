# GadgetChai - Device-as-a-Service (DaaS) Rental Platform

GadgetChai is a modern Device-as-a-Service (DaaS) electronics subscription platform built specifically for the Bangladeshi market. It allows consumers and businesses to rent high-end tech hardware (laptops, phones, cameras, gaming consoles) on flexible monthly terms (1, 3, 6, or 12 months) secured by tokenized recurring billing and an AI-driven e-KYC pipeline.

This project features:
*   **Frontend client:** Flutter mobile & web app (located in `/app`).
*   **e-KYC Service:** FastAPI Python service for OCR NID validation and facial match verification (located in `/kyc_service`).
*   **Database & Edge Functions:** Remote cloud Supabase database integration (`awaken` project) hosting all schemas, tables, and active serverless webhooks.

---

## Technical Stack

*   **App UI:** Flutter SDK, Riverpod (State Management), GoRouter (Navigation), Google Fonts (Outfit & Inter), Supabase Flutter SDK.
*   **Backend Database:** Cloud Supabase Postgres, Row Level Security (RLS) policies, PgBouncer pool.
*   **Payment Gateway Integration:** Custom Deno TypeScript agreement edge webhooks hosted on Supabase Cloud.
*   **AI KYC Verification:** Python 3.10+, FastAPI, Uvicorn, OpenCV, EasyOCR, and DeepFace.

---

## Prerequisites

Ensure you have the following installed on your developer machine:
1.  [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel v3.22+)
2.  [Dart SDK](https://dart.dev/get-started) (Bundled with Flutter)
3.  [Python 3.10+](https://www.python.org/downloads/)

---

## Setup & Startup Guide

Follow these steps in order to start the developer environment.

### Step 1: Remote Supabase Cloud Setup

The database tables, security access rules, and Deno edge webhooks (`bkash-webhook` and `charge-rentals`) live on your cloud Supabase project (`fsdfqcnjcjtdmdjshrvu`).

### Apply schema + seed data

**Option A — SQL Editor (fastest):**

1. Open [Supabase SQL Editor](https://supabase.com/dashboard/project/fsdfqcnjcjtdmdjshrvu/sql/new)
2. Paste the contents of `supabase/setup-all.sql` and run it

**Option B — Seed script:**

1. Add `SUPABASE_SERVICE_ROLE_KEY` or `DATABASE_URL` to `.env` (see `.env.example`)
2. Run the migration SQL in the dashboard first (if not done via Option A)
3. Execute:

```bash
npm run seed
```

**Option C — Supabase MCP:**

1. Reload Cursor so `.mcp.json` picks up the Supabase MCP server
2. Authenticate when prompted
3. Use MCP `execute_sql` to run `supabase/setup-all.sql`

*   The `.env` configuration file is at both the project root and the `app/` folder containing the live cloud endpoints and keys.

---

### Step 2: Start the Python e-KYC OCR Server

Open a terminal session, navigate to the `kyc_service` folder, and configure your virtual environment:

```bash
cd kyc_service

# Create virtual environment
# On Windows:
python -m venv venv
venv\Scripts\activate

# On macOS / Linux:
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Start the FastAPI engine using Uvicorn
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

The e-KYC service will compile and host endpoints at `http://127.0.0.1:8000`. You can inspect interactive Swagger documentation at `http://127.0.0.1:8000/docs`.

---

### Step 3: Run the Flutter Client Application

Launch the frontend client passing the environment configs:

1.  Navigate to the `app` folder:
    ```bash
    cd app
    ```
2.  Install the required package dependencies:
    ```bash
    flutter pub get
    ```
3.  Launch the application using the generated `.env` variables:
    ```bash
    # Run passing environment config properties
    flutter run --dart-define-from-file=.env
    ```

---

## Folder Architecture

```text
├── app/                  # Flutter application client code
│   ├── .env              # Injected environment properties
│   ├── lib/
│   │   ├── core/         # Router (GoRouter), Theme system definitions
│   │   ├── features/     # Feature-focused modules
│   │   │   ├── auth/     # OTP authentication
│   │   │   ├── catalog/  # Explore catalog and device details screen
│   │   │   ├── checkout/ # Cart management, e-KYC camera, bKash webhook
│   │   │   └── rentals/  # Customer Account timeline, return logistics
│   │   └── main.dart     # App entrypoint
├── kyc_service/          # FastAPI Python service for OCR & Facial Match
│   ├── main.py           # API endpoints (Selfie & NID verification)
│   ├── requirements.txt  # Python packages list
├── supabase/             # Migrations, seed SQL, RLS policies
│   ├── migrations/       # Schema extensions + RLS
│   ├── seed.sql          # Catalog, promos, categories, inventory
│   └── setup-all.sql     # One-file migration + seed for SQL Editor
├── scripts/
│   └── seed-database.mjs # Node seed runner (service role or DATABASE_URL)
├── .mcp.json             # Supabase MCP configuration
├── README.md             # Project documentation guide
```

---

## Development Notes

### 1. Verification & Testing
Before committing layout edits, verify static typing and compiler health by running:
```bash
cd app
flutter analyze
```

### 2. Mocking Transactions
For local sandbox checkout flows, the bKash payment gateway agreement runs a mock web view container that simulates transaction approvals, executing success webhooks back into Supabase to provision device contracts instantly.

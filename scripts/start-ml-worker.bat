@echo off
REM Start GadgetChai KYC ML worker (Python 3.11 venv)
cd /d "%~dp0.."
set SUPABASE_URL=https://fsdfqcnjcjtdmdjshrvu.supabase.co
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B "SUPABASE_SERVICE_ROLE_KEY=" .env`) do set %%A=%%B
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B "SUPABASE_ANON_KEY=" .env`) do set %%A=%%B
set KYC_ALLOW_MOCK=false
set TF_ENABLE_ONEDNN_OPTS=0
kyc_service\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --app-dir kyc_service

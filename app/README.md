# GadgetChai Flutter App

**Primary target:** Android  
**Optional:** Web (dev/demo only)

## Android run (recommended)

1. Connect a device or start an emulator with Google Play / camera support.
2. Configure Supabase Auth redirects — see [../docs/SUPABASE_AUTH_SETUP.md](../docs/SUPABASE_AUTH_SETUP.md).
3. Set `CLIENT_APP_URL=gadgetchai://` in `app/.env` **and** in Supabase edge secrets (`npm run wire-production` from repo root).
4. Add redirect URL in Supabase Dashboard: `gadgetchai://**`

```bash
cd app
flutter pub get
flutter run --dart-define-from-file=.env
```

## Web run (optional)

Use a separate env file or override:

```bash
flutter run -d chrome --dart-define-from-file=.env.web
```

Example `app/.env.web`:

```
CLIENT_APP_URL=http://localhost:3000
```

Run with `--web-port 3000` if needed.

## Android deep links

| Purpose | URL |
|---------|-----|
| Email confirm / password reset | `gadgetchai://auth` |
| bKash checkout result | `gadgetchai:///checkout/status?...` |

Declared in `android/app/src/main/AndroidManifest.xml`.

## bKash sandbox on device

Use test wallet `01770618575` (PIN `12121`, OTP `123456`) in checkout or Account tab.

## Permissions

Camera and internet are declared in `AndroidManifest.xml` for KYC capture and API calls.

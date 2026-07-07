# Supabase Auth Setup (Phase A)

Configure project **awaken** (`fsdfqcnjcjtdmdjshrvu`) in the [Supabase Dashboard](https://supabase.com/dashboard).

## Email provider

1. **Authentication → Providers → Email**
   - Enable Email provider
   - **Confirm email:** ON (required before sign-in)
   - Secure email change: ON (recommended)

2. **Authentication → URL configuration**
   - **Site URL:** `gadgetchai://auth` (Android) or `http://localhost:3000` (web-only dev)
   - **Redirect URLs:**
     - `gadgetchai://**` (Android — required)
     - `http://localhost:3000/**` (optional web dev)

3. **Authentication → Providers → Phone**
   - Disable until a paid SMS provider is configured (Phase B/C)

4. **Authentication → Attack protection**
   - Enable **Leaked password protection**

## Optional: custom SMTP

If built-in email rate limits are hit, add Resend/Brevo SMTP under **Project Settings → Auth → SMTP**.

## Verify

1. Sign up in the Flutter app with a real email
2. Click the confirmation link in inbox
3. Sign in with email + password

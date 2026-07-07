#!/usr/bin/env node
/**
 * Wire GadgetChai production secrets to Supabase Edge Functions and Vercel.
 * Requires SUPABASE_ACCESS_TOKEN in environment (or .env.local not committed).
 *
 * Usage: node scripts/wire-production.mjs
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const PROJECT_REF = 'fsdfqcnjcjtdmdjshrvu';

function loadEnv() {
  const env = {};
  for (const file of [join(root, '.env'), join(root, '.env.local')]) {
    if (!existsSync(file)) continue;
    for (const line of readFileSync(file, 'utf8').split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const idx = trimmed.indexOf('=');
      if (idx === -1) continue;
      env[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
    }
  }
  return env;
}

const env = loadEnv();
const token = process.env.SUPABASE_ACCESS_TOKEN;
if (!token) {
  console.error('Set SUPABASE_ACCESS_TOKEN in the environment.');
  process.exit(1);
}

async function api(path, options = {}) {
  const response = await fetch(`https://api.supabase.com/v1${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  });
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!response.ok) {
    throw new Error(`${options.method ?? 'GET'} ${path} → ${response.status}: ${text}`);
  }
  return data;
}

async function fetchServiceRoleKey() {
  const keys = await api(`/projects/${PROJECT_REF}/api-keys?reveal=true`);
  const legacy = keys.find?.((k) => k.name === 'service_role' || k.type === 'service_role');
  if (legacy?.api_key) return legacy.api_key;
  const secret = keys.find?.((k) => k.type === 'secret' || k.name === 'default');
  return secret?.api_key ?? secret?.secret ?? null;
}

async function setCronSettings() {
  const sql = `
INSERT INTO public.app_settings (key, value) VALUES
  ('supabase_url', '${env.SUPABASE_URL}'),
  ('cron_secret', '${env.CRON_SECRET}')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
`;
  await api(`/projects/${PROJECT_REF}/database/query`, {
    method: 'POST',
    body: JSON.stringify({ query: sql }),
  });
  console.log('✓ pg_cron app_settings updated');
}

async function setEdgeSecrets() {
  const secrets = [
    { name: 'BKASH_APP_KEY', value: env.BKASH_APP_KEY },
    { name: 'BKASH_APP_SECRET', value: env.BKASH_APP_SECRET },
    { name: 'BKASH_USERNAME', value: env.BKASH_USERNAME },
    { name: 'BKASH_PASSWORD', value: env.BKASH_PASSWORD },
    { name: 'CRON_SECRET', value: env.CRON_SECRET },
    { name: 'CLIENT_APP_URL', value: env.CLIENT_APP_URL },
    { name: 'BKASH_API_URL', value: env.BKASH_API_URL },
  ].filter((s) => s.value);

  await api(`/projects/${PROJECT_REF}/secrets`, {
    method: 'POST',
    body: JSON.stringify(secrets),
  });
  console.log(`✓ Supabase edge secrets set (${secrets.length} keys)`);
}

function vercelEnvAdd(name, value) {
  for (const target of ['production', 'preview', 'development']) {
    const result = spawnSync(
      'vercel',
      ['env', 'add', name, target, '--force'],
      {
        cwd: join(root, 'kyc_service'),
        input: value,
        encoding: 'utf8',
        shell: true,
      },
    );
    if (result.status !== 0) {
      console.warn(`  vercel env add ${name} ${target}: ${result.stderr || result.stdout}`);
    }
  }
  console.log(`✓ Vercel env: ${name}`);
}

async function main() {
  console.log('Fetching service role key…');
  const serviceRoleKey = await fetchServiceRoleKey();
  if (serviceRoleKey) {
    env.SUPABASE_SERVICE_ROLE_KEY = serviceRoleKey;
    console.log('✓ Service role key retrieved');
  } else {
    console.warn('⚠ Could not retrieve service role key');
  }

  console.log('Setting Supabase edge function secrets…');
  await setEdgeSecrets();

  console.log('Updating pg_cron app_settings…');
  await setCronSettings();

  console.log('Setting Vercel environment variables…');
  const vercelVars = {
    SUPABASE_URL: env.SUPABASE_URL,
    SUPABASE_ANON_KEY: env.SUPABASE_ANON_KEY,
    ML_WORKER_URL: env.ML_WORKER_URL,
    ALLOWED_ORIGINS: env.ALLOWED_ORIGINS,
    KYC_ALLOW_MOCK: env.KYC_ALLOW_MOCK ?? 'false',
  };
  if (serviceRoleKey) {
    vercelVars.SUPABASE_SERVICE_ROLE_KEY = serviceRoleKey;
  }
  for (const [name, value] of Object.entries(vercelVars)) {
    if (value) vercelEnvAdd(name, value);
  }

  console.log('\nDone. Run: npm run charge-rentals  (to test billing cron auth)');
  if (serviceRoleKey) {
    console.log('\nAdd to .env:\nSUPABASE_SERVICE_ROLE_KEY=' + serviceRoleKey);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});

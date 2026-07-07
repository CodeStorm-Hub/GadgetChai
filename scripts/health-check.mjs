#!/usr/bin/env node
/**
 * Ping GadgetChai services (ML worker, KYC gateway, Flutter web, charge-rentals).
 * Usage: node scripts/health-check.mjs
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const envPath = join(root, '.env');

function loadEnv() {
  const env = {};
  if (!existsSync(envPath)) return env;
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    env[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
  }
  return env;
}

async function check(name, url, options = {}) {
  try {
    const res = await fetch(url, options);
    const text = await res.text();
    const ok = res.ok;
    console.log(`${ok ? '✓' : '✗'} ${name}: ${res.status} ${text.slice(0, 120)}`);
    return ok;
  } catch (e) {
    console.log(`✗ ${name}: ${e.message}`);
    return false;
  }
}

const env = loadEnv();
const supabaseUrl = env.SUPABASE_URL ?? 'https://fsdfqcnjcjtdmdjshrvu.supabase.co';
const cronSecret = env.CRON_SECRET;
const mlUrl = env.ML_WORKER_URL ?? 'http://127.0.0.1:8000';
const kycUrl = env.KYC_SERVICE_URL ?? 'https://kycservice.vercel.app';

console.log('GadgetChai health check\n');

await check('KYC gateway', `${kycUrl}/health`);
await check('ML worker (local/ngrok)', `${mlUrl}/health`, {
  headers: { 'ngrok-skip-browser-warning': 'true' },
});
await check('Flutter web', 'http://localhost:3000/');

if (cronSecret) {
  await check('charge-rentals', `${supabaseUrl}/functions/v1/charge-rentals`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${cronSecret}` },
  });
} else {
  console.log('⊘ charge-rentals: CRON_SECRET not set in .env');
}

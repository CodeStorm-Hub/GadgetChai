#!/usr/bin/env node
/**
 * Manually invoke charge-rentals edge function (for cron or testing).
 * Requires CRON_SECRET in .env
 *
 * Usage: node scripts/invoke-charge-rentals.mjs
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');

function loadEnv() {
  const envPath = join(root, '.env');
  if (!existsSync(envPath)) return {};
  const env = {};
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    env[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
  }
  return env;
}

const env = loadEnv();
const supabaseUrl = env.SUPABASE_URL ?? 'https://fsdfqcnjcjtdmdjshrvu.supabase.co';
const cronSecret = env.CRON_SECRET;

if (!cronSecret) {
  console.error('Set CRON_SECRET in .env (must match Supabase Edge Function secret).');
  process.exit(1);
}

const response = await fetch(`${supabaseUrl}/functions/v1/charge-rentals`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${cronSecret}`,
    'Content-Type': 'application/json',
  },
  body: '{}',
});

const text = await response.text();
console.log(`Status: ${response.status}`);
console.log(text);

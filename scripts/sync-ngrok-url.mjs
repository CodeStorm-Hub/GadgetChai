#!/usr/bin/env node
/**
 * Sync active ngrok tunnel URL → .env + Vercel ML_WORKER_URL.
 * Requires NGROK_API_KEY in .env or environment; ngrok agent running on port 8000.
 *
 * Usage: npm run sync-ngrok
 *        npm run sync-ngrok -- --deploy   (also redeploy kyc_service)
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const envPath = join(root, '.env');
const deploy = process.argv.includes('--deploy');

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

function setEnvValue(key, value) {
  if (!existsSync(envPath)) {
    writeFileSync(envPath, `${key}=${value}\n`, 'utf8');
    return;
  }
  const lines = readFileSync(envPath, 'utf8').split('\n');
  let found = false;
  const updated = lines.map((line) => {
    if (line.startsWith(`${key}=`)) {
      found = true;
      return `${key}=${value}`;
    }
    return line;
  });
  if (!found) updated.push(`${key}=${value}`);
  writeFileSync(envPath, updated.join('\n'), 'utf8');
}

async function fetchNgrokUrl(apiKey) {
  // Prefer local agent (fast, no quota)
  try {
    const local = await fetch('http://127.0.0.1:4040/api/tunnels');
    if (local.ok) {
      const data = await local.json();
      const tunnel = data.tunnels?.find(
        (t) => t.config?.addr?.includes(':8000') || t.config?.addr === 'http://localhost:8000',
      );
      if (tunnel?.public_url) return tunnel.public_url.replace(/\/$/, '');
    }
  } catch {
    // agent not running
  }

  const response = await fetch('https://api.ngrok.com/tunnels', {
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Ngrok-Version': '2',
    },
  });
  if (!response.ok) {
    throw new Error(`ngrok API ${response.status}: ${await response.text()}`);
  }
  const data = await response.json();
  const tunnel = data.tunnels?.find((t) => t.forwards_to?.includes('8000'));
  if (!tunnel?.public_url) {
    throw new Error('No ngrok tunnel forwarding to port 8000. Run: scripts\\start-ngrok.bat');
  }
  return tunnel.public_url.replace(/\/$/, '');
}

function buildAllowedOrigins(ngrokUrl, existing) {
  const base = [
    'http://localhost:3000',
    'http://127.0.0.1:8000',
    'https://kycservice.vercel.app',
  ];
  const fromEnv = (existing ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean)
    .filter((o) => !o.includes('ngrok-free.dev') && !o.includes('ngrok.io'));
  return [...new Set([...base, ...fromEnv, ngrokUrl])].join(',');
}

function vercelEnvAdd(name, value) {
  for (const target of ['production', 'preview', 'development']) {
    spawnSync('vercel', ['env', 'add', name, target, '--force'], {
      cwd: join(root, 'kyc_service'),
      input: value,
      encoding: 'utf8',
      shell: true,
    });
  }
  console.log(`✓ Vercel env: ${name}`);
}

async function main() {
  const env = loadEnv();
  const apiKey = process.env.NGROK_API_KEY ?? env.NGROK_API_KEY;
  if (!apiKey) {
    console.error('Set NGROK_API_KEY in .env');
    process.exit(1);
  }

  const ngrokUrl = await fetchNgrokUrl(apiKey);
  console.log(`ngrok tunnel: ${ngrokUrl}`);

  setEnvValue('ML_WORKER_URL', ngrokUrl);
  const origins = buildAllowedOrigins(ngrokUrl, env.ALLOWED_ORIGINS);
  setEnvValue('ALLOWED_ORIGINS', origins);
  console.log('✓ Updated .env (ML_WORKER_URL, ALLOWED_ORIGINS)');

  vercelEnvAdd('ML_WORKER_URL', ngrokUrl);
  vercelEnvAdd('ALLOWED_ORIGINS', origins);

  if (deploy) {
    console.log('Redeploying kyc_service…');
    const result = spawnSync('vercel', ['--prod', '--yes'], {
      cwd: join(root, 'kyc_service'),
      encoding: 'utf8',
      shell: true,
    });
    if (result.status !== 0) {
      console.error(result.stderr || result.stdout);
      process.exit(1);
    }
    console.log('✓ Vercel redeployed');
  } else {
    console.log('Tip: npm run sync-ngrok -- --deploy  to redeploy after URL change');
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});

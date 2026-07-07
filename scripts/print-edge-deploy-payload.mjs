#!/usr/bin/env node
/**
 * Reads edge function sources and prints JSON for Supabase MCP deploy.
 * Usage: node scripts/print-edge-deploy-payload.mjs bkash-webhook
 */

import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const slug = process.argv[2];
if (!slug) {
  console.error('Usage: node scripts/print-edge-deploy-payload.mjs <function-slug>');
  process.exit(1);
}

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const indexPath = join(root, 'supabase', 'functions', slug, 'index.ts');
const sharedPath = join(root, 'supabase', 'functions', '_shared', 'bkash.ts');

const payload = {
  project_id: 'fsdfqcnjcjtdmdjshrvu',
  name: slug,
  entrypoint_path: 'index.ts',
  verify_jwt: false,
  files: [
    { name: 'index.ts', content: readFileSync(indexPath, 'utf8') },
    { name: '../_shared/bkash.ts', content: readFileSync(sharedPath, 'utf8') },
  ],
};

process.stdout.write(JSON.stringify(payload));

writeFileSync(
  join(root, '.edge-deploy-payload.json'),
  JSON.stringify(payload),
  'utf8',
);

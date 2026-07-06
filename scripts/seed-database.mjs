#!/usr/bin/env node
/**
 * Applies GadgetChai migrations and seed data to remote Supabase.
 *
 * Option A (recommended): set DATABASE_URL in .env (Supabase → Settings → Database → Connection string)
 * Option B: set SUPABASE_SERVICE_ROLE_KEY in .env (inserts seed rows via REST; run migration SQL in dashboard first)
 *
 * Usage: node scripts/seed-database.mjs
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

async function runWithDatabaseUrl(databaseUrl) {
  const pg = await import('pg');
  const client = new pg.default.Client({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();

  const migration = readFileSync(join(root, 'supabase/migrations/20260706120000_gadget_chai_schema.sql'), 'utf8');
  const seed = readFileSync(join(root, 'supabase/seed.sql'), 'utf8');

  console.log('Applying schema migration...');
  await client.query(migration);
  console.log('Seeding database...');
  await client.query(seed);
  await client.end();
  console.log('Done.');
}

async function runWithServiceRole(url, serviceKey) {
  const headers = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    'Content-Type': 'application/json',
    Prefer: 'resolution=merge-duplicates,return=minimal',
  };

  const devices = [
    {
      id: '11111111-1111-1111-1111-111111000001',
      name: 'Apple iPhone 17 Pro - 256GB', brand: 'Apple', category: 'Phones & Tablets',
      description: '6.3-inch LTPO Super Retina XDR OLED, 12GB Unified Memory, A19 Pro chip.',
      image_url: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500',
      monthly_price_1m: 7500, monthly_price_3m: 6500, monthly_price_6m: 6000, monthly_price_12m: 5500,
      is_out_of_stock: false, is_featured: true, sort_order: 1,
      specs_memory: '12GB LPDDR6', specs_battery: '3988 mAh Li-Ion',
      specs_display: '6.3-inch LTPO Super Retina XDR OLED', specs_processor: 'Apple A19 Pro (3nm)',
      specs_camera: 'Triple 48MP Rear, 12MP Front',
    },
    {
      id: '11111111-1111-1111-1111-111111000002',
      name: 'Sony Alpha 7 IV (Body)', brand: 'Sony', category: 'Cameras',
      description: '33MP Full-Frame Exmor R CMOS Sensor, 4K 60p Video.',
      image_url: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=500',
      monthly_price_1m: 9500, monthly_price_3m: 8000, monthly_price_6m: 7000, monthly_price_12m: 6000,
      is_out_of_stock: false, is_featured: true, sort_order: 2,
      specs_memory: 'Dual card slots', specs_battery: 'NP-FZ100',
      specs_display: '3.0-inch Vari-Angle Touchscreen', specs_processor: 'BIONZ XR',
      specs_camera: '33 Megapixels Full Frame',
    },
    {
      id: '11111111-1111-1111-1111-111111000003',
      name: 'Nintendo Switch 2 Console', brand: 'Nintendo', category: 'Gaming Consoles',
      description: 'Lightning-fast loading, 4K dock modes, next-gen mobility.',
      image_url: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=500',
      monthly_price_1m: 4500, monthly_price_3m: 3800, monthly_price_6m: 3300, monthly_price_12m: 2800,
      is_out_of_stock: false, is_featured: true, sort_order: 3,
    },
    {
      id: '11111111-1111-1111-1111-111111000004',
      name: 'ASUS ROG Zephyrus G14', brand: 'ASUS', category: 'Computers',
      description: 'AMD Ryzen 9, RTX 4070, 16GB DDR5, 1TB SSD.',
      image_url: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=500',
      monthly_price_1m: 8500, monthly_price_3m: 7200, monthly_price_6m: 6500, monthly_price_12m: 5500,
      is_out_of_stock: true, is_featured: false, sort_order: 4,
    },
    {
      id: '11111111-1111-1111-1111-111111000005',
      name: 'DJI Mavic 3 Pro Cine', brand: 'DJI', category: 'Cameras',
      description: 'Triple-camera system, Apple ProRes 422 HQ, 43-min flight time.',
      image_url: 'https://images.unsplash.com/photo-1508614589041-895b88991e3e?w=500',
      monthly_price_1m: 15000, monthly_price_3m: 13000, monthly_price_6m: 11500, monthly_price_12m: 10000,
      is_out_of_stock: false, is_featured: false, sort_order: 5,
    },
    {
      id: '11111111-1111-1111-1111-111111000006',
      name: 'MacBook Pro 16" M3 Max', brand: 'Apple', category: 'Computers',
      description: '16-inch Liquid Retina XDR, M3 Max, 36GB memory, 1TB SSD.',
      image_url: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500',
      monthly_price_1m: 12000, monthly_price_3m: 10000, monthly_price_6m: 9000, monthly_price_12m: 8000,
      is_out_of_stock: false, is_featured: false, sort_order: 6,
    },
  ];

  console.log('Upserting devices via service role...');
  const deviceRes = await fetch(`${url}/rest/v1/devices?on_conflict=id`, {
    method: 'POST', headers: { ...headers, Prefer: 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify(devices),
  });
  if (!deviceRes.ok) throw new Error(`devices: ${await deviceRes.text()}`);

  const promos = [
    { id: '33333333-3333-3333-3333-333333000001', title: 'The game is on', description: 'Rent TVs, projectors, soundbars and more.', bg_color: '#1E293B', text_color: '#FFFFFF', image_url: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500', sort_order: 1 },
    { id: '33333333-3333-3333-3333-333333000002', title: 'This is the summer you actually start', description: 'Get the tech you need this summer for a low monthly rate.', bg_color: '#FDE047', text_color: '#1E293B', image_url: 'https://images.unsplash.com/photo-1484755560695-a4c7300c5c29?w=500', sort_order: 2 },
    { id: '33333333-3333-3333-3333-333333000003', title: 'Extra perks for students', description: 'Exclusive student discounts from ৳1,500/Month.', bg_color: '#67E8F9', text_color: '#0F172A', image_url: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=500', sort_order: 3 },
  ];

  const promoRes = await fetch(`${url}/rest/v1/promos?on_conflict=id`, {
    method: 'POST', headers, body: JSON.stringify(promos),
  });
  if (!promoRes.ok && !String(await promoRes.text()).includes('PGRST205')) {
    console.warn('promos table may need migration first:', await promoRes.text());
  }

  const categories = [
    { id: '44444444-4444-4444-4444-444444000001', title: 'Phones & Tablets', image_url: 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=200', sort_order: 1 },
    { id: '44444444-4444-4444-4444-444444000002', title: 'Computers', image_url: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=200', sort_order: 2 },
    { id: '44444444-4444-4444-4444-444444000003', title: 'Cameras', image_url: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=200', sort_order: 3 },
    { id: '44444444-4444-4444-4444-444444000004', title: 'Gaming Consoles', image_url: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=200', sort_order: 4 },
  ];

  const catRes = await fetch(`${url}/rest/v1/categories?on_conflict=title`, {
    method: 'POST', headers, body: JSON.stringify(categories),
  });
  if (!catRes.ok && !String(await catRes.text()).includes('PGRST205')) {
    console.warn('categories table may need migration first');
  }

  const items = [
    { id: '22222222-2222-2222-2222-222222000001', device_id: '11111111-1111-1111-1111-111111000006', serial_number: 'SN-MBP-398242', imei: 'N/A', condition_grade: 'Grade A', status: 'rented', purchase_cost: 280000, cumulative_revenue: 310000 },
    { id: '22222222-2222-2222-2222-222222000002', device_id: '11111111-1111-1111-1111-111111000002', serial_number: 'SN-SONY-748301', imei: 'N/A', condition_grade: 'Grade B', status: 'available', purchase_cost: 180000, cumulative_revenue: 90000 },
    { id: '22222222-2222-2222-2222-222222000003', device_id: '11111111-1111-1111-1111-111111000003', serial_number: 'SN-PS5-903418', imei: 'N/A', condition_grade: 'Grade A', status: 'maintenance', purchase_cost: 65000, cumulative_revenue: 42000 },
    { id: '22222222-2222-2222-2222-222222000004', device_id: '11111111-1111-1111-1111-111111000001', serial_number: 'SN-IPH-102938', imei: '356789012345678', condition_grade: 'Grade A', status: 'rented', purchase_cost: 145000, cumulative_revenue: 88000 },
  ];

  const itemRes = await fetch(`${url}/rest/v1/device_items?on_conflict=id`, {
    method: 'POST', headers, body: JSON.stringify(items),
  });
  if (!itemRes.ok) console.warn('device_items:', await itemRes.text());

  const countRes = await fetch(`${url}/rest/v1/devices?select=id`, { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } });
  const rows = await countRes.json();
  console.log(`Seed complete. devices count: ${rows.length}`);
}

async function main() {
  const env = loadEnv();
  const databaseUrl = process.env.DATABASE_URL || env.DATABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_SERVICE_ROLE_KEY;
  const url = process.env.SUPABASE_URL || env.SUPABASE_URL || 'https://fsdfqcnjcjtdmdjshrvu.supabase.co';

  if (databaseUrl) {
    await runWithDatabaseUrl(databaseUrl);
    return;
  }

  if (serviceKey) {
    await runWithServiceRole(url, serviceKey);
    return;
  }

  console.error(`Missing credentials. Add one of these to ${join(root, '.env')}:`);
  console.error('  DATABASE_URL=postgresql://postgres.[ref]:[password]@...');
  console.error('  SUPABASE_SERVICE_ROLE_KEY=... (from Supabase Dashboard → Settings → API)');
  console.error('\nAlso run supabase/migrations/20260706120000_gadget_chai_schema.sql in the SQL Editor first.');
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

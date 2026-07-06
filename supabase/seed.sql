-- GadgetChai seed data (idempotent)
-- Run via: node scripts/seed-database.mjs
-- Or paste into Supabase SQL Editor

-- Fixed UUIDs for stable references across app and tests
-- Devices: 11111111-1111-1111-1111-11111100000N

INSERT INTO public.devices (
  id, name, brand, category, description, image_url,
  monthly_price_1m, monthly_price_3m, monthly_price_6m, monthly_price_12m,
  is_out_of_stock, is_featured, sort_order,
  specs_memory, specs_battery, specs_display, specs_processor, specs_camera
) VALUES
(
  '11111111-1111-1111-1111-111111000001',
  'Apple iPhone 17 Pro - 256GB', 'Apple', 'Phones & Tablets',
  '6.3-inch LTPO Super Retina XDR OLED, 12GB Unified Memory, A19 Pro chip. The next generation of mobile computing.',
  'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500',
  7500, 6500, 6000, 5500, false, true, 1,
  '12GB LPDDR6', '3988 mAh Li-Ion', '6.3-inch LTPO Super Retina XDR OLED (1206 x 2622 px)', 'Apple A19 Pro (3nm)', 'Triple 48MP Rear, 12MP Front'
),
(
  '11111111-1111-1111-1111-111111000002',
  'Sony Alpha 7 IV (Body)', 'Sony', 'Cameras',
  '33MP Full-Frame Exmor R CMOS Sensor, Up to 10 fps Shooting, ISO 100-51200, 4K 60p Video. Ideal for professional videographers.',
  'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=500',
  9500, 8000, 7000, 6000, false, true, 2,
  'Dual card slots (SD/CFexpress Type A)', 'NP-FZ100 battery (approx. 520 shots)', '3.0-inch 1.03m-dot Vari-Angle Touchscreen LCD', 'BIONZ XR image processor', '33 Megapixels Full Frame'
),
(
  '11111111-1111-1111-1111-111111000003',
  'Nintendo Switch 2 Console', 'Nintendo', 'Gaming Consoles',
  'Experience lightning-fast loading, support for haptic feedback, 4K dock modes, and next-gen mobility.',
  'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=500',
  4500, 3800, 3300, 2800, false, true, 3,
  '12GB unified memory', '4310 mAh battery', '7.9-inch OLED handheld display', 'Custom NVIDIA Tegra', 'N/A'
),
(
  '11111111-1111-1111-1111-111111000004',
  'ASUS ROG Zephyrus G14', 'ASUS', 'Computers',
  'AMD Ryzen 9, RTX 4070, 16GB DDR5, 1TB SSD. Portable, high-performance rendering laptop.',
  'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=500',
  8500, 7200, 6500, 5500, true, false, 4,
  '16GB DDR5', '76Wh battery', '14-inch QHD 165Hz display', 'AMD Ryzen 9 + RTX 4070', 'N/A'
),
(
  '11111111-1111-1111-1111-111111000005',
  'DJI Mavic 3 Pro Cine', 'DJI', 'Cameras',
  'Triple-camera system, Apple ProRes 422 HQ, 43-min flight time, omnidirectional obstacle sensing.',
  'https://images.unsplash.com/photo-1508614589041-895b88991e3e?w=500',
  15000, 13000, 11500, 10000, false, false, 5,
  '1TB internal storage', '5000 mAh intelligent flight battery', 'N/A', 'Hasselblad triple-camera system', '4/3 CMOS Hasselblad + dual tele'
),
(
  '11111111-1111-1111-1111-111111000006',
  'MacBook Pro 16" M3 Max', 'Apple', 'Computers',
  '16-inch Liquid Retina XDR display, M3 Max chip, 36GB unified memory, 1TB SSD. Built for creators.',
  'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500',
  12000, 10000, 9000, 8000, false, false, 6,
  '36GB unified memory', '100Wh battery', '16.2-inch Liquid Retina XDR', 'Apple M3 Max', 'N/A'
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  brand = EXCLUDED.brand,
  category = EXCLUDED.category,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  monthly_price_1m = EXCLUDED.monthly_price_1m,
  monthly_price_3m = EXCLUDED.monthly_price_3m,
  monthly_price_6m = EXCLUDED.monthly_price_6m,
  monthly_price_12m = EXCLUDED.monthly_price_12m,
  is_out_of_stock = EXCLUDED.is_out_of_stock,
  is_featured = EXCLUDED.is_featured,
  sort_order = EXCLUDED.sort_order,
  specs_memory = EXCLUDED.specs_memory,
  specs_battery = EXCLUDED.specs_battery,
  specs_display = EXCLUDED.specs_display,
  specs_processor = EXCLUDED.specs_processor,
  specs_camera = EXCLUDED.specs_camera,
  updated_at = now();

INSERT INTO public.device_items (
  id, device_id, serial_number, imei, condition_grade, status, purchase_cost, cumulative_revenue
) VALUES
(
  '22222222-2222-2222-2222-222222000001',
  '11111111-1111-1111-1111-111111000006',
  'SN-MBP-398242', 'N/A', 'Grade A', 'rented', 280000.00, 310000.00
),
(
  '22222222-2222-2222-2222-222222000002',
  '11111111-1111-1111-1111-111111000002',
  'SN-SONY-748301', 'N/A', 'Grade B', 'available', 180000.00, 90000.00
),
(
  '22222222-2222-2222-2222-222222000003',
  '11111111-1111-1111-1111-111111000003',
  'SN-PS5-903418', 'N/A', 'Grade A', 'maintenance', 65000.00, 42000.00
),
(
  '22222222-2222-2222-2222-222222000004',
  '11111111-1111-1111-1111-111111000001',
  'SN-IPH-102938', '356789012345678', 'Grade A', 'rented', 145000.00, 88000.00
)
ON CONFLICT (id) DO UPDATE SET
  device_id = EXCLUDED.device_id,
  serial_number = EXCLUDED.serial_number,
  imei = EXCLUDED.imei,
  condition_grade = EXCLUDED.condition_grade,
  status = EXCLUDED.status,
  purchase_cost = EXCLUDED.purchase_cost,
  cumulative_revenue = EXCLUDED.cumulative_revenue,
  updated_at = now();

INSERT INTO public.promos (id, title, description, bg_color, text_color, image_url, sort_order) VALUES
(
  '33333333-3333-3333-3333-333333000001',
  'The game is on',
  'The biggest football event of the year is your excuse to upgrade. Rent TVs, projectors, soundbars and more.',
  '#1E293B', '#FFFFFF',
  'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500', 1
),
(
  '33333333-3333-3333-3333-333333000002',
  'This is the summer you actually start',
  'More daylight, more energy, more reasons to try new things. Get the tech you need this summer for a low monthly rate.',
  '#FDE047', '#1E293B',
  'https://images.unsplash.com/photo-1484755560695-a4c7300c5c29?w=500', 2
),
(
  '33333333-3333-3333-3333-333333000003',
  'Extra perks for students',
  'Ace your summer semester with the right tech — exclusive student discounts make it easier than ever to get started. From ৳1,500/Month.',
  '#67E8F9', '#0F172A',
  'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=500', 3
)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  bg_color = EXCLUDED.bg_color,
  text_color = EXCLUDED.text_color,
  image_url = EXCLUDED.image_url,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

INSERT INTO public.categories (id, title, image_url, sort_order) VALUES
('44444444-4444-4444-4444-444444000001', 'Phones & Tablets', 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=200', 1),
('44444444-4444-4444-4444-444444000002', 'Computers', 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=200', 2),
('44444444-4444-4444-4444-444444000003', 'Cameras', 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=200', 3),
('44444444-4444-4444-4444-444444000004', 'Gaming Consoles', 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=200', 4)
ON CONFLICT (title) DO UPDATE SET
  image_url = EXCLUDED.image_url,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

-- Sample fulfillment rentals (no user FK — for admin kanban demo only when no real rentals exist)
INSERT INTO public.rentals (
  id, user_id, device_id, plan_months, monthly_price, security_deposit,
  status, delivery_otp, start_date, next_billing_date, end_date
)
SELECT
  '55555555-5555-5555-5555-555555000001'::uuid,
  p.id,
  '11111111-1111-1111-1111-111111000002'::uuid,
  3, 8000.00, 0.00,
  'awaiting_dispatch', '4820',
  now(), now() + interval '30 days', now() + interval '90 days'
FROM public.profiles p
WHERE p.role = 'admin'
LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.rentals (
  id, user_id, device_id, plan_months, monthly_price, security_deposit,
  status, delivery_otp, start_date, next_billing_date, end_date
)
SELECT
  '55555555-5555-5555-5555-555555000002'::uuid,
  p.id,
  '11111111-1111-1111-1111-111111000006'::uuid,
  12, 8000.00, 0.00,
  'in_transit', '9045',
  now(), now() + interval '30 days', now() + interval '365 days'
FROM public.profiles p
WHERE p.role = 'admin'
LIMIT 1
ON CONFLICT (id) DO NOTHING;

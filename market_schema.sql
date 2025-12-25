-- SME Marketplace Schema
create extension if not exists "uuid-ossp";

-- 1. Profiles for Sellers (Extending auth.users)
create table if not exists public.sme_sellers (
  id uuid references auth.users not null primary key,
  business_name text,
  contact_number text,
  is_verified boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Product Catalog
create table if not exists public.sme_products (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.sme_sellers(id) not null,
  name text not null,
  description text,
  price numeric not null, -- Selling price
  photo_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Warehouses (New)
create table if not exists public.warehouses (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  name_ar text,
  emirate text not null,
  location_lat numeric,
  location_lng numeric,
  total_shelves integer default 100,
  price_per_shelf numeric default 100.0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Inventory (Stock on Shelf)
-- Updated with warehouse_id and shelf_label
create table if not exists public.sme_inventory (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.sme_sellers(id) not null,
  product_id uuid references public.sme_products(id),
  warehouse_id uuid references public.warehouses(id), -- Linked to specific warehouse
  shelf_id text, -- Identifier for the physical 100 AED shelf (Legacy?)
  shelf_label text, -- e.g "Dubai-Shelf-04"
  quantity integer default 0,
  status text check (status in ('in_stock', 'damaged', 'reserved')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Inbound Requests (Drop-offs)
-- Updated with labor and inspection options
create table if not exists public.sme_inbound_requests (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.sme_sellers(id) not null,
  warehouse_id uuid references public.warehouses(id),
  expected_date timestamp with time zone,
  item_count integer,
  labor_count integer default 0, -- Number of workers requested
  visual_inspection_requested boolean default false, -- Detailed inspection
  status text default 'pending', -- pending, accepted, completed, rejected
  notes text,
  gate_pass_code text, -- QR Code content
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Outbound Orders (Sales/Delivery)
create table if not exists public.sme_orders (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.sme_sellers(id) not null,
  customer_name text,
  customer_address text,
  delivery_method text check (delivery_method in ('pickup', 'delivery')),
  status text default 'pending', -- pending, picked, out_for_delivery, completed
  total_amount numeric,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. User Subscriptions (Shelf Rentals)
create table if not exists public.sme_subscriptions (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.sme_sellers(id) not null,
  warehouse_id uuid references public.warehouses(id) not null,
  shelves_count integer default 1,
  start_date timestamp with time zone default timezone('utc'::text, now()),
  end_date timestamp with time zone,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS (Row Level Security)
alter table public.sme_sellers enable row level security;
alter table public.sme_products enable row level security;
alter table public.sme_inventory enable row level security;
alter table public.sme_inbound_requests enable row level security;
alter table public.sme_orders enable row level security;
alter table public.sme_subscriptions enable row level security;

-- Policies (Simple: Users can only see/edit their own data)
create policy "Users can view own seller profile" on public.sme_sellers for select using (auth.uid() = id);
create policy "Users can update own seller profile" on public.sme_sellers for update using (auth.uid() = id);
create policy "Users can insert own seller profile" on public.sme_sellers for insert with check (auth.uid() = id);

create policy "Users can view own products" on public.sme_products for all using (auth.uid() = seller_id);
create policy "Users can view own inventory" on public.sme_inventory for all using (auth.uid() = seller_id);
create policy "Users can view own inbound" on public.sme_inbound_requests for all using (auth.uid() = seller_id);
create policy "Users can view own orders" on public.sme_orders for all using (auth.uid() = seller_id);
create policy "Users can view own subscriptions" on public.sme_subscriptions for all using (auth.uid() = seller_id);

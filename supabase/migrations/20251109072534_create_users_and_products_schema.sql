/*
  # E-Commerce Platform - Initial Schema Setup

  ## Overview
  This migration sets up the core database structure for a multi-vendor e-commerce platform
  where users can register as sellers and list their products for sale.

  ## New Tables

  ### 1. `user_profiles`
  - `id` (uuid, primary key) - Links to auth.users
  - `email` (text) - User email
  - `full_name` (text) - User's full name
  - `phone` (text) - Contact phone number
  - `role` (text) - User role: 'customer', 'seller', 'admin'
  - `is_seller_approved` (boolean) - Whether seller account is approved
  - `store_name` (text) - Seller's store name
  - `store_description` (text) - About the seller's store
  - `avatar_url` (text) - Profile picture URL
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 2. `categories`
  - `id` (uuid, primary key)
  - `name` (text) - Category name
  - `slug` (text, unique) - URL-friendly name
  - `description` (text) - Category description
  - `image_url` (text) - Category image
  - `parent_id` (uuid) - For subcategories
  - `created_at` (timestamptz)

  ### 3. `products`
  - `id` (uuid, primary key)
  - `seller_id` (uuid) - References user_profiles
  - `category_id` (uuid) - References categories
  - `name` (text) - Product name
  - `slug` (text) - URL-friendly name
  - `description` (text) - Product description
  - `price` (decimal) - Product price
  - `compare_price` (decimal) - Original price for discounts
  - `stock_quantity` (integer) - Available stock
  - `sku` (text) - Stock keeping unit
  - `is_active` (boolean) - Product visibility
  - `is_featured` (boolean) - Featured product flag
  - `weight` (decimal) - Product weight
  - `images` (jsonb) - Array of image URLs
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 4. `orders`
  - `id` (uuid, primary key)
  - `customer_id` (uuid) - References user_profiles
  - `order_number` (text, unique) - Human-readable order number
  - `status` (text) - Order status
  - `total_amount` (decimal) - Total order amount
  - `shipping_address` (jsonb) - Delivery address
  - `payment_status` (text) - Payment status
  - `payment_method` (text) - Payment method used
  - `notes` (text) - Order notes
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 5. `order_items`
  - `id` (uuid, primary key)
  - `order_id` (uuid) - References orders
  - `product_id` (uuid) - References products
  - `seller_id` (uuid) - References user_profiles
  - `quantity` (integer) - Item quantity
  - `price` (decimal) - Price at time of purchase
  - `subtotal` (decimal) - Line item total
  - `created_at` (timestamptz)

  ### 6. `reviews`
  - `id` (uuid, primary key)
  - `product_id` (uuid) - References products
  - `customer_id` (uuid) - References user_profiles
  - `rating` (integer) - 1-5 star rating
  - `comment` (text) - Review text
  - `is_verified_purchase` (boolean) - Verified buyer
  - `created_at` (timestamptz)

  ## Security
  - RLS enabled on all tables
  - Policies for authenticated users to manage their own data
  - Admin-only policies for sensitive operations
  - Sellers can only manage their own products
  - Customers can view products and manage their orders

  ## Important Notes
  - All monetary values use decimal type for precision
  - JSONB used for flexible data (images, addresses)
  - Comprehensive indexes for performance
  - Foreign keys maintain referential integrity
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text,
  phone text,
  role text DEFAULT 'customer' CHECK (role IN ('customer', 'seller', 'admin')),
  is_seller_approved boolean DEFAULT false,
  store_name text,
  store_description text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  image_url text,
  parent_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL CHECK (price >= 0),
  compare_price decimal(10,2) CHECK (compare_price >= 0),
  stock_quantity integer DEFAULT 0 CHECK (stock_quantity >= 0),
  sku text,
  is_active boolean DEFAULT true,
  is_featured boolean DEFAULT false,
  weight decimal(10,2),
  images jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(seller_id, slug)
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  order_number text UNIQUE NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  total_amount decimal(10,2) NOT NULL CHECK (total_amount >= 0),
  shipping_address jsonb NOT NULL,
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_method text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  seller_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  price decimal(10,2) NOT NULL CHECK (price >= 0),
  subtotal decimal(10,2) NOT NULL CHECK (subtotal >= 0),
  created_at timestamptz DEFAULT now()
);

-- Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  is_verified_purchase boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  UNIQUE(product_id, customer_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_slug ON products(slug);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- RLS Policies for categories
CREATE POLICY "Anyone can view categories"
  ON categories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert categories"
  ON categories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update categories"
  ON categories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete categories"
  ON categories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for products
CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT
  TO authenticated
  USING (
    is_active = true OR 
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Approved sellers can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    seller_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('seller', 'admin')
      AND (is_seller_approved = true OR role = 'admin')
    )
  );

CREATE POLICY "Sellers can update own products"
  ON products FOR UPDATE
  TO authenticated
  USING (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Sellers can delete own products"
  ON products FOR DELETE
  TO authenticated
  USING (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for orders
CREATE POLICY "Customers can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    customer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM order_items
      WHERE order_items.order_id = orders.id 
      AND order_items.seller_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Customers and admins can update orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    customer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    customer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for order_items
CREATE POLICY "Users can view relevant order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id 
      AND orders.customer_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Customers can insert order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id 
      AND orders.customer_id = auth.uid()
    )
  );

-- RLS Policies for reviews
CREATE POLICY "Anyone can view reviews"
  ON reviews FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Customers can create reviews"
  ON reviews FOR INSERT
  TO authenticated
  WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Customers can update own reviews"
  ON reviews FOR UPDATE
  TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Customers can delete own reviews"
  ON reviews FOR DELETE
  TO authenticated
  USING (
    customer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS text AS $$
DECLARE
    new_number text;
    counter integer;
BEGIN
    counter := (SELECT COUNT(*) FROM orders) + 1;
    new_number := 'ORD-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(counter::text, 6, '0');
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
    ) THEN
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW EXECUTE FUNCTION handle_new_user();
    END IF;
END $$;
# Golden Pearl — Luxury Fashion House

## Overview
A bilingual (Arabic RTL + English LTR) luxury fashion e-commerce mobile app built with Flutter, backed by an Express.js + PostgreSQL API server. The brand specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and gift packaging.

## Tech Stack
- **Mobile App**: Flutter 3.22.0 (Dart), targeting iOS, Android, and Web
- **Backend**: Express.js + TypeScript, PostgreSQL with Drizzle ORM
- **Localization**: flutter_localizations + intl + ARB files (Arabic default, English toggle)
- **State Management**: Provider (ChangeNotifier)
- **Auth**: bcrypt password hashing, express-session for session management
- **Security**: helmet (secure headers), express-rate-limit (auth 10/min, upload 30/min, API 200/min), compression
- **Styling**: Custom luxury soft neutral theme, PlayfairDisplay headings, Material Design 3

## Design System (Luxury Soft Neutral Spec)
- **Primary Gold**: #B89B5E (accent only), **Dark Gold**: #9C7F42
- **Background**: #F4F4F4 (soft neutral), **Card Background**: #FFFFFF
- **Charcoal Text**: #1C1C1C, **Secondary Text**: #6B6B6B, **Divider**: #EAEAEA
- **Button Radius**: 12px, primary = solid gold, secondary = gold outline
- **Product Cards**: 4:5 aspect ratio, full bleed images, shimmer placeholder, fade-in
- **Category Highlights**: Circular real product images (96px, subtle shadow, thin gold ring)
- **Motion**: fade + vertical lift (250-320ms), button press scale 0.97
- **Currency**: SAR (Saudi Riyal), stored as integer halalas (×100)
- **Arabic Mode**: Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩), ر.س suffix, Arabic comma ٬
- **English Mode**: Western digits, "SAR" prefix, standard comma
- **Brand Name**: Always "Golden Pearl" in both languages
- **Terminology**: "السلة" (Cart) — not "الحقيبة" (Bag)

## Architecture
### Flutter App (`golden_pearl/`)
- `lib/main.dart` — App entry, luxury theme, navigation (4 tabs: Home, Shop, Cart, Settings), route handling (/login, /admin)
- `lib/screens/` — HomeScreen, ShopScreen, CategoryScreen, ProductDetailScreen, CartScreen, CheckoutScreen (with login guard + store pickup), OrdersScreen, NotificationsScreen, SettingsScreen, OrderConfirmationScreen, LoginScreen
- `lib/screens/admin/` — AdminDashboard (7 pages: Overview, Products, Orders, Hero, Categories + bottom nav 5 tabs + drawer 7 items including Promotions, Notifications), AdminProductsScreen (category tabs), AdminProductFormScreen (create/edit with image upload), AdminOrdersScreen (with item thumbnails), AdminHeroPage (unified slides + per-slide text overlays with AR/EN editing, live preview, typography/position controls), AdminCategoriesScreen (image upload + visibility + reorder + name editing), AdminPromotions (discount code management), AdminNotificationsScreen (send to all users)
- `lib/providers/` — LanguageProvider, CartProvider, FavoritesProvider, AuthProvider (login/register/logout/checkAuth)
- `lib/services/api_service.dart` — HTTP client with auth endpoints, admin CRUD, analytics tracking
- `lib/models/` — Product (with stock field), CartItem, Order, AppNotification
- `lib/utils/` — money_formatter.dart, arabic_digits.dart
- `lib/widgets/` — product_card, shimmer_placeholder, category_icons, hero_video_background, luxury_video_player
- `lib/l10n/` — app_ar.arb, app_en.arb (complete bilingual strings)
- `lib/l10n/generated/` — Auto-generated AppLocalizations
- `assets/images/` — Brand photos, `assets/videos/` — Product videos
- `fonts/` — PlayfairDisplay (Regular, SemiBold, Bold)

### Backend (`server/`) — Clean Architecture
- `server/index.ts` — Express server with helmet, compression, rate limiting, CORS, session, static file serving
- `server/routes.ts` — Thin route registration (~98 lines), delegates to controllers
- `server/storage.ts` — PostgreSQL storage layer with IStorage interface and DatabaseStorage class
- `server/db.ts` — Drizzle + pg pool setup
- `server/seed.ts` — Seeds products, discount codes, admin user, site settings
- `server/payments.ts` — Payment abstraction layer (mock provider, ready for Moyasar)
- `server/shipping.ts` — Shipping abstraction layer (flat-rate SA, ready for Aramex/SMSA)
- `server/controllers/` — Business logic split into domain controllers:
  - `auth.controller.ts` — Register, login, logout, me, merge cart
  - `products.controller.ts` — List, get, create, update, delete, stock, reorder
  - `cart.controller.ts` — Get, add, update, remove, clear
  - `orders.controller.ts` — Create (with stock validation), list, get, admin list, status update (with notifications)
  - `uploads.controller.ts` — Unified file upload (smart image/video detection), delete, multer config with dual MIME+extension validation
  - `admin.controller.ts` — Banners CRUD, categories CRUD, discounts CRUD, notifications, settings, analytics
  - `public.controller.ts` — Public banners (cached), categories (cached), discount validation, notifications, settings, page views
  - `payments.controller.ts` — Payment stubs, session management
  - `shipping.controller.ts` — Quote, create shipment, track
- `server/middleware/` — Cross-cutting concerns:
  - `asyncHandler.ts` — Wraps async handlers, forwards errors to error middleware
  - `auth.ts` — isAdmin middleware (checks session + user role)
  - `cache.ts` — In-memory cache with TTL (60s for banners/categories), invalidation on admin writes
  - `errorHandler.ts` — Centralized error handler (AppError, MulterError, unknown errors)
- `server/utils/` — Shared utilities:
  - `AppError.ts` — Typed error class with factory methods (badRequest, unauthorized, forbidden, notFound, conflict, internal)
  - `response.ts` — Standardized response helpers
- `shared/schema.ts` — Drizzle ORM schema with indexes (products: category+orderIndex, orders: createdAt+userId, banners: active+sortOrder, categories: sortOrder)

## Security
- **Helmet**: Secure HTTP headers (X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security, etc.)
- **Rate Limiting**: Auth 10/min, upload 30/min, API 200/min
- **Session Cookies**: httpOnly, sameSite: lax, secure in production
- **Upload Hardening**: Dual MIME+extension validation, UUID filenames, path traversal prevention
- **Error Handling**: Centralized via AppError class, no stack trace leaking to clients

## Authentication & Authorization
- **Guest browsing**: Users can browse all products, add to cart, search — no login required
- **Login-on-checkout**: Checkout guard redirects to login screen if not authenticated; on login, guest cart merges into user cart
- **Admin access**: Settings screen shows "Admin Panel" tile only when user role is 'admin'
- **Admin credentials**: email=admin@goldenpearl.com, password=admin123
- **Session-based**: express-session with userId stored in session

## Admin Panel
Accessible from Settings → Admin Panel (only visible to admin users). Admin name: "Zainab Hussain". Navigation: 5-tab bottom nav (Dashboard, Products, Orders, Hero, Categories) + drawer adds Promotions, Notifications.
- **Dashboard**: Welcome message, stat cards (products, orders, visits, sessions), top viewed products list, quick action links
- **Products**: Category tabs (All/Dresses/Jalabiyas/Kids/Gifts), stock color coding, edit/duplicate/delete actions, stock update dialog
- **Product Form**: Create/edit with multi-image upload (sharp compression), name En/Ar, price, category, description, stock, sizes, colors
- **Orders**: Filtered tabs (All/Delivery/Pickup), product thumbnails in order cards, status update dialog, order detail bottom sheet
- **Hero** (unified): Slide list with image previews, upload new slides (image), toggle active, drag-to-reorder, delete. Each slide has per-slide text overlay editing (AR/EN) with full typography controls (font family, size, weight, letter spacing, color, shadow, alignment, position preset), live preview on actual slide image. Overlays stored as JSON in banner `overlay` column
- **Categories**: Upload category images, edit AR/EN names (pencil icon → dialog), toggle visibility, drag-to-reorder (4 default: Dresses, Jalabiyas, Kids, Gifts)
- **Promotions**: Discount code CRUD, percentage/fixed types, expiration dates, min order, usage tracking
- **Notifications**: Compose and send notifications to all users, optional product link

## Currency & Pricing
- All monetary values stored as **integer halalas** (1 SAR = 100 halalas)
- Shipping threshold: 15000 halalas (150 SAR), fee: 1500 halalas (15 SAR)

## Performance
- **DB Indexes**: products(category, orderIndex), orders(createdAt, userId), banners(active+sortOrder), categories(sortOrder)
- **In-Memory Cache**: Banners and categories cached for 60s, invalidated on admin writes
- **Compression**: gzip/brotli via compression middleware
- **Static Assets**: 7-day cache with immutable headers
- **Video Streaming**: Range request support for MP4 files

## Features
- **Bilingual**: Arabic RTL (default) ↔ English LTR with persistent language toggle
- **Home**: Dynamic banner carousel with per-slide text overlays (from banner `overlay` JSON, fallback to l10n defaults), fallback to default hero video when no banners, dynamic category circles (from admin, fallback to defaults), featured products grid
- **Shop**: Product listing with filters, search, sort
- **Product Detail**: Multi-image + video slider, fullscreen zoom, size/color selectors
- **Cart**: Cart + Wishlist tabs, swipe-to-delete, quantity management
- **Checkout**: Login guard, delivery/pickup toggle, discount codes
- **Orders**: Full status tracking with notifications
- **Admin Panel**: Full Shopify-like CMS (products, orders, banners, categories, promotions, notifications, settings, analytics)
- **Media Upload**: Image compression via sharp (max 1200px, JPEG quality 80), video upload support, unified upload endpoint with smart detection

## Database Tables
- **users**: id, email (unique), passwordHash, name, phone, role (default 'user'), createdAt
- **products**: id, nameEn/Ar, descriptionEn/Ar, price, originalPrice, category, images[], videoUrl, sizes[], colors[], fabricEn/Ar, inStock, featured, badge, rating, reviewCount, stock (default 100), orderIndex (default 0) — *indexes: category, orderIndex*
- **banners**: id, type ("image"|"video"), url (text), active (boolean default true), sortOrder (integer default 0), overlay (text, JSON with per-slide AR/EN text + style), createdAt — *index: active+sortOrder*
- **categories**: id, slug (text unique), nameEn (text), nameAr (text), imageUrl (text nullable), visible (boolean default true), sortOrder (integer default 0) — *index: sortOrder*
- **cart_items**: id, sessionId, userId (nullable), productId, quantity, size, color
- **orders**: id, sessionId, userId (nullable), items (JSONB), subtotal/shipping/discount/total, status, deliveryMethod, customer info, notes — *indexes: createdAt, userId*
- **discount_codes**: id, code, type, value, minOrder, maxUses, usedCount, active, expiresAt
- **notifications**: id, userId, orderId, productId (nullable), title, message, read, createdAt
- **admin_users**: id, username, passwordHash
- **site_settings**: id, key (unique), value, updatedAt
- **page_views**: id, sessionId, page, productId, createdAt

## API Endpoints
### Public
- `GET /api/products` — List products (?category, ?search, ?featured)
- `GET /api/products/:id` — Single product
- `GET/POST/PATCH/DELETE /api/cart` — Cart CRUD
- `POST /api/orders` — Create order (stock validation)
- `GET /api/orders` — Order history
- `POST /api/discounts/validate` — Validate discount code
- `GET /api/notifications` — User notifications
- `GET /api/banners` — Active banners (sorted, cached 60s)
- `GET /api/categories` — Visible categories (sorted, cached 60s)
- `GET /api/settings/:key` — Public setting value
- `POST /api/analytics/pageview` — Record page view

### Auth
- `POST /api/auth/register` — Create account (rate limited 10/min)
- `POST /api/auth/login` — Login (rate limited 10/min)
- `POST /api/auth/logout` — Logout
- `GET /api/auth/me` — Current user
- `POST /api/auth/merge` — Merge guest cart into user cart

### Admin (requires admin role)
- `POST /api/admin/upload` — Upload media (unified endpoint, rate limited 30/min)
- `DELETE /api/admin/upload` — Delete uploaded file
- `POST/PATCH/DELETE /api/admin/products/:id` — Product CRUD
- `PATCH /api/admin/products/:id/stock` — Update stock
- `PATCH /api/admin/products/reorder` — Reorder products by orderIndex
- `GET /api/admin/orders` — All orders
- `PATCH /api/admin/orders/:id/status` — Update status (triggers notifications)
- `CRUD /api/admin/banners` — Banner management (create, list, update, delete, reorder)
- `CRUD /api/admin/categories` — Category management (update image, toggle visibility, reorder)
- `POST /api/admin/notifications/send` — Send notification to all users
- `GET/PUT /api/admin/settings/:key` — Site settings
- `GET /api/admin/analytics` — Visit analytics
- `POST/GET/PATCH/DELETE /api/admin/discounts` — Discount code management

## Running
- Workflow "Start application" runs `npm run dev` → Express server on port 5000
- Express serves Flutter web build from `golden_pearl/build/web/`
- To rebuild Flutter: `cd golden_pearl && flutter pub get && flutter gen-l10n && flutter build web --release`
- Copy assets after build: images/ and videos/ to build/web/

## Pending (Deferred until credentials provided)
- **Moyasar Apple Pay**: Backend stubs exist — needs API keys
- **Firebase Cloud Messaging**: Needs FCM credentials

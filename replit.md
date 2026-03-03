# Golden Pearl — Luxury Fashion House

## Overview
A bilingual (Arabic RTL + English LTR) luxury fashion e-commerce mobile app built with Flutter, backed by an Express.js + PostgreSQL API server. The brand specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and gift packaging.

## Tech Stack
- **Mobile App**: Flutter 3.22.0 (Dart), targeting iOS, Android, and Web
- **Backend**: Express.js + TypeScript, PostgreSQL with Drizzle ORM
- **Localization**: flutter_localizations + intl + ARB files (Arabic default, English toggle)
- **State Management**: Provider (ChangeNotifier)
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
- `lib/main.dart` — App entry, luxury theme, navigation (5 tabs: Home, Shop, Cart, Notifications, Settings), route handling
- `lib/screens/` — HomeScreen, ShopScreen, CategoryScreen, ProductDetailScreen, CartScreen, CheckoutScreen (with store pickup), OrdersScreen, NotificationsScreen, SettingsScreen, OrderConfirmationScreen
- `lib/providers/` — LanguageProvider (AR/EN with persistence), CartProvider (int halalas), FavoritesProvider (local SharedPreferences)
- `lib/services/api_service.dart` — HTTP client for Express API (products, cart, orders, notifications, discounts)
- `lib/models/` — Product (int price), CartItem, Order (int monetary fields, deliveryMethod), AppNotification
- `lib/utils/money_formatter.dart` — SAR formatting with Arabic-Indic digits
- `lib/utils/arabic_digits.dart` — Arabic-Indic digit conversion for all numbers
- `lib/widgets/product_card.dart` — Luxury product card with shimmer, heart favorite toggle, quick add-to-cart button
- `lib/widgets/shimmer_placeholder.dart` — Animated shimmer loading
- `lib/widgets/category_icons.dart` — Custom icons (used in category pages)
- `lib/l10n/` — app_ar.arb, app_en.arb (complete bilingual strings including notifications, pickup, statuses)
- `lib/l10n/generated/` — Auto-generated AppLocalizations (via `flutter gen-l10n`)
- `l10n.yaml` — L10n config with `synthetic-package: false`, output to `lib/l10n/generated/`
- `assets/images/` — Brand photos (hero1-3, logo, product images)
- `fonts/` — PlayfairDisplay (Regular, SemiBold, Bold)

### Backend (`server/`)
- `server/index.ts` — Express server with CORS, session, serves Flutter web build
- `server/routes.ts` — RESTful API endpoints (products, cart, orders, notifications, payments, shipping, admin)
- `server/storage.ts` — PostgreSQL storage layer (DatabaseStorage) with full CRUD
- `server/db.ts` — Drizzle + pg pool setup
- `server/seed.ts` — Seeds 28 products + 3 discount codes (all in halalas)
- `server/payments.ts` — Payment session management (stub for Moyasar)
- `server/shipping.ts` — Shipping quote and tracking (stub)
- `shared/schema.ts` — Drizzle ORM schema (all monetary fields = integer halalas)

## Currency & Pricing
- All monetary values stored as **integer halalas** (1 SAR = 100 halalas)
- Example: 1,089 SAR = 108900 in database
- Shipping threshold: 15000 halalas (150 SAR)
- Shipping fee: 1500 halalas (15 SAR)
- MoneyFormatter handles locale-aware display

## Features
- **Bilingual**: Arabic RTL (default) ↔ English LTR with persistent language toggle
- **Home**: Hero banner carousel, real product image category circles (96px, subtle shadow), featured products grid, brand info
- **Category Pages**: Dedicated `/category/:slug` pages for each category (dresses, jalabiyas, kids, gifts)
- **Shop**: Product listing with category filters, search, sort
- **Product Detail**: Multi-image + video media slider with thumbnails, fullscreen image zoom (pinch/double-tap/pan), video player with controls, size/color selectors, quantity controls, add to cart (auto-return to previous page), fabric info, ratings
- **Cart**: Tabbed view (Cart + Wishlist), swipe-to-delete, quantity management, free shipping threshold (SAR 150), order summary
- **Checkout**: Delivery method toggle (delivery / store pickup), hardcoded store info card (Saihat) with map/call buttons, shipping form with country/city pickers, discount code validation
- **Orders**: Order history with full status tracking (Pending, Paid, Processing, Ready for Pickup, Picked Up, Shipped, Delivered)
- **Notifications**: In-app notification list with unread badge on bell icon (5th tab), auto-created on order status changes
- **Settings**: AR/EN language toggle, brand info, policies

## Order Status Flow
- `pending` → `paid` (after Moyasar payment confirmation) → `processing` → `ready_for_pickup` / `shipped` → `picked_up` / `delivered`
- Notification auto-created when status changes to `ready_for_pickup`, `shipped`, or `delivered`

## Delivery Methods
- **Delivery**: Standard shipping to customer address (SAR 15 fee, free over SAR 150)
- **Store Pickup**: Free, shows hardcoded store info card (Golden Pearl - Saihat 32437, phone 055 501 2942, Google Maps link)

## API Endpoints
- `GET /api/products` — List products (`?category=`, `?search=`, `?featured=true`)
- `GET /api/products/:id` — Single product
- `GET/POST/PATCH/DELETE /api/cart` — Cart CRUD (session-based)
- `POST /api/orders` — Create order (with deliveryMethod field)
- `GET /api/orders` — Order history
- `POST /api/discounts/validate` — Validate discount code
- `GET /api/notifications` — User notifications
- `GET /api/notifications/unread-count` — Unread count
- `PATCH /api/notifications/:id/read` — Mark as read
- `POST /api/payments/create` — Payment intent stub (Moyasar)
- `POST /api/webhooks/moyasar` — Payment webhook stub
- `POST /api/payments/session` — Payment session creation
- `POST /api/shipping/quote` — Shipping quote
- `PATCH /api/admin/orders/:id/status` — Update order status (triggers notifications)
- Admin: `POST/PATCH/DELETE /api/admin/products`, `GET /api/admin/orders`, `POST/GET/DELETE /api/admin/discounts`

## Database Tables
- **products**: id, nameEn, nameAr, descriptionEn, descriptionAr, price (int halalas), originalPrice (int), category, images[], videoUrl, sizes[], colors[], fabricEn, fabricAr, inStock, featured, badge, rating, reviewCount
- **cart_items**: id, sessionId, productId, quantity, size, color
- **orders**: id, sessionId, items (JSONB), subtotal/shipping/discount/total (all int halalas), status, deliveryMethod, customer info, shipping info, notes
- **discount_codes**: id, code, type, value (int), minOrder (int), maxUses, usedCount, active, expiresAt
- **notifications**: id, userId (sessionId), orderId, title, message, read (boolean), createdAt
- **admin_users**: id, username, passwordHash

## Discount Codes (seeded)
- WELCOME10 — 10% off, min order 10000 halalas (SAR 100)
- EID25 — 25% off, min order 20000 halalas (SAR 200)
- FREESHIP — Fixed 1500 halalas (SAR 15) off, min order 15000 halalas (SAR 150)

## Running
- Workflow "Start application" runs `npm run dev` → Express server on port 5000
- Express serves Flutter web build from `golden_pearl/build/web/`
- To rebuild Flutter: `cd golden_pearl && flutter gen-l10n && flutter build web --release`
- Images must be copied after build: `mkdir -p golden_pearl/build/web/images && cp golden_pearl/assets/images/*.png golden_pearl/build/web/images/`

## Pending (Deferred until credentials provided)
- **Moyasar Apple Pay**: Backend stubs exist at `/api/payments/create` and `/api/webhooks/moyasar` — needs API keys to activate
- **Firebase Cloud Messaging**: Device token storage + push notification delivery on order status changes — needs FCM credentials
- **GitHub Sync**: Repo at github.com/aboudz-bit/golden-pearl

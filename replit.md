# Golden Pearl — Luxury Fashion House

## Overview
A bilingual (Arabic RTL + English LTR) luxury fashion e-commerce mobile app built with Flutter, backed by an Express.js + PostgreSQL API server. The brand specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and gift packaging.

## Tech Stack
- **Mobile App**: Flutter 3.22.0 (Dart), targeting iOS, Android, and Web
- **Backend**: Express.js + TypeScript, PostgreSQL with Drizzle ORM
- **Localization**: flutter_localizations + intl + ARB files (Arabic default, English toggle)
- **State Management**: Provider (ChangeNotifier)
- **Styling**: Custom luxury gold theme (#B89B5E), PlayfairDisplay headings, Material Design 3

## Design System (Master Luxury Build Spec)
- **Primary Gold**: #B89B5E, **Dark Gold**: #9C7F42
- **Cream Background**: #F6F3EE, **Charcoal Text**: #1C1C1C, **Divider**: #E8E3D8
- **Button Radius**: 12px, primary = solid gold, secondary = gold outline
- **Product Cards**: 4:5 aspect ratio, full bleed images, shimmer placeholder, fade-in
- **Category Highlights**: Instagram-style circular (68px, 2px gold ring, cream inner)
- **Motion**: fade + vertical lift (250-320ms), button press scale 0.97
- **Currency**: SAR (Saudi Riyal), stored as integer halalas (×100)
- **Arabic Mode**: Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩), ر.س suffix, Arabic comma ٬
- **English Mode**: Western digits, "SAR" prefix, standard comma
- **Brand Name**: Always "Golden Pearl" in both languages

## Architecture
### Flutter App (`golden_pearl/`)
- `lib/main.dart` — App entry, luxury theme, navigation, route handling
- `lib/screens/` — HomeScreen, ShopScreen, CategoryScreen, ProductDetailScreen, CartScreen, CheckoutScreen, OrdersScreen, SettingsScreen, OrderConfirmationScreen
- `lib/providers/` — LanguageProvider (AR/EN with persistence), CartProvider (int halalas)
- `lib/services/api_service.dart` — HTTP client for Express API
- `lib/models/` — Product (int price), CartItem, Order (int monetary fields)
- `lib/utils/money_formatter.dart` — SAR formatting with Arabic-Indic digits
- `lib/utils/arabic_digits.dart` — Arabic-Indic digit conversion for all numbers
- `lib/widgets/product_card.dart` — Luxury product card with shimmer
- `lib/widgets/shimmer_placeholder.dart` — Animated shimmer loading
- `lib/l10n/` — app_ar.arb, app_en.arb (complete bilingual strings)
- `assets/images/` — Brand photos (hero1-3, logo)
- `assets/fonts/` — PlayfairDisplay (bundled locally)

### Backend (`server/`)
- `server/index.ts` — Express server with CORS, session, serves Flutter web build
- `server/routes.ts` — RESTful API endpoints
- `server/storage.ts` — PostgreSQL storage layer (DatabaseStorage)
- `server/db.ts` — Drizzle + pg pool setup
- `server/seed.ts` — Seeds 10 products + 3 discount codes (all in halalas)
- `shared/schema.ts` — Drizzle ORM schema (all monetary fields = integer halalas)

## Currency & Pricing
- All monetary values stored as **integer halalas** (1 SAR = 100 halalas)
- Example: 1,089 SAR = 108900 in database
- Shipping threshold: 15000 halalas (150 SAR)
- Shipping fee: 1500 halalas (15 SAR)
- MoneyFormatter handles locale-aware display

## Features
- **Bilingual**: Arabic RTL (default) ↔ English LTR with persistent language toggle
- **Home**: Hero banner carousel, Instagram-style circular category highlights (tap → dedicated category page), featured products grid, brand info
- **Category Pages**: Dedicated `/category/:slug` pages for each category (dresses, jalabiyas, kids, gifts) with back button, localized title, search within category, sort, product grid
- **Shop**: Product listing with category filters, search, sort (newest/price/bestsellers)
- **Product Detail**: Image carousel, size/color selectors, quantity controls, add to cart, fabric info, ratings
- **Cart**: Swipe-to-delete, quantity management, free shipping threshold (SAR 150), order summary
- **Checkout**: Shipping form, discount code validation, order placement
- **Orders**: Order history with status tracking (Processing, Shipped, Delivered)
- **Settings**: AR/EN language toggle, brand info, policies

## API Endpoints
- `GET /api/products` — List products (`?category=`, `?search=`, `?featured=true`)
- `GET /api/products/:id` — Single product
- `GET/POST/PATCH/DELETE /api/cart` — Cart CRUD (session-based)
- `POST /api/orders` — Create order
- `GET /api/orders` — Order history
- `POST /api/discounts/validate` — Validate discount code
- Admin: `POST/PATCH/DELETE /api/admin/products`, `GET/PATCH /api/admin/orders`, `POST/GET/DELETE /api/admin/discounts`

## Database Tables
- **products**: id, nameEn, nameAr, descriptionEn, descriptionAr, price (int halalas), originalPrice (int), category, images[], sizes[], colors[], fabricEn, fabricAr, inStock, featured, badge, rating, reviewCount
- **cart_items**: id, sessionId, productId, quantity, size, color
- **orders**: id, sessionId, items (JSONB), subtotal/shipping/discount/total (all int halalas), status, customer info, shipping info
- **discount_codes**: id, code, type, value (int), minOrder (int), maxUses, usedCount, active, expiresAt

## Discount Codes (seeded)
- WELCOME10 — 10% off, min order 10000 halalas (SAR 100)
- EID25 — 25% off, min order 20000 halalas (SAR 200)
- FREESHIP — Fixed 1500 halalas (SAR 15) off, min order 15000 halalas (SAR 150)

## Running
- Workflow "Start application" runs `npm run dev` → Express server on port 5000
- Express serves Flutter web build from `golden_pearl/build/web/`
- To rebuild Flutter: `cd golden_pearl && flutter build web`
- Images must be copied after build: `cp golden_pearl/assets/images/*.png golden_pearl/build/web/images/`

## Phase 2 (Planned)
- Web admin dashboard for inventory/order management (same backend)
- Payment integration inside the app

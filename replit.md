# Golden Pearl — Luxury Fashion House

## Overview
A bilingual (Arabic RTL + English LTR) luxury fashion e-commerce mobile app built with Flutter, backed by an Express.js + PostgreSQL API server. The brand specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and gift packaging.

## Tech Stack
- **Mobile App**: Flutter 3.22.0 (Dart), targeting iOS, Android, and Web
- **Backend**: Express.js + TypeScript, PostgreSQL with Drizzle ORM
- **Localization**: flutter_localizations + intl + ARB files (Arabic default, English toggle)
- **State Management**: Provider (ChangeNotifier)
- **Auth**: bcrypt password hashing, express-session for session management
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
- `lib/screens/admin/` — AdminDashboard (9 pages: Overview, Products, Orders, Banners, Categories, Promotions, Notifications, Settings, Analytics + bottom nav + drawer), AdminProductsScreen (category tabs), AdminProductFormScreen (create/edit with image upload), AdminOrdersScreen (with item thumbnails), AdminBannersScreen (CRUD + reorder + upload), AdminCategoriesScreen (image upload + visibility + reorder), AdminPromotions (discount code management), AdminNotificationsScreen (send to all users), AdminSettingsScreen, AdminAnalyticsScreen
- `lib/providers/` — LanguageProvider, CartProvider, FavoritesProvider, AuthProvider (login/register/logout/checkAuth)
- `lib/services/api_service.dart` — HTTP client with auth endpoints, admin CRUD, analytics tracking
- `lib/models/` — Product (with stock field), CartItem, Order, AppNotification
- `lib/utils/` — money_formatter.dart, arabic_digits.dart
- `lib/widgets/` — product_card, shimmer_placeholder, category_icons, hero_video_background, luxury_video_player
- `lib/l10n/` — app_ar.arb, app_en.arb (complete bilingual strings)
- `lib/l10n/generated/` — Auto-generated AppLocalizations
- `assets/images/` — Brand photos, `assets/videos/` — Product videos
- `fonts/` — PlayfairDisplay (Regular, SemiBold, Bold)

### Backend (`server/`)
- `server/index.ts` — Express server with CORS, session, serves Flutter web build
- `server/routes.ts` — RESTful API (products, cart, orders, auth, admin, notifications, payments, shipping)
- `server/storage.ts` — PostgreSQL storage layer with full CRUD including auth/settings/analytics
- `server/db.ts` — Drizzle + pg pool setup
- `server/seed.ts` — Seeds products, discount codes, admin user, site settings
- `server/payments.ts` — Payment session management (stub for Moyasar)
- `server/shipping.ts` — Shipping quote and tracking (stub)
- `shared/schema.ts` — Drizzle ORM schema (products, cartItems, orders, discountCodes, notifications, adminUsers, users, siteSettings, pageViews)

## Authentication & Authorization
- **Guest browsing**: Users can browse all products, add to cart, search — no login required
- **Login-on-checkout**: Checkout guard redirects to login screen if not authenticated; on login, guest cart merges into user cart
- **Admin access**: Settings screen shows "Admin Panel" tile only when user role is 'admin'
- **Admin credentials**: email=admin@goldenpearl.com, password=admin123
- **Session-based**: express-session with userId stored in session

## Admin Panel
Accessible from Settings → Admin Panel (only visible to admin users). Navigation: 5-tab bottom nav (Dashboard, Products, Orders, Banners, Categories) + drawer for Promotions, Notifications, Settings, Analytics.
- **Dashboard**: Overview cards (products, orders, visits, sessions), quick action links, Add Product FAB
- **Products**: Category tabs (All/Dresses/Jalabiyas/Kids/Gifts), stock color coding, edit/duplicate/delete actions, stock update dialog
- **Product Form**: Create/edit with multi-image upload (sharp compression), name En/Ar, price, category, description, stock, sizes, colors
- **Orders**: Filtered tabs (All/Delivery/Pickup), product thumbnails in order cards, status update dialog, order detail bottom sheet
- **Banners**: Upload image/video banners, toggle active, drag-to-reorder, delete with confirmation
- **Categories**: Upload category images, toggle visibility, drag-to-reorder (4 default: Dresses, Jalabiyas, Kids, Gifts)
- **Promotions**: Discount code CRUD, percentage/fixed types, expiration dates, min order, usage tracking
- **Notifications**: Compose and send notifications to all users, sent history
- **Hero Text Editor**: Bilingual (AR/EN) hero overlay text editing with full style controls (font family, size, weight, letter spacing, color, shadow, alignment, position preset + fine-tune X/Y offsets), live preview card, draft/publish separation, reset to published state
- **Settings**: Site settings management
- **Analytics**: Total views, unique sessions, top viewed products

## Currency & Pricing
- All monetary values stored as **integer halalas** (1 SAR = 100 halalas)
- Shipping threshold: 15000 halalas (150 SAR), fee: 1500 halalas (15 SAR)

## Features
- **Bilingual**: Arabic RTL (default) ↔ English LTR with persistent language toggle
- **Home**: Dynamic banner carousel (from admin-uploaded banners, fallback to hero video), dynamic hero overlay text (from admin heroOverlay settings, fallback to l10n defaults), dynamic category circles (from admin, fallback to defaults), featured products grid
- **Shop**: Product listing with filters, search, sort
- **Product Detail**: Multi-image + video slider, fullscreen zoom, size/color selectors
- **Cart**: Cart + Wishlist tabs, swipe-to-delete, quantity management
- **Checkout**: Login guard, delivery/pickup toggle, discount codes
- **Orders**: Full status tracking with notifications
- **Admin Panel**: Full Shopify-like CMS (products, orders, banners, categories, promotions, notifications, settings, analytics)
- **Media Upload**: Image compression via sharp (max 1200px, JPEG quality 80), video upload support

## Database Tables
- **users**: id, email (unique), passwordHash, name, phone, role (default 'user'), createdAt
- **products**: id, nameEn/Ar, descriptionEn/Ar, price, originalPrice, category, images[], videoUrl, sizes[], colors[], fabricEn/Ar, inStock, featured, badge, rating, reviewCount, stock (default 100), orderIndex (default 0)
- **banners**: id, type ("image"|"video"), url (text), active (boolean default true), sortOrder (integer default 0)
- **categories**: id, slug (text unique), nameEn (text), nameAr (text), imageUrl (text nullable), visible (boolean default true), sortOrder (integer default 0)
- **cart_items**: id, sessionId, userId (nullable), productId, quantity, size, color
- **orders**: id, sessionId, userId (nullable), items (JSONB), subtotal/shipping/discount/total, status, deliveryMethod, customer info, notes
- **discount_codes**: id, code, type, value, minOrder, maxUses, usedCount, active, expiresAt
- **notifications**: id, userId, orderId, title, message, read, createdAt
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
- `GET /api/banners` — Active banners (sorted by sortOrder)
- `GET /api/categories` — Visible categories (sorted by sortOrder)
- `GET /api/settings/:key` — Public setting value
- `POST /api/analytics/pageview` — Record page view

### Auth
- `POST /api/auth/register` — Create account
- `POST /api/auth/login` — Login
- `POST /api/auth/logout` — Logout
- `GET /api/auth/me` — Current user
- `POST /api/auth/merge` — Merge guest cart into user cart

### Admin (requires admin role)
- `POST /api/admin/upload` — Upload media (multer + sharp compression)
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

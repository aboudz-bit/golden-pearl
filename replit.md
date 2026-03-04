# Golden Pearl — Luxury Fashion House

## Overview
Golden Pearl is a bilingual (Arabic RTL + English LTR) luxury fashion e-commerce application built with Flutter (iOS/Android/Web), supported by an Express.js + TypeScript backend and PostgreSQL database. The platform specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and gift packaging, offering a premium online shopping experience.

## User Preferences
Clear, concise summaries. Prioritize modularity and reusability. Consistent luxury soft neutral design aesthetic. Iterative development with consultation before major changes.

## Architecture

### Backend — `server/`
Clean architecture with separation of concerns:

```
server/
├── index.ts                 # Express app setup, middleware, static serving
├── routes.ts                # Thin route registration (~100 lines)
├── storage.ts               # Database access layer (Drizzle ORM)
├── db.ts                    # Database connection
├── seed.ts                  # Database seeding
├── vite.ts                  # Vite dev server integration
├── payments.ts              # Payment gateway stubs (Moyasar)
├── shipping.ts              # Shipping provider stubs (Aramex/SMSA)
├── controllers/
│   ├── auth.controller.ts       # Register, login, logout, me, merge cart
│   ├── products.controller.ts   # Product CRUD + reorder
│   ├── cart.controller.ts       # Cart CRUD
│   ├── orders.controller.ts     # Order create, list, admin status updates
│   ├── admin.controller.ts      # Banners, categories, discounts, notifications (send/list/delete), settings, analytics
│   ├── staff.controller.ts      # Staff user CRUD + permission management (admin-only)
│   ├── customers.controller.ts  # Customer list, detail, export (XLSX), cart notifications
│   ├── uploads.controller.ts    # Unified file upload (images+videos) with sharp compression
│   ├── public.controller.ts     # Public endpoints: banners, categories, notifications, settings, pageviews
│   ├── payments.controller.ts   # Payment session stubs
│   └── shipping.controller.ts   # Shipping quote/tracking stubs
├── middleware/
│   ├── auth.ts              # isAdmin, isStaffOrAdmin, requirePermission middleware
│   ├── asyncHandler.ts      # Async error wrapper for route handlers
│   ├── errorHandler.ts      # Centralized error handler (AppError + generic)
│   └── cache.ts             # In-memory TTL cache (banners, categories)
└── utils/
    ├── AppError.ts          # Typed error class (badRequest, notFound, unauthorized, conflict, forbidden)
    └── response.ts          # Standardized response helpers
```

### Frontend — `golden_pearl/lib/`
```
lib/
├── main.dart                # App entry, theme, routing, providers
├── data/locations.dart      # Store location data
├── l10n/                    # Localization (app_en.arb, app_ar.arb, generated/)
├── models/
│   ├── cart_item.dart, order.dart, product.dart, store.dart
├── providers/
│   ├── auth_provider.dart, cart_provider.dart, favorites_provider.dart, language_provider.dart
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard.dart        # Admin shell with drawer navigation
│   │   ├── admin_products.dart         # Product list + search
│   │   ├── admin_product_form.dart     # Product create/edit form
│   │   ├── admin_orders.dart           # Order management
│   │   ├── admin_hero_page.dart        # Banners/hero management (unified)
│   │   ├── admin_categories.dart       # Category management
│   │   ├── admin_promotions.dart       # Discount code management
│   │   ├── admin_notifications.dart    # Broadcast notification sending + grouped list + delete
│   │   ├── admin_customers.dart        # Customer list with search/filter/export
│   │   ├── admin_customer_detail.dart  # Customer detail + cart notification
│   │   └── admin_staff.dart            # Staff user management + permission editor (admin-only)
│   ├── home_screen.dart, shop_screen.dart, product_detail_screen.dart
│   ├── cart_screen.dart, checkout_screen.dart, order_confirmation_screen.dart
│   ├── login_screen.dart, orders_screen.dart, notifications_screen.dart
│   ├── category_screen.dart, settings_screen.dart
├── services/
│   └── api_service.dart     # HTTP client (cookie-based auth, all API calls)
├── utils/
│   ├── money_formatter.dart # SAR formatting (halalas → display)
│   └── arabic_digits.dart   # Arabic-Indic digit conversion
└── widgets/
    ├── product_card.dart, category_icons.dart
    ├── hero_video_background.dart, luxury_video_player.dart
    └── shimmer_placeholder.dart
```

### Shared — `shared/schema.ts`
Drizzle ORM schema definitions with Zod insert schemas and TypeScript types for all 10 tables: users, products, cartItems, orders, discountCodes, notifications, adminUsers, siteSettings, pageViews, banners, categories.

## Key Technical Details

| Aspect | Detail |
|---|---|
| **Currency** | Integer halalas (1 SAR = 100 halalas). Use `MoneyFormatter.format(amount, lang)` |
| **Color palette** | Gold #B89B5E, Cream BG #F4F4F4, Card BG #FFFFFF, Charcoal #1C1C1C |
| **Admin credentials** | admin@goldenpearl.com / admin123 |
| **Staff test account** | sara@goldenpearl.com / staff123 |
| **User roles** | admin (full access), staff (permission-gated), user (customer) |
| **L10n** | `synthetic-package: false`, generated at `lib/l10n/generated/` |
| **Build command** | `cd golden_pearl && flutter gen-l10n && flutter build web --release` then `cp -r assets/images assets/videos build/web/` |
| **Port issue** | `fuser -k 5000/tcp` before restart if port stuck |
| **Error format** | `{success: false, message: string, code: string}` |

## Staff & Permissions (RBAC)
- **Roles**: `admin` (full implicit access), `staff` (permission-gated), `user` (customer)
- **Users table**: `isActive` (boolean), `permissions` (JSONB) fields added
- **Middleware chain**: `isStaffOrAdmin` → `requirePermission("module.action")`
- **Admin always passes** all permission checks; staff must have explicit grants
- **Modules**: dashboard, orders, products, categories, banners, customers, notifications, discountCodes
- **Staff management**: Admin-only screen with create/edit/permissions/disable
- **Frontend**: Admin dashboard shows only permitted modules in drawer + bottom nav
- **Disabled accounts**: Login returns 403 "Account disabled"
- **Staff endpoints**: `POST/GET /api/admin/staff`, `PATCH /api/admin/staff/:id`, `PATCH /api/admin/staff/:id/permissions`, `DELETE /api/admin/staff/:id`

## Security
- **Helmet**: Secure HTTP headers (HSTS, X-Content-Type-Options, X-Frame-Options)
- **Rate limiting**: Auth 10/min, Upload 30/min, General API 200/min
- **Session**: httpOnly, sameSite: lax, secure in production
- **Uploads**: UUID filenames, dual MIME+extension validation, path traversal protection, 50MB limit, sharp image compression
- **Error handling**: Centralized via AppError — no stack traces leaked

## Performance
- **DB indexes**: products(category, orderIndex), orders(createdAt, userId), banners(active, sortOrder), categories(sortOrder)
- **Caching**: In-memory TTL cache (60s) for banners and categories, invalidated on admin writes
- **Compression**: gzip/brotli via `compression` middleware
- **Static assets**: 7-day cache headers for images/videos/uploads

## External Dependencies
- PostgreSQL, Drizzle ORM, Express.js (TypeScript), Flutter (Dart)
- bcrypt, express-session, memorystore, helmet, express-rate-limit, compression
- multer, sharp, exceljs (XLSX export)
- flutter_localizations, intl, provider, http, video_player
- Moyasar (payment, pending credentials), Aramex/SMSA (shipping, pending)

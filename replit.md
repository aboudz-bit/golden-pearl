# Golden Pearl — Luxury Fashion House

## Overview
Golden Pearl is a bilingual (Arabic RTL + English LTR) luxury fashion e-commerce mobile application built with Flutter, supported by an Express.js and PostgreSQL API server. The platform specializes in handcrafted embroidered dresses, jalabiyas, kids' collections, and exquisite gift packaging, aiming to offer a premium online shopping experience for high-end fashion.

## User Preferences
I prefer clear, concise summaries and explanations. When making changes, prioritize modularity and reusability. For UI components, favor a consistent luxury soft neutral design aesthetic. I value iterative development and would like to be consulted before any major architectural changes or significant feature implementations.

## System Architecture
The application features a Flutter-based mobile app targeting iOS, Android, and Web, with an Express.js backend using TypeScript and PostgreSQL with Drizzle ORM.

**UI/UX Design:**
- **Theme**: Custom luxury soft neutral theme with a focus on elegance.
- **Typography**: PlayfairDisplay for headings, Material Design 3 for overall styling.
- **Color Palette**: Primary Gold (#B89B5E), Dark Gold (#9C7F42), soft neutral Background (#F4F4F4), Charcoal Text (#1C1C1C).
- **Components**: Product cards with 4:5 aspect ratio and full-bleed images, circular category highlights with subtle gold accents, consistent motion (fade + vertical lift, button press scale).
- **Localization**: Full bilingual support (Arabic default RTL, English LTR toggle) with ARB files, including Arabic-Indic digits and specific currency formatting.

**Technical Implementations:**
- **State Management**: Provider (ChangeNotifier) for client-side state.
- **Authentication**: bcrypt for password hashing, express-session for session management. Guest browsing is allowed, with a login-on-checkout mechanism that merges guest carts.
- **Security**: Helmet for secure headers, express-rate-limit for API protection, compression middleware.
- **Admin Panel**: A comprehensive, Shopify-like CMS for managing products, orders, banners, categories, promotions, notifications, customers, and site settings. Features include multi-image upload with compression, dynamic text overlays for banners with live preview, and customer data export.
- **Currency Handling**: All monetary values are stored as integer halalas (1 SAR = 100 halalas) to prevent floating-point inaccuracies.
- **Performance**: Utilizes DB indexing, in-memory caching for frequently accessed public data (banners, categories), gzip/brotli compression, and static asset caching.
- **Media**: Unified upload endpoint for images (with `sharp` compression) and videos, supporting range requests for video streaming.

**System Design Choices:**
- **Clean Architecture**: The backend is structured with clear separation of concerns, utilizing controllers for business logic, a storage layer for database interactions, and middleware for cross-cutting concerns.
- **Error Handling**: Centralized error handling using a custom `AppError` class to provide consistent and informative error responses without leaking sensitive information.
- **Modularity**: Services and utilities are designed for reusability, with clear abstractions for payment and shipping gateways to facilitate future integrations.

## External Dependencies
- **PostgreSQL**: Primary database for all application data.
- **Drizzle ORM**: Used for interacting with the PostgreSQL database from the Express.js backend.
- **Flutter (Dart)**: Framework for the mobile and web client applications.
- **Express.js (TypeScript)**: Backend web application framework.
- **`flutter_localizations` + `intl` + ARB files**: For internationalization and localization within the Flutter app.
- **`bcrypt`**: For secure password hashing.
- **`express-session`**: For session management in the backend.
- **`helmet`**: For securing HTTP headers in the Express.js application.
- **`express-rate-limit`**: For applying rate limiting to API endpoints.
- **`compression`**: Middleware for response compression.
- **`multer`**: For handling multipart/form-data, primarily for file uploads.
- **`sharp`**: For image processing and compression on the backend.
- **Moyasar**: Payment gateway (integration pending credentials).
- **Aramex/SMSA**: Shipping providers (integration pending).
- **Firebase Cloud Messaging**: For push notifications (integration pending credentials).
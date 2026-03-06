import { db } from "./db";
import crypto from "crypto";
import {
  companies, users, memberships, products, productAssets,
  experiences, publishRecords, analyticsEvents,
} from "@shared/schema";

function hashPassword(pw: string): string {
  return crypto.createHash("sha256").update(pw).digest("hex");
}

const DEMO_COMPANIES = [
  {
    name: "Golden Pearl",
    slug: "golden-pearl",
    logo: "/images/logo.png",
    brandPrimaryColor: "#c9a84c",
    brandSecondaryColor: "#1a1a2e",
    domain: "goldenpearl.com",
    defaultArMode: "surface",
  },
  {
    name: "LuxeHome Interiors",
    slug: "luxehome",
    brandPrimaryColor: "#2563eb",
    brandSecondaryColor: "#1e40af",
    domain: "luxehome.co",
    defaultArMode: "surface",
  },
  {
    name: "TechGear Pro",
    slug: "techgear",
    brandPrimaryColor: "#059669",
    brandSecondaryColor: "#047857",
    domain: "techgear.pro",
    defaultArMode: "surface",
  },
];

const DEMO_USERS = [
  {
    email: "admin@arcore7.com",
    passwordHash: hashPassword("admin123"),
    firstName: "Super",
    lastName: "Admin",
    role: "super_admin",
  },
  {
    email: "sarah@goldenpearl.com",
    passwordHash: hashPassword("demo123"),
    firstName: "Sarah",
    lastName: "Al-Rashid",
    role: "company_admin",
  },
  {
    email: "omar@goldenpearl.com",
    passwordHash: hashPassword("demo123"),
    firstName: "Omar",
    lastName: "Hassan",
    role: "content_manager",
  },
  {
    email: "james@luxehome.co",
    passwordHash: hashPassword("demo123"),
    firstName: "James",
    lastName: "Mitchell",
    role: "company_admin",
  },
  {
    email: "alex@techgear.pro",
    passwordHash: hashPassword("demo123"),
    firstName: "Alex",
    lastName: "Chen",
    role: "company_admin",
  },
];

export async function seedDatabase() {
  try {
    const existingCompanies = await db.select().from(companies);
    if (existingCompanies.length > 0) {
      console.log(`Database already seeded (${existingCompanies.length} companies). Skipping.`);
      return;
    }

    console.log("Seeding AR-core-7 database...");

    // Companies
    const createdCompanies = await db.insert(companies).values(DEMO_COMPANIES).returning();
    console.log(`  Created ${createdCompanies.length} companies`);

    // Users
    const createdUsers = await db.insert(users).values(DEMO_USERS).returning();
    console.log(`  Created ${createdUsers.length} users`);

    // Memberships
    const membershipData = [
      // Super admin gets access to all companies
      { userId: createdUsers[0].id, companyId: createdCompanies[0].id, role: "company_admin" },
      { userId: createdUsers[0].id, companyId: createdCompanies[1].id, role: "company_admin" },
      { userId: createdUsers[0].id, companyId: createdCompanies[2].id, role: "company_admin" },
      // Sarah & Omar -> Golden Pearl
      { userId: createdUsers[1].id, companyId: createdCompanies[0].id, role: "company_admin" },
      { userId: createdUsers[2].id, companyId: createdCompanies[0].id, role: "content_manager" },
      // James -> LuxeHome
      { userId: createdUsers[3].id, companyId: createdCompanies[1].id, role: "company_admin" },
      // Alex -> TechGear
      { userId: createdUsers[4].id, companyId: createdCompanies[2].id, role: "company_admin" },
    ];
    await db.insert(memberships).values(membershipData);
    console.log(`  Created ${membershipData.length} memberships`);

    // Products - Golden Pearl
    const gpProducts = [
      {
        companyId: createdCompanies[0].id,
        title: "Royal Maroon Embroidered Gown",
        sku: "GP-GOWN-001",
        category: "Fashion",
        description: "A breathtaking evening gown in deep maroon with intricate gold thread embroidery. Handcrafted by skilled artisans, blending traditional luxury with modern elegance.",
        brand: "Golden Pearl",
        thumbnail: "/images/hero3.png",
        status: "active",
        tags: ["evening", "embroidered", "luxury"],
        scalePreset: 1.0,
        anchorType: "floor",
        publishStatus: "published",
        assetCompletenessScore: 85,
        slug: "royal-maroon-gown",
      },
      {
        companyId: createdCompanies[0].id,
        title: "Sage Green Ensemble",
        sku: "GP-ENS-002",
        category: "Fashion",
        description: "A sophisticated sage green ensemble featuring intricate floral embroidery with gold accents. The relaxed silhouette with layered skirt creates an effortlessly elegant look.",
        brand: "Golden Pearl",
        thumbnail: "/images/hero1.png",
        status: "active",
        tags: ["ensemble", "floral", "elegant"],
        scalePreset: 1.0,
        anchorType: "floor",
        publishStatus: "published",
        assetCompletenessScore: 90,
        slug: "sage-green-ensemble",
      },
      {
        companyId: createdCompanies[0].id,
        title: "Blue Embroidered Tunic",
        sku: "GP-TUN-003",
        category: "Fashion",
        description: "A stunning sky blue tunic with elaborate floral embroidery featuring birds, butterflies and blossom motifs.",
        brand: "Golden Pearl",
        thumbnail: "/images/hero2.png",
        status: "active",
        tags: ["tunic", "embroidered", "floral"],
        scalePreset: 0.8,
        anchorType: "floor",
        publishStatus: "ready",
        assetCompletenessScore: 70,
        slug: "blue-embroidered-tunic",
      },
    ];

    // Products - LuxeHome
    const lhProducts = [
      {
        companyId: createdCompanies[1].id,
        title: "Artisan Coffee Table",
        sku: "LH-TBL-001",
        category: "Furniture",
        description: "Hand-crafted walnut coffee table with brass inlay details. Perfect for modern living spaces.",
        brand: "LuxeHome",
        status: "active",
        tags: ["furniture", "table", "walnut"],
        dimensionsWidth: 120,
        dimensionsHeight: 45,
        dimensionsDepth: 60,
        dimensionsUnit: "cm",
        scalePreset: 0.5,
        anchorType: "floor",
        publishStatus: "published",
        assetCompletenessScore: 95,
        slug: "artisan-coffee-table",
      },
      {
        companyId: createdCompanies[1].id,
        title: "Milano Lounge Chair",
        sku: "LH-CHR-002",
        category: "Furniture",
        description: "Italian-designed lounge chair with premium leather upholstery and solid oak frame.",
        brand: "LuxeHome",
        status: "active",
        tags: ["furniture", "chair", "leather"],
        dimensionsWidth: 75,
        dimensionsHeight: 90,
        dimensionsDepth: 80,
        dimensionsUnit: "cm",
        scalePreset: 0.6,
        anchorType: "floor",
        publishStatus: "ready",
        assetCompletenessScore: 80,
        slug: "milano-lounge-chair",
      },
    ];

    // Products - TechGear
    const tgProducts = [
      {
        companyId: createdCompanies[2].id,
        title: "ProVision VR Headset",
        sku: "TG-VR-001",
        category: "Electronics",
        description: "Next-generation VR headset with 4K displays per eye, inside-out tracking, and lightweight ergonomic design.",
        brand: "TechGear",
        status: "active",
        tags: ["vr", "headset", "electronics"],
        dimensionsWidth: 18,
        dimensionsHeight: 10,
        dimensionsDepth: 20,
        dimensionsUnit: "cm",
        scalePreset: 2.0,
        anchorType: "tabletop",
        publishStatus: "published",
        assetCompletenessScore: 100,
        slug: "provision-vr-headset",
      },
      {
        companyId: createdCompanies[2].id,
        title: "AirDock Wireless Charger",
        sku: "TG-CHG-002",
        category: "Accessories",
        description: "Premium wireless charging dock with magnetic alignment, fast-charge support, and ambient LED status ring.",
        brand: "TechGear",
        status: "active",
        tags: ["charger", "wireless", "accessories"],
        scalePreset: 3.0,
        anchorType: "tabletop",
        publishStatus: "draft",
        assetCompletenessScore: 60,
        slug: "airdock-wireless-charger",
      },
    ];

    const allProducts = [...gpProducts, ...lhProducts, ...tgProducts];
    const createdProducts = await db.insert(products).values(allProducts).returning();
    console.log(`  Created ${createdProducts.length} products`);

    // Assets for products (using sample model URLs)
    const assetData = createdProducts.flatMap((p) => {
      const assets = [
        {
          productId: p.id,
          companyId: p.companyId,
          assetType: "poster",
          fileName: "poster.png",
          filePath: p.thumbnail || "/images/logo.png",
          fileSize: 250000,
          mimeType: "image/png",
          isValid: true,
          sortOrder: 0,
        },
      ];
      // Add GLB asset reference for demo
      assets.push({
        productId: p.id,
        companyId: p.companyId,
        assetType: "glb",
        fileName: "model.glb",
        filePath: "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
        fileSize: 1500000,
        mimeType: "model/gltf-binary",
        isValid: true,
        sortOrder: 1,
      });
      return assets;
    });
    await db.insert(productAssets).values(assetData);
    console.log(`  Created ${assetData.length} product assets`);

    // Experiences
    const experienceData = [
      // Golden Pearl experiences
      {
        companyId: createdCompanies[0].id,
        productId: createdProducts[0].id,
        name: "Royal Gown 3D Viewer",
        slug: "gp-royal-gown-viewer",
        experienceType: "product_viewer",
        status: "published",
        scale: 1.0,
        lightingPreset: "studio",
        backgroundMode: "gradient",
        autoRotate: true,
        ctaText: "Shop Now",
        ctaLink: "https://goldenpearl.com/shop",
        analyticsEnabled: true,
      },
      {
        companyId: createdCompanies[0].id,
        productId: createdProducts[0].id,
        name: "Royal Gown Surface AR",
        slug: "gp-royal-gown-ar",
        experienceType: "surface_ar",
        status: "published",
        scale: 1.0,
        lightingPreset: "outdoor",
        backgroundMode: "transparent",
        autoRotate: false,
        ctaText: "View in Your Space",
        analyticsEnabled: true,
      },
      {
        companyId: createdCompanies[0].id,
        productId: createdProducts[1].id,
        name: "Sage Ensemble Image Target",
        slug: "gp-sage-image-target",
        experienceType: "image_target",
        status: "ready",
        scale: 0.8,
        lightingPreset: "soft",
        backgroundMode: "transparent",
        analyticsEnabled: true,
        targetImagePath: "/images/hero1.png",
      },
      // LuxeHome experiences
      {
        companyId: createdCompanies[1].id,
        productId: createdProducts[3].id,
        name: "Coffee Table AR Preview",
        slug: "lh-coffee-table-ar",
        experienceType: "surface_ar",
        status: "published",
        scale: 0.5,
        lightingPreset: "studio",
        backgroundMode: "transparent",
        ctaText: "Order Now",
        ctaLink: "https://luxehome.co/products/coffee-table",
        analyticsEnabled: true,
      },
      {
        companyId: createdCompanies[1].id,
        productId: createdProducts[3].id,
        name: "Coffee Table 3D Viewer",
        slug: "lh-coffee-table-viewer",
        experienceType: "product_viewer",
        status: "published",
        scale: 0.5,
        lightingPreset: "studio",
        backgroundMode: "white",
        autoRotate: true,
        analyticsEnabled: true,
      },
      // TechGear experiences
      {
        companyId: createdCompanies[2].id,
        productId: createdProducts[5].id,
        name: "VR Headset 360° View",
        slug: "tg-vr-headset-viewer",
        experienceType: "product_viewer",
        status: "published",
        scale: 2.0,
        lightingPreset: "dramatic",
        backgroundMode: "dark",
        autoRotate: true,
        ctaText: "Pre-Order",
        ctaLink: "https://techgear.pro/vr-headset",
        analyticsEnabled: true,
      },
      {
        companyId: createdCompanies[2].id,
        productId: createdProducts[5].id,
        name: "VR Headset QR Launch",
        slug: "tg-vr-headset-qr",
        experienceType: "qr_launch",
        status: "published",
        scale: 2.0,
        lightingPreset: "studio",
        backgroundMode: "transparent",
        analyticsEnabled: true,
      },
    ];

    const createdExperiences = await db.insert(experiences).values(experienceData).returning();
    console.log(`  Created ${createdExperiences.length} experiences`);

    // Publish records for published experiences
    const publishedExps = createdExperiences.filter(e => e.status === "published");
    const publishData = publishedExps.map(e => ({
      experienceId: e.id,
      companyId: e.companyId,
      publishedById: createdUsers[0].id,
      publicUrl: `/ar/${e.slug}`,
      qrTargetUrl: `/qr/${e.slug}`,
      embedSnippet: `<iframe src="/ar/${e.slug}?embed=1" width="100%" height="500" frameborder="0" allow="camera;xr-spatial-tracking"></iframe>`,
      isLive: true,
    }));
    if (publishData.length > 0) {
      await db.insert(publishRecords).values(publishData);
      console.log(`  Created ${publishData.length} publish records`);
    }

    // Analytics events (sample data for the last 30 days)
    const analyticsData: any[] = [];
    const eventTypes = ["page_view", "viewer_open", "ar_launch", "camera_granted", "tracking_session"];
    const devices = ["mobile", "desktop", "tablet"];
    const browsers = ["Safari", "Chrome", "Firefox"];

    for (let dayOffset = 0; dayOffset < 30; dayOffset++) {
      const date = new Date();
      date.setDate(date.getDate() - dayOffset);

      for (const company of createdCompanies) {
        const eventsPerDay = Math.floor(Math.random() * 15) + 5;
        for (let i = 0; i < eventsPerDay; i++) {
          const eventType = eventTypes[Math.floor(Math.random() * eventTypes.length)];
          const exp = createdExperiences.find(e => e.companyId === company.id);
          const prod = createdProducts.find(p => p.companyId === company.id);

          analyticsData.push({
            companyId: company.id,
            experienceId: exp?.id || null,
            productId: prod?.id || null,
            eventType,
            sessionId: `sess-${Math.random().toString(36).slice(2, 10)}`,
            deviceType: devices[Math.floor(Math.random() * devices.length)],
            browser: browsers[Math.floor(Math.random() * browsers.length)],
            duration: eventType === "tracking_session" ? Math.floor(Math.random() * 120) + 10 : null,
            createdAt: date,
          });
        }
      }
    }

    // Insert in batches
    for (let i = 0; i < analyticsData.length; i += 100) {
      const batch = analyticsData.slice(i, i + 100);
      await db.insert(analyticsEvents).values(batch);
    }
    console.log(`  Created ${analyticsData.length} analytics events`);

    console.log("AR-core-7 database seeded successfully!");
    console.log("\n  Login credentials:");
    console.log("  Super Admin: admin@arcore7.com / admin123");
    console.log("  Company Admin (Golden Pearl): sarah@goldenpearl.com / demo123");
    console.log("  Content Manager: omar@goldenpearl.com / demo123");
    console.log("  Company Admin (LuxeHome): james@luxehome.co / demo123");
    console.log("  Company Admin (TechGear): alex@techgear.pro / demo123\n");

  } catch (error) {
    console.error("Seed error:", error);
  }
}

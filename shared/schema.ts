import { pgTable, text, varchar, integer, boolean, real, timestamp, serial, jsonb, uniqueIndex, index } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";
import { relations } from "drizzle-orm";

// ============================================================
// AR-core-7: Multi-tenant B2B AR Platform Schema
// ============================================================

// --- Companies ---
export const companies = pgTable("companies", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  slug: text("slug").notNull().unique(),
  logo: text("logo"),
  brandPrimaryColor: text("brand_primary_color").default("#6366f1"),
  brandSecondaryColor: text("brand_secondary_color").default("#8b5cf6"),
  domain: text("domain"),
  defaultArMode: text("default_ar_mode").default("surface"),
  maxUploadSizeMb: integer("max_upload_size_mb").default(50),
  allowedFileTypes: text("allowed_file_types").array().default(["glb", "gltf", "usdz", "png", "jpg", "jpeg", "webp"]),
  settings: jsonb("settings").default({}),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// --- Users ---
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  firstName: text("first_name").notNull(),
  lastName: text("last_name").notNull(),
  avatar: text("avatar"),
  role: text("role").notNull().default("viewer"), // super_admin, company_admin, content_manager, viewer
  isActive: boolean("is_active").notNull().default(true),
  lastLoginAt: timestamp("last_login_at"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// --- Memberships (User <-> Company with role) ---
export const memberships = pgTable("memberships", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  companyId: integer("company_id").notNull().references(() => companies.id),
  role: text("role").notNull().default("viewer"), // company_admin, content_manager, viewer
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => [
  uniqueIndex("membership_unique").on(table.userId, table.companyId),
]);

// --- Products ---
export const products = pgTable("products", {
  id: serial("id").primaryKey(),
  companyId: integer("company_id").notNull().references(() => companies.id),
  title: text("title").notNull(),
  sku: text("sku"),
  category: text("category"),
  description: text("description"),
  brand: text("brand"),
  thumbnail: text("thumbnail"),
  status: text("status").notNull().default("draft"), // draft, active, archived
  tags: text("tags").array().default([]),
  dimensionsWidth: real("dimensions_width"),
  dimensionsHeight: real("dimensions_height"),
  dimensionsDepth: real("dimensions_depth"),
  dimensionsUnit: text("dimensions_unit").default("cm"),
  scalePreset: real("scale_preset").default(1.0),
  anchorType: text("anchor_type").default("floor"), // floor, wall, tabletop, face
  defaultSceneSettings: jsonb("default_scene_settings").default({}),
  publishStatus: text("publish_status").notNull().default("draft"), // draft, ready, published, archived
  assetCompletenessScore: integer("asset_completeness_score").default(0),
  slug: text("slug").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
}, (table) => [
  index("product_company_idx").on(table.companyId),
  uniqueIndex("product_slug_company").on(table.companyId, table.slug),
]);

// --- Product Assets ---
export const productAssets = pgTable("product_assets", {
  id: serial("id").primaryKey(),
  productId: integer("product_id").notNull().references(() => products.id),
  companyId: integer("company_id").notNull().references(() => companies.id),
  assetType: text("asset_type").notNull(), // image, glb, gltf, usdz, poster, target_image, face_effect, metadata
  fileName: text("file_name").notNull(),
  filePath: text("file_path").notNull(),
  fileSize: integer("file_size"),
  mimeType: text("mime_type"),
  isValid: boolean("is_valid").default(true),
  validationErrors: text("validation_errors").array().default([]),
  optimizationStatus: text("optimization_status").default("pending"), // pending, processing, optimized, failed
  metadata: jsonb("metadata").default({}),
  sortOrder: integer("sort_order").default(0),
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => [
  index("asset_product_idx").on(table.productId),
]);

// --- Experiences ---
export const experiences = pgTable("experiences", {
  id: serial("id").primaryKey(),
  companyId: integer("company_id").notNull().references(() => companies.id),
  productId: integer("product_id").references(() => products.id),
  name: text("name").notNull(),
  slug: text("slug").notNull(),
  experienceType: text("experience_type").notNull(), // product_viewer, surface_ar, image_target, qr_launch, embed_viewer
  status: text("status").notNull().default("draft"), // draft, ready, published, archived
  // Scene config
  scale: real("scale").default(1.0),
  rotationX: real("rotation_x").default(0),
  rotationY: real("rotation_y").default(0),
  rotationZ: real("rotation_z").default(0),
  positionX: real("position_x").default(0),
  positionY: real("position_y").default(0),
  positionZ: real("position_z").default(0),
  lightingPreset: text("lighting_preset").default("studio"), // studio, outdoor, soft, dramatic, neutral
  backgroundMode: text("background_mode").default("transparent"), // transparent, white, dark, gradient, custom
  backgroundColor: text("background_color"),
  autoRotate: boolean("auto_rotate").default(true),
  // CTA
  ctaText: text("cta_text"),
  ctaLink: text("cta_link"),
  // Target image for image_target type
  targetImagePath: text("target_image_path"),
  targetMindFile: text("target_mind_file"),
  // Analytics
  analyticsEnabled: boolean("analytics_enabled").default(true),
  // Embed
  embedAllowedDomains: text("embed_allowed_domains").array().default([]),
  sceneConfig: jsonb("scene_config").default({}),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
}, (table) => [
  index("experience_company_idx").on(table.companyId),
  uniqueIndex("experience_slug_unique").on(table.slug),
]);

// --- Publish Records ---
export const publishRecords = pgTable("publish_records", {
  id: serial("id").primaryKey(),
  experienceId: integer("experience_id").notNull().references(() => experiences.id),
  companyId: integer("company_id").notNull().references(() => companies.id),
  publishedById: integer("published_by_id").references(() => users.id),
  publicUrl: text("public_url"),
  embedSnippet: text("embed_snippet"),
  qrTargetUrl: text("qr_target_url"),
  whitelabelRoute: text("whitelabel_route"),
  version: integer("version").default(1),
  isLive: boolean("is_live").notNull().default(true),
  publishedAt: timestamp("published_at").defaultNow(),
  unpublishedAt: timestamp("unpublished_at"),
});

// --- Analytics Events ---
export const analyticsEvents = pgTable("analytics_events", {
  id: serial("id").primaryKey(),
  companyId: integer("company_id").notNull().references(() => companies.id),
  experienceId: integer("experience_id").references(() => experiences.id),
  productId: integer("product_id").references(() => products.id),
  eventType: text("event_type").notNull(), // page_view, viewer_open, ar_launch, camera_granted, tracking_session, session_duration
  sessionId: text("session_id"),
  userAgent: text("user_agent"),
  deviceType: text("device_type"), // mobile, tablet, desktop
  browser: text("browser"),
  duration: integer("duration"), // in seconds for session_duration
  metadata: jsonb("metadata").default({}),
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => [
  index("analytics_company_idx").on(table.companyId),
  index("analytics_experience_idx").on(table.experienceId),
  index("analytics_created_idx").on(table.createdAt),
]);

// --- Settings ---
export const settings = pgTable("settings", {
  id: serial("id").primaryKey(),
  companyId: integer("company_id").references(() => companies.id),
  key: text("key").notNull(),
  value: jsonb("value").notNull(),
  category: text("category").default("general"), // general, branding, viewer, ar, upload, analytics
  updatedAt: timestamp("updated_at").defaultNow(),
}, (table) => [
  uniqueIndex("setting_company_key").on(table.companyId, table.key),
]);

// --- Audit Log ---
export const auditLogs = pgTable("audit_logs", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").references(() => users.id),
  companyId: integer("company_id").references(() => companies.id),
  action: text("action").notNull(), // create, update, delete, publish, unpublish, login, logout
  entityType: text("entity_type").notNull(), // company, user, product, asset, experience, setting
  entityId: integer("entity_id"),
  changes: jsonb("changes").default({}),
  ipAddress: text("ip_address"),
  createdAt: timestamp("created_at").defaultNow(),
}, (table) => [
  index("audit_company_idx").on(table.companyId),
  index("audit_created_idx").on(table.createdAt),
]);

// ============================================================
// Relations
// ============================================================

export const companiesRelations = relations(companies, ({ many }) => ({
  memberships: many(memberships),
  products: many(products),
  experiences: many(experiences),
  analyticsEvents: many(analyticsEvents),
}));

export const usersRelations = relations(users, ({ many }) => ({
  memberships: many(memberships),
}));

export const membershipsRelations = relations(memberships, ({ one }) => ({
  user: one(users, { fields: [memberships.userId], references: [users.id] }),
  company: one(companies, { fields: [memberships.companyId], references: [companies.id] }),
}));

export const productsRelations = relations(products, ({ one, many }) => ({
  company: one(companies, { fields: [products.companyId], references: [companies.id] }),
  assets: many(productAssets),
  experiences: many(experiences),
}));

export const productAssetsRelations = relations(productAssets, ({ one }) => ({
  product: one(products, { fields: [productAssets.productId], references: [products.id] }),
  company: one(companies, { fields: [productAssets.companyId], references: [companies.id] }),
}));

export const experiencesRelations = relations(experiences, ({ one }) => ({
  company: one(companies, { fields: [experiences.companyId], references: [companies.id] }),
  product: one(products, { fields: [experiences.productId], references: [products.id] }),
}));

// ============================================================
// Insert Schemas (Zod)
// ============================================================

export const insertCompanySchema = createInsertSchema(companies).omit({ id: true, createdAt: true, updatedAt: true });
export const insertUserSchema = createInsertSchema(users).omit({ id: true, createdAt: true, updatedAt: true, lastLoginAt: true });
export const insertMembershipSchema = createInsertSchema(memberships).omit({ id: true, createdAt: true });
export const insertProductSchema = createInsertSchema(products).omit({ id: true, createdAt: true, updatedAt: true });
export const insertProductAssetSchema = createInsertSchema(productAssets).omit({ id: true, createdAt: true });
export const insertExperienceSchema = createInsertSchema(experiences).omit({ id: true, createdAt: true, updatedAt: true });
export const insertPublishRecordSchema = createInsertSchema(publishRecords).omit({ id: true, publishedAt: true });
export const insertAnalyticsEventSchema = createInsertSchema(analyticsEvents).omit({ id: true, createdAt: true });
export const insertSettingSchema = createInsertSchema(settings).omit({ id: true, updatedAt: true });
export const insertAuditLogSchema = createInsertSchema(auditLogs).omit({ id: true, createdAt: true });

// ============================================================
// Types
// ============================================================

export type Company = typeof companies.$inferSelect;
export type User = typeof users.$inferSelect;
export type Membership = typeof memberships.$inferSelect;
export type Product = typeof products.$inferSelect;
export type ProductAsset = typeof productAssets.$inferSelect;
export type Experience = typeof experiences.$inferSelect;
export type PublishRecord = typeof publishRecords.$inferSelect;
export type AnalyticsEvent = typeof analyticsEvents.$inferSelect;
export type Setting = typeof settings.$inferSelect;
export type AuditLog = typeof auditLogs.$inferSelect;

export type InsertCompany = z.infer<typeof insertCompanySchema>;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type InsertMembership = z.infer<typeof insertMembershipSchema>;
export type InsertProduct = z.infer<typeof insertProductSchema>;
export type InsertProductAsset = z.infer<typeof insertProductAssetSchema>;
export type InsertExperience = z.infer<typeof insertExperienceSchema>;
export type InsertPublishRecord = z.infer<typeof insertPublishRecordSchema>;
export type InsertAnalyticsEvent = z.infer<typeof insertAnalyticsEventSchema>;
export type InsertSetting = z.infer<typeof insertSettingSchema>;
export type InsertAuditLog = z.infer<typeof insertAuditLogSchema>;

// ============================================================
// Shared Types & Enums
// ============================================================

export const UserRoles = ["super_admin", "company_admin", "content_manager", "viewer"] as const;
export type UserRole = typeof UserRoles[number];

export const ExperienceTypes = ["product_viewer", "surface_ar", "image_target", "qr_launch", "embed_viewer"] as const;
export type ExperienceType = typeof ExperienceTypes[number];

export const PublishStatuses = ["draft", "ready", "published", "archived"] as const;
export type PublishStatus = typeof PublishStatuses[number];

export const LightingPresets = ["studio", "outdoor", "soft", "dramatic", "neutral"] as const;
export type LightingPreset = typeof LightingPresets[number];

export const AssetTypes = ["image", "glb", "gltf", "usdz", "poster", "target_image", "face_effect", "metadata"] as const;
export type AssetType = typeof AssetTypes[number];

export const AnchorTypes = ["floor", "wall", "tabletop", "face"] as const;
export type AnchorType = typeof AnchorTypes[number];

export const AnalyticsEventTypes = ["page_view", "viewer_open", "ar_launch", "camera_granted", "tracking_session", "session_duration"] as const;
export type AnalyticsEventType = typeof AnalyticsEventTypes[number];

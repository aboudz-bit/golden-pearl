import { eq, and, desc, count, sql, gte } from "drizzle-orm";
import { db } from "./db";
import {
  companies, users, memberships, products, productAssets,
  experiences, publishRecords, analyticsEvents, settings, auditLogs,
  type InsertCompany, type InsertUser, type InsertMembership, type InsertProduct,
  type InsertProductAsset, type InsertExperience, type InsertPublishRecord,
  type InsertAnalyticsEvent, type InsertSetting, type InsertAuditLog,
} from "@shared/schema";

// ============================================================
// Companies
// ============================================================
export async function getCompanies() {
  return db.select().from(companies).orderBy(desc(companies.createdAt));
}
export async function getCompanyById(id: number) {
  const [c] = await db.select().from(companies).where(eq(companies.id, id));
  return c;
}
export async function getCompanyBySlug(slug: string) {
  const [c] = await db.select().from(companies).where(eq(companies.slug, slug));
  return c;
}
export async function createCompany(data: InsertCompany) {
  const [c] = await db.insert(companies).values(data).returning();
  return c;
}
export async function updateCompany(id: number, data: Partial<InsertCompany>) {
  const [c] = await db.update(companies).set({ ...data, updatedAt: new Date() }).where(eq(companies.id, id)).returning();
  return c;
}
export async function deleteCompany(id: number) {
  await db.delete(companies).where(eq(companies.id, id));
}

// ============================================================
// Users
// ============================================================
export async function getUsers(companyId?: number) {
  if (companyId) {
    const rows = await db.select({ user: users, membership: memberships })
      .from(users)
      .innerJoin(memberships, eq(users.id, memberships.userId))
      .where(eq(memberships.companyId, companyId))
      .orderBy(desc(users.createdAt));
    return rows.map(r => ({ ...r.user, membershipRole: r.membership.role }));
  }
  return db.select().from(users).orderBy(desc(users.createdAt));
}
export async function getUserById(id: number) {
  const [u] = await db.select().from(users).where(eq(users.id, id));
  return u;
}
export async function getUserByEmail(email: string) {
  const [u] = await db.select().from(users).where(eq(users.email, email));
  return u;
}
export async function createUser(data: InsertUser) {
  const [u] = await db.insert(users).values(data).returning();
  return u;
}
export async function updateUser(id: number, data: Partial<InsertUser>) {
  const [u] = await db.update(users).set({ ...data, updatedAt: new Date() }).where(eq(users.id, id)).returning();
  return u;
}

// ============================================================
// Memberships
// ============================================================
export async function getMembershipsByUser(userId: number) {
  return db.select({
    membership: memberships,
    company: companies,
  }).from(memberships)
    .innerJoin(companies, eq(memberships.companyId, companies.id))
    .where(eq(memberships.userId, userId));
}
export async function getMembershipsByCompany(companyId: number) {
  return db.select({
    membership: memberships,
    user: users,
  }).from(memberships)
    .innerJoin(users, eq(memberships.userId, users.id))
    .where(eq(memberships.companyId, companyId));
}
export async function createMembership(data: InsertMembership) {
  const [m] = await db.insert(memberships).values(data).returning();
  return m;
}
export async function deleteMembership(id: number) {
  await db.delete(memberships).where(eq(memberships.id, id));
}

// ============================================================
// Products
// ============================================================
export async function getProducts(companyId?: number) {
  if (companyId) {
    return db.select().from(products).where(eq(products.companyId, companyId)).orderBy(desc(products.createdAt));
  }
  return db.select().from(products).orderBy(desc(products.createdAt));
}
export async function getProductById(id: number) {
  const [p] = await db.select().from(products).where(eq(products.id, id));
  return p;
}
export async function getProductBySlug(companyId: number, slug: string) {
  const [p] = await db.select().from(products).where(and(eq(products.companyId, companyId), eq(products.slug, slug)));
  return p;
}
export async function createProduct(data: InsertProduct) {
  const [p] = await db.insert(products).values(data).returning();
  return p;
}
export async function updateProduct(id: number, data: Partial<InsertProduct>) {
  const [p] = await db.update(products).set({ ...data, updatedAt: new Date() }).where(eq(products.id, id)).returning();
  return p;
}
export async function deleteProduct(id: number) {
  await db.delete(productAssets).where(eq(productAssets.productId, id));
  await db.delete(products).where(eq(products.id, id));
}

// ============================================================
// Product Assets
// ============================================================
export async function getAssetsByProduct(productId: number) {
  return db.select().from(productAssets).where(eq(productAssets.productId, productId)).orderBy(productAssets.sortOrder);
}
export async function getAssetsByCompany(companyId: number) {
  return db.select().from(productAssets).where(eq(productAssets.companyId, companyId)).orderBy(desc(productAssets.createdAt));
}
export async function createAsset(data: InsertProductAsset) {
  const [a] = await db.insert(productAssets).values(data).returning();
  return a;
}
export async function deleteAsset(id: number) {
  await db.delete(productAssets).where(eq(productAssets.id, id));
}

// ============================================================
// Experiences
// ============================================================
export async function getExperiences(companyId?: number) {
  if (companyId) {
    return db.select().from(experiences).where(eq(experiences.companyId, companyId)).orderBy(desc(experiences.createdAt));
  }
  return db.select().from(experiences).orderBy(desc(experiences.createdAt));
}
export async function getExperienceById(id: number) {
  const [e] = await db.select().from(experiences).where(eq(experiences.id, id));
  return e;
}
export async function getExperienceBySlug(slug: string) {
  const [e] = await db.select().from(experiences).where(eq(experiences.slug, slug));
  return e;
}
export async function createExperience(data: InsertExperience) {
  const [e] = await db.insert(experiences).values(data).returning();
  return e;
}
export async function updateExperience(id: number, data: Partial<InsertExperience>) {
  const [e] = await db.update(experiences).set({ ...data, updatedAt: new Date() }).where(eq(experiences.id, id)).returning();
  return e;
}
export async function deleteExperience(id: number) {
  await db.delete(experiences).where(eq(experiences.id, id));
}

// ============================================================
// Publish Records
// ============================================================
export async function getPublishRecords(experienceId: number) {
  return db.select().from(publishRecords).where(eq(publishRecords.experienceId, experienceId)).orderBy(desc(publishRecords.publishedAt));
}
export async function createPublishRecord(data: InsertPublishRecord) {
  const [p] = await db.insert(publishRecords).values(data).returning();
  return p;
}
export async function getActivePublishRecord(experienceId: number) {
  const [p] = await db.select().from(publishRecords)
    .where(and(eq(publishRecords.experienceId, experienceId), eq(publishRecords.isLive, true)))
    .orderBy(desc(publishRecords.publishedAt))
    .limit(1);
  return p;
}

// ============================================================
// Analytics
// ============================================================
export async function createAnalyticsEvent(data: InsertAnalyticsEvent) {
  const [e] = await db.insert(analyticsEvents).values(data).returning();
  return e;
}
export async function getAnalyticsSummary(companyId?: number, days = 30) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const conditions = companyId
    ? and(eq(analyticsEvents.companyId, companyId), gte(analyticsEvents.createdAt, since))
    : gte(analyticsEvents.createdAt, since);

  return db.select({
    eventType: analyticsEvents.eventType,
    count: count(),
  }).from(analyticsEvents)
    .where(conditions)
    .groupBy(analyticsEvents.eventType);
}
export async function getAnalyticsTimeline(companyId?: number, days = 30) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const conditions = companyId
    ? and(eq(analyticsEvents.companyId, companyId), gte(analyticsEvents.createdAt, since))
    : gte(analyticsEvents.createdAt, since);

  return db.select({
    date: sql<string>`DATE(${analyticsEvents.createdAt})`.as("date"),
    eventType: analyticsEvents.eventType,
    count: count(),
  }).from(analyticsEvents)
    .where(conditions)
    .groupBy(sql`DATE(${analyticsEvents.createdAt})`, analyticsEvents.eventType)
    .orderBy(sql`DATE(${analyticsEvents.createdAt})`);
}

// ============================================================
// Settings
// ============================================================
export async function getSettings(companyId?: number | null) {
  if (companyId) {
    return db.select().from(settings).where(eq(settings.companyId, companyId));
  }
  return db.select().from(settings);
}
export async function upsertSetting(companyId: number | null, key: string, value: any, category = "general") {
  const existing = companyId
    ? await db.select().from(settings).where(and(eq(settings.companyId, companyId), eq(settings.key, key)))
    : await db.select().from(settings).where(eq(settings.key, key));

  if (existing.length > 0) {
    const [s] = await db.update(settings).set({ value, updatedAt: new Date() }).where(eq(settings.id, existing[0].id)).returning();
    return s;
  }
  const [s] = await db.insert(settings).values({ companyId, key, value, category }).returning();
  return s;
}

// ============================================================
// Audit Logs
// ============================================================
export async function createAuditLog(data: InsertAuditLog) {
  const [a] = await db.insert(auditLogs).values(data).returning();
  return a;
}
export async function getAuditLogs(companyId?: number, limit = 100) {
  if (companyId) {
    return db.select().from(auditLogs).where(eq(auditLogs.companyId, companyId)).orderBy(desc(auditLogs.createdAt)).limit(limit);
  }
  return db.select().from(auditLogs).orderBy(desc(auditLogs.createdAt)).limit(limit);
}

// ============================================================
// Dashboard Stats
// ============================================================
export async function getDashboardStats(companyId?: number) {
  const companyFilter = companyId ? eq(products.companyId, companyId) : undefined;
  const expFilter = companyId ? eq(experiences.companyId, companyId) : undefined;

  const [productCount] = await db.select({ count: count() }).from(products).where(companyFilter);
  const [experienceCount] = await db.select({ count: count() }).from(experiences).where(expFilter);
  const [publishedCount] = await db.select({ count: count() }).from(experiences).where(
    companyId
      ? and(eq(experiences.companyId, companyId), eq(experiences.status, "published"))
      : eq(experiences.status, "published")
  );
  const [assetCount] = await db.select({ count: count() }).from(productAssets).where(
    companyId ? eq(productAssets.companyId, companyId) : undefined
  );
  const [companyCount] = await db.select({ count: count() }).from(companies);
  const [userCount] = await db.select({ count: count() }).from(users);

  const analytics = await getAnalyticsSummary(companyId, 30);

  return {
    totalProducts: productCount.count,
    totalExperiences: experienceCount.count,
    publishedExperiences: publishedCount.count,
    totalAssets: assetCount.count,
    totalCompanies: companyCount.count,
    totalUsers: userCount.count,
    analytics: analytics.reduce((acc, a) => ({ ...acc, [a.eventType]: a.count }), {} as Record<string, number>),
  };
}

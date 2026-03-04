import { db } from "./db";
import { eq, and, ilike, or, desc, asc, count, sql, gte } from "drizzle-orm";
import {
  products, cartItems, orders, discountCodes, adminUsers, notifications,
  users, siteSettings, pageViews, banners, categories,
  type Product, type CartItem, type CartItemWithProduct,
  type InsertCartItem, type InsertProduct, type Order,
  type InsertOrder, type DiscountCode, type InsertDiscountCode,
  type Notification, type InsertNotification,
  type User, type InsertUser, type SiteSetting, type PageView, type InsertPageView,
  type Banner, type InsertBanner, type Category, type InsertCategory
} from "@shared/schema";

export interface IStorage {
  getProducts(): Promise<Product[]>;
  getProductsByCategory(category: string): Promise<Product[]>;
  getFeaturedProducts(): Promise<Product[]>;
  getProduct(id: number): Promise<Product | undefined>;
  searchProducts(query: string): Promise<Product[]>;
  createProduct(product: InsertProduct): Promise<Product>;
  updateProduct(id: number, product: Partial<InsertProduct>): Promise<Product | undefined>;
  deleteProduct(id: number): Promise<void>;
  updateProductStock(id: number, stock: number): Promise<Product | undefined>;
  reorderProducts(items: { id: number; orderIndex: number }[]): Promise<void>;

  getCartItems(sessionId: string): Promise<CartItemWithProduct[]>;
  getCartItemsByUserId(userId: number): Promise<CartItemWithProduct[]>;
  addCartItem(item: InsertCartItem): Promise<CartItem>;
  updateCartItem(id: number, quantity: number): Promise<CartItem | undefined>;
  removeCartItem(id: number): Promise<void>;
  clearCart(sessionId: string): Promise<void>;
  migrateCartToUser(sessionId: string, userId: number): Promise<void>;

  createOrder(order: InsertOrder): Promise<Order>;
  getOrders(sessionId: string): Promise<Order[]>;
  getOrdersByUserId(userId: number): Promise<Order[]>;
  getOrder(id: number): Promise<Order | undefined>;
  getAllOrders(): Promise<Order[]>;
  updateOrderStatus(id: number, status: string, trackingNumber?: string): Promise<Order | undefined>;

  getDiscountCode(code: string): Promise<DiscountCode | undefined>;
  createDiscountCode(discount: InsertDiscountCode): Promise<DiscountCode>;
  getAllDiscountCodes(): Promise<DiscountCode[]>;
  updateDiscountCode(id: number, data: Partial<InsertDiscountCode>): Promise<DiscountCode | undefined>;
  deleteDiscountCode(id: number): Promise<void>;
  incrementDiscountUsage(id: number): Promise<void>;

  getNotifications(userId: string): Promise<Notification[]>;
  createNotification(notification: InsertNotification): Promise<Notification>;
  markNotificationRead(id: number): Promise<Notification | undefined>;
  getUnreadNotificationCount(userId: string): Promise<number>;
  sendNotificationToAll(title: string, message: string, productId?: number): Promise<void>;
  deleteNotification(id: number): Promise<void>;
  getAllNotifications(): Promise<Notification[]>;

  createUser(user: InsertUser & { role?: string }): Promise<User>;
  getUserByEmail(email: string): Promise<User | undefined>;
  getUserById(id: number): Promise<User | undefined>;
  getAllUsers(): Promise<User[]>;

  getSetting(key: string): Promise<string | undefined>;
  setSetting(key: string, value: string): Promise<SiteSetting>;
  getAllSettings(): Promise<SiteSetting[]>;

  createPageView(view: InsertPageView): Promise<PageView>;
  getAnalytics(): Promise<{ totalViews: number; uniqueSessions: number; topProducts: { productId: number; views: number; product?: Product }[] }>;

  getBanners(): Promise<Banner[]>;
  getActiveBanners(): Promise<Banner[]>;
  createBanner(banner: InsertBanner): Promise<Banner>;
  updateBanner(id: number, data: Partial<InsertBanner>): Promise<Banner | undefined>;
  deleteBanner(id: number): Promise<void>;
  reorderBanners(items: { id: number; sortOrder: number }[]): Promise<void>;

  getCategories(): Promise<Category[]>;
  getVisibleCategories(): Promise<Category[]>;
  updateCategory(id: number, data: Partial<InsertCategory>): Promise<Category | undefined>;
  reorderCategories(items: { id: number; sortOrder: number }[]): Promise<void>;

  getAdminByUsername(username: string): Promise<typeof adminUsers.$inferSelect | undefined>;
}

export class DatabaseStorage implements IStorage {
  async getProducts(): Promise<Product[]> {
    return db.select().from(products).orderBy(asc(products.orderIndex), desc(products.createdAt));
  }

  async getProductsByCategory(category: string): Promise<Product[]> {
    return db.select().from(products).where(eq(products.category, category)).orderBy(asc(products.orderIndex), desc(products.createdAt));
  }

  async getFeaturedProducts(): Promise<Product[]> {
    return db.select().from(products).where(eq(products.featured, true));
  }

  async getProduct(id: number): Promise<Product | undefined> {
    const [product] = await db.select().from(products).where(eq(products.id, id));
    return product;
  }

  async searchProducts(query: string): Promise<Product[]> {
    const q = `%${query}%`;
    return db.select().from(products).where(
      or(
        ilike(products.nameEn, q),
        ilike(products.nameAr, q),
        ilike(products.descriptionEn, q),
        ilike(products.descriptionAr, q),
        ilike(products.category, q)
      )
    );
  }

  async createProduct(product: InsertProduct): Promise<Product> {
    const [created] = await db.insert(products).values(product).returning();
    return created;
  }

  async updateProduct(id: number, product: Partial<InsertProduct>): Promise<Product | undefined> {
    const [updated] = await db.update(products).set(product).where(eq(products.id, id)).returning();
    return updated;
  }

  async deleteProduct(id: number): Promise<void> {
    await db.delete(products).where(eq(products.id, id));
  }

  async updateProductStock(id: number, stock: number): Promise<Product | undefined> {
    const [updated] = await db.update(products).set({ stock, inStock: stock > 0 }).where(eq(products.id, id)).returning();
    return updated;
  }

  async reorderProducts(items: { id: number; orderIndex: number }[]): Promise<void> {
    for (const item of items) {
      await db.update(products).set({ orderIndex: item.orderIndex }).where(eq(products.id, item.id));
    }
  }

  async getCartItems(sessionId: string): Promise<CartItemWithProduct[]> {
    const rows = await db
      .select({ cartItem: cartItems, product: products })
      .from(cartItems)
      .innerJoin(products, eq(cartItems.productId, products.id))
      .where(eq(cartItems.sessionId, sessionId));
    return rows.map(row => ({ ...row.cartItem, product: row.product }));
  }

  async getCartItemsByUserId(userId: number): Promise<CartItemWithProduct[]> {
    const rows = await db
      .select({ cartItem: cartItems, product: products })
      .from(cartItems)
      .innerJoin(products, eq(cartItems.productId, products.id))
      .where(eq(cartItems.userId, userId));
    return rows.map(row => ({ ...row.cartItem, product: row.product }));
  }

  async addCartItem(item: InsertCartItem): Promise<CartItem> {
    const conditions = [
      eq(cartItems.productId, item.productId),
      eq(cartItems.size, item.size),
      eq(cartItems.color, item.color)
    ];
    if (item.userId) {
      conditions.push(eq(cartItems.userId, item.userId));
    } else {
      conditions.push(eq(cartItems.sessionId, item.sessionId));
    }

    const existing = await db.select().from(cartItems).where(and(...conditions));
    if (existing.length > 0) {
      const [updated] = await db.update(cartItems)
        .set({ quantity: sql`${cartItems.quantity} + ${item.quantity ?? 1}` })
        .where(eq(cartItems.id, existing[0].id))
        .returning();
      return updated;
    }
    const [created] = await db.insert(cartItems).values({ ...item, quantity: item.quantity ?? 1 }).returning();
    return created;
  }

  async updateCartItem(id: number, quantity: number): Promise<CartItem | undefined> {
    const [updated] = await db.update(cartItems).set({ quantity }).where(eq(cartItems.id, id)).returning();
    return updated;
  }

  async removeCartItem(id: number): Promise<void> {
    await db.delete(cartItems).where(eq(cartItems.id, id));
  }

  async clearCart(sessionId: string): Promise<void> {
    await db.delete(cartItems).where(eq(cartItems.sessionId, sessionId));
  }

  async migrateCartToUser(sessionId: string, userId: number): Promise<void> {
    const guestItems = await db.select().from(cartItems).where(
      and(eq(cartItems.sessionId, sessionId), sql`${cartItems.userId} IS NULL`)
    );

    for (const item of guestItems) {
      const existing = await db.select().from(cartItems).where(
        and(
          eq(cartItems.userId, userId),
          eq(cartItems.productId, item.productId),
          eq(cartItems.size, item.size),
          eq(cartItems.color, item.color)
        )
      );
      if (existing.length > 0) {
        await db.update(cartItems)
          .set({ quantity: sql`${cartItems.quantity} + ${item.quantity}` })
          .where(eq(cartItems.id, existing[0].id));
        await db.delete(cartItems).where(eq(cartItems.id, item.id));
      } else {
        await db.update(cartItems)
          .set({ userId, sessionId: `user_${userId}` })
          .where(eq(cartItems.id, item.id));
      }
    }
  }

  async createOrder(order: InsertOrder): Promise<Order> {
    const [created] = await db.insert(orders).values(order).returning();
    return created;
  }

  async getOrders(sessionId: string): Promise<Order[]> {
    return db.select().from(orders).where(eq(orders.sessionId, sessionId)).orderBy(desc(orders.createdAt));
  }

  async getOrdersByUserId(userId: number): Promise<Order[]> {
    return db.select().from(orders).where(eq(orders.userId, userId)).orderBy(desc(orders.createdAt));
  }

  async getOrder(id: number): Promise<Order | undefined> {
    const [order] = await db.select().from(orders).where(eq(orders.id, id));
    return order;
  }

  async getAllOrders(): Promise<Order[]> {
    return db.select().from(orders).orderBy(desc(orders.createdAt));
  }

  async updateOrderStatus(id: number, status: string, trackingNumber?: string): Promise<Order | undefined> {
    const data: any = { status };
    if (trackingNumber) data.trackingNumber = trackingNumber;
    const [updated] = await db.update(orders).set(data).where(eq(orders.id, id)).returning();
    return updated;
  }

  async getDiscountCode(code: string): Promise<DiscountCode | undefined> {
    const [discount] = await db.select().from(discountCodes).where(eq(discountCodes.code, code.toUpperCase()));
    return discount;
  }

  async createDiscountCode(discount: InsertDiscountCode): Promise<DiscountCode> {
    const [created] = await db.insert(discountCodes).values({ ...discount, code: discount.code.toUpperCase() }).returning();
    return created;
  }

  async getAllDiscountCodes(): Promise<DiscountCode[]> {
    return db.select().from(discountCodes);
  }

  async updateDiscountCode(id: number, data: Partial<InsertDiscountCode>): Promise<DiscountCode | undefined> {
    const [updated] = await db.update(discountCodes).set(data).where(eq(discountCodes.id, id)).returning();
    return updated;
  }

  async deleteDiscountCode(id: number): Promise<void> {
    await db.delete(discountCodes).where(eq(discountCodes.id, id));
  }

  async incrementDiscountUsage(id: number): Promise<void> {
    await db.update(discountCodes).set({ usedCount: sql`${discountCodes.usedCount} + 1` }).where(eq(discountCodes.id, id));
  }

  async getNotifications(userId: string): Promise<Notification[]> {
    return db.select().from(notifications).where(eq(notifications.userId, userId)).orderBy(desc(notifications.createdAt));
  }

  async createNotification(notification: InsertNotification): Promise<Notification> {
    const [created] = await db.insert(notifications).values(notification).returning();
    return created;
  }

  async markNotificationRead(id: number): Promise<Notification | undefined> {
    const [updated] = await db.update(notifications).set({ read: true }).where(eq(notifications.id, id)).returning();
    return updated;
  }

  async getUnreadNotificationCount(userId: string): Promise<number> {
    const [result] = await db.select({ count: count() }).from(notifications).where(
      and(eq(notifications.userId, userId), eq(notifications.read, false))
    );
    return result?.count ?? 0;
  }

  async sendNotificationToAll(title: string, message: string, productId?: number): Promise<void> {
    const allUsers = await db.select().from(users);
    for (const user of allUsers) {
      await db.insert(notifications).values({
        userId: String(user.id),
        title,
        message,
        productId: productId || null,
        read: false,
      });
    }
  }

  async deleteNotification(id: number): Promise<void> {
    await db.delete(notifications).where(eq(notifications.id, id));
  }

  async getAllNotifications(): Promise<Notification[]> {
    return db.select().from(notifications).orderBy(desc(notifications.createdAt));
  }

  async createUser(user: InsertUser & { role?: string }): Promise<User> {
    const values: any = { ...user };
    if (user.role) values.role = user.role;
    const [created] = await db.insert(users).values(values).returning();
    return created;
  }

  async getUserByEmail(email: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.email, email.toLowerCase()));
    return user;
  }

  async getUserById(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getAllUsers(): Promise<User[]> {
    return db.select().from(users);
  }

  async getSetting(key: string): Promise<string | undefined> {
    const [setting] = await db.select().from(siteSettings).where(eq(siteSettings.key, key));
    return setting?.value;
  }

  async setSetting(key: string, value: string): Promise<SiteSetting> {
    const existing = await db.select().from(siteSettings).where(eq(siteSettings.key, key));
    if (existing.length > 0) {
      const [updated] = await db.update(siteSettings)
        .set({ value, updatedAt: new Date() })
        .where(eq(siteSettings.key, key))
        .returning();
      return updated;
    }
    const [created] = await db.insert(siteSettings).values({ key, value }).returning();
    return created;
  }

  async getAllSettings(): Promise<SiteSetting[]> {
    return db.select().from(siteSettings);
  }

  async createPageView(view: InsertPageView): Promise<PageView> {
    const [created] = await db.insert(pageViews).values(view).returning();
    return created;
  }

  async getAnalytics(): Promise<{ totalViews: number; uniqueSessions: number; topProducts: { productId: number; views: number; product?: Product }[] }> {
    const [totals] = await db.select({
      totalViews: count(),
      uniqueSessions: sql<number>`COUNT(DISTINCT ${pageViews.sessionId})`,
    }).from(pageViews);

    const topProductRows = await db.select({
      productId: pageViews.productId,
      views: count(),
    }).from(pageViews)
      .where(sql`${pageViews.productId} IS NOT NULL`)
      .groupBy(pageViews.productId)
      .orderBy(desc(count()))
      .limit(10);

    const topProducts = [];
    for (const row of topProductRows) {
      if (row.productId) {
        const product = await this.getProduct(row.productId);
        topProducts.push({ productId: row.productId, views: row.views, product });
      }
    }

    return {
      totalViews: totals?.totalViews ?? 0,
      uniqueSessions: totals?.uniqueSessions ?? 0,
      topProducts,
    };
  }

  async getBanners(): Promise<Banner[]> {
    return db.select().from(banners).orderBy(asc(banners.sortOrder));
  }

  async getActiveBanners(): Promise<Banner[]> {
    return db.select().from(banners).where(eq(banners.active, true)).orderBy(asc(banners.sortOrder));
  }

  async createBanner(banner: InsertBanner): Promise<Banner> {
    const [created] = await db.insert(banners).values(banner).returning();
    return created;
  }

  async updateBanner(id: number, data: Partial<InsertBanner>): Promise<Banner | undefined> {
    const [updated] = await db.update(banners).set(data).where(eq(banners.id, id)).returning();
    return updated;
  }

  async deleteBanner(id: number): Promise<void> {
    await db.delete(banners).where(eq(banners.id, id));
  }

  async reorderBanners(items: { id: number; sortOrder: number }[]): Promise<void> {
    for (const item of items) {
      await db.update(banners).set({ sortOrder: item.sortOrder }).where(eq(banners.id, item.id));
    }
  }

  async getCategories(): Promise<Category[]> {
    return db.select().from(categories).orderBy(asc(categories.sortOrder));
  }

  async getVisibleCategories(): Promise<Category[]> {
    return db.select().from(categories).where(eq(categories.visible, true)).orderBy(asc(categories.sortOrder));
  }

  async updateCategory(id: number, data: Partial<InsertCategory>): Promise<Category | undefined> {
    const [updated] = await db.update(categories).set(data).where(eq(categories.id, id)).returning();
    return updated;
  }

  async reorderCategories(items: { id: number; sortOrder: number }[]): Promise<void> {
    for (const item of items) {
      await db.update(categories).set({ sortOrder: item.sortOrder }).where(eq(categories.id, item.id));
    }
  }

  async getAdminByUsername(username: string) {
    const [admin] = await db.select().from(adminUsers).where(eq(adminUsers.username, username));
    return admin;
  }
}

export const storage = new DatabaseStorage();

import type { Request, Response } from "express";
import { db } from "../db";
import { users, orders, cartItems, products, notifications } from "@shared/schema";
import { eq, ilike, or, sql, desc, asc, and, gte, lte, count } from "drizzle-orm";
import { AppError } from "../utils/AppError";
import ExcelJS from "exceljs";

interface CustomerSummary {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  role: string;
  createdAt: Date | null;
  totalOrders: number;
  totalSpent: number;
  lastOrderDate: Date | null;
}

async function buildCustomerQuery(query: Request["query"]) {
  const { search, sort, hasOrders, from, to } = query;

  const allUsers = await db.select().from(users).where(
    (() => {
      const conditions = [];
      if (search && typeof search === "string" && search.trim()) {
        const term = `%${search.trim()}%`;
        conditions.push(
          or(
            ilike(users.name, term),
            ilike(users.email, term),
            ilike(users.phone, term),
            sql`CAST(${users.id} AS TEXT) = ${search.trim()}`
          )
        );
      }
      if (from && typeof from === "string") {
        conditions.push(gte(users.createdAt, new Date(from)));
      }
      if (to && typeof to === "string") {
        conditions.push(lte(users.createdAt, new Date(to)));
      }
      return conditions.length > 0 ? and(...conditions) : undefined;
    })()
  );

  const userIds = allUsers.map(u => u.id);
  if (userIds.length === 0) return [];

  const orderStats = await db
    .select({
      userId: orders.userId,
      totalOrders: count(orders.id),
      totalSpent: sql<number>`COALESCE(SUM(CASE WHEN ${orders.status} != 'cancelled' THEN ${orders.total} ELSE 0 END), 0)`,
      lastOrderDate: sql<Date>`MAX(${orders.createdAt})`,
    })
    .from(orders)
    .where(sql`${orders.userId} IN (${sql.join(userIds.map(id => sql`${id}`), sql`, `)})`)
    .groupBy(orders.userId);

  const statsMap = new Map(orderStats.map(s => [s.userId, s]));

  let result: CustomerSummary[] = allUsers.map(u => {
    const stats = statsMap.get(u.id);
    return {
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      createdAt: u.createdAt,
      totalOrders: Number(stats?.totalOrders ?? 0),
      totalSpent: Number(stats?.totalSpent ?? 0),
      lastOrderDate: stats?.lastOrderDate ?? null,
    };
  });

  if (hasOrders === "true") {
    result = result.filter(c => c.totalOrders > 0);
  } else if (hasOrders === "false") {
    result = result.filter(c => c.totalOrders === 0);
  }

  const sortBy = typeof sort === "string" ? sort : "newest";
  switch (sortBy) {
    case "highest_spent":
      result.sort((a, b) => b.totalSpent - a.totalSpent);
      break;
    case "most_orders":
      result.sort((a, b) => b.totalOrders - a.totalOrders);
      break;
    case "last_order":
      result.sort((a, b) => {
        if (!a.lastOrderDate && !b.lastOrderDate) return 0;
        if (!a.lastOrderDate) return 1;
        if (!b.lastOrderDate) return -1;
        return new Date(b.lastOrderDate).getTime() - new Date(a.lastOrderDate).getTime();
      });
      break;
    case "newest":
    default:
      result.sort((a, b) => {
        if (!a.createdAt && !b.createdAt) return 0;
        if (!a.createdAt) return 1;
        if (!b.createdAt) return -1;
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      });
  }

  return result;
}

export async function listCustomers(req: Request, res: Response) {
  const customers = await buildCustomerQuery(req.query);

  const page = Math.max(1, parseInt(req.query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string) || 20));
  const offset = (page - 1) * limit;
  const paginated = customers.slice(offset, offset + limit);

  res.json({
    success: true,
    data: paginated,
    totalCount: customers.length,
    page,
    limit,
  });
}

export async function getCustomer(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid customer ID");

  const [user] = await db.select().from(users).where(eq(users.id, id));
  if (!user) throw AppError.notFound("Customer not found");

  const customerOrders = await db
    .select()
    .from(orders)
    .where(eq(orders.userId, id))
    .orderBy(desc(orders.createdAt));

  const totalSpent = customerOrders
    .filter(o => o.status !== "cancelled")
    .reduce((sum, o) => sum + o.total, 0);

  const cartRows = await db
    .select({
      id: cartItems.id,
      productId: cartItems.productId,
      quantity: cartItems.quantity,
      size: cartItems.size,
      color: cartItems.color,
      productNameEn: products.nameEn,
      productNameAr: products.nameAr,
      productPrice: products.price,
      productImages: products.images,
    })
    .from(cartItems)
    .leftJoin(products, eq(cartItems.productId, products.id))
    .where(eq(cartItems.userId, id));

  res.json({
    success: true,
    data: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      createdAt: user.createdAt,
      totalOrders: customerOrders.length,
      totalSpent,
      lastOrderDate: customerOrders[0]?.createdAt ?? null,
      orders: customerOrders,
      cart: cartRows,
    },
  });
}

export async function exportCustomers(req: Request, res: Response) {
  const customers = await buildCustomerQuery(req.query);

  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Customers");

  sheet.columns = [
    { header: "ID", key: "id", width: 8 },
    { header: "Name / الاسم", key: "name", width: 25 },
    { header: "Email / البريد", key: "email", width: 30 },
    { header: "Phone / الهاتف", key: "phone", width: 18 },
    { header: "Role", key: "role", width: 10 },
    { header: "Registered / تاريخ التسجيل", key: "createdAt", width: 20 },
    { header: "Total Orders / الطلبات", key: "totalOrders", width: 14 },
    { header: "Total Spent (SAR) / المبلغ", key: "totalSpent", width: 18 },
    { header: "Last Order / آخر طلب", key: "lastOrderDate", width: 20 },
  ];

  sheet.getRow(1).font = { bold: true };

  for (const c of customers) {
    sheet.addRow({
      id: c.id,
      name: c.name,
      email: c.email,
      phone: c.phone ?? "",
      role: c.role,
      createdAt: c.createdAt ? new Date(c.createdAt).toISOString().split("T")[0] : "",
      totalOrders: c.totalOrders,
      totalSpent: (c.totalSpent / 100).toFixed(2),
      lastOrderDate: c.lastOrderDate ? new Date(c.lastOrderDate).toISOString().split("T")[0] : "",
    });
  }

  const buffer = await workbook.xlsx.writeBuffer();
  res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
  res.setHeader("Content-Disposition", `attachment; filename=customers_${Date.now()}.xlsx`);
  res.send(buffer);
}

export async function exportCustomer(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid customer ID");

  const [user] = await db.select().from(users).where(eq(users.id, id));
  if (!user) throw AppError.notFound("Customer not found");

  const customerOrders = await db
    .select()
    .from(orders)
    .where(eq(orders.userId, id))
    .orderBy(desc(orders.createdAt));

  const cartRows = await db
    .select({
      productId: cartItems.productId,
      quantity: cartItems.quantity,
      size: cartItems.size,
      color: cartItems.color,
      productNameEn: products.nameEn,
      productPrice: products.price,
    })
    .from(cartItems)
    .leftJoin(products, eq(cartItems.productId, products.id))
    .where(eq(cartItems.userId, id));

  const workbook = new ExcelJS.Workbook();

  const infoSheet = workbook.addWorksheet("Customer Info");
  infoSheet.columns = [
    { header: "Field", key: "field", width: 20 },
    { header: "Value", key: "value", width: 40 },
  ];
  infoSheet.getRow(1).font = { bold: true };
  infoSheet.addRow({ field: "ID", value: user.id });
  infoSheet.addRow({ field: "Name", value: user.name });
  infoSheet.addRow({ field: "Email", value: user.email });
  infoSheet.addRow({ field: "Phone", value: user.phone ?? "" });
  infoSheet.addRow({ field: "Role", value: user.role });
  infoSheet.addRow({ field: "Registered", value: user.createdAt ? new Date(user.createdAt).toISOString().split("T")[0] : "" });
  infoSheet.addRow({ field: "Total Orders", value: customerOrders.length });
  const totalSpent = customerOrders.filter(o => o.status !== "cancelled").reduce((s, o) => s + o.total, 0);
  infoSheet.addRow({ field: "Total Spent (SAR)", value: (totalSpent / 100).toFixed(2) });

  const ordersSheet = workbook.addWorksheet("Orders");
  ordersSheet.columns = [
    { header: "Order ID", key: "id", width: 10 },
    { header: "Date", key: "date", width: 18 },
    { header: "Status", key: "status", width: 14 },
    { header: "Delivery", key: "delivery", width: 14 },
    { header: "Items", key: "items", width: 8 },
    { header: "Total (SAR)", key: "total", width: 14 },
  ];
  ordersSheet.getRow(1).font = { bold: true };
  for (const o of customerOrders) {
    const itemsArr = Array.isArray(o.items) ? o.items : [];
    ordersSheet.addRow({
      id: o.id,
      date: o.createdAt ? new Date(o.createdAt).toISOString().replace("T", " ").substring(0, 19) : "",
      status: o.status,
      delivery: o.deliveryMethod,
      items: itemsArr.length,
      total: (o.total / 100).toFixed(2),
    });
  }

  const cartSheet = workbook.addWorksheet("Cart");
  cartSheet.columns = [
    { header: "Product", key: "product", width: 30 },
    { header: "Qty", key: "qty", width: 8 },
    { header: "Size", key: "size", width: 10 },
    { header: "Color", key: "color", width: 12 },
    { header: "Unit Price (SAR)", key: "price", width: 16 },
  ];
  cartSheet.getRow(1).font = { bold: true };
  for (const c of cartRows) {
    cartSheet.addRow({
      product: c.productNameEn ?? `Product #${c.productId}`,
      qty: c.quantity,
      size: c.size,
      color: c.color,
      price: c.productPrice ? (c.productPrice / 100).toFixed(2) : "",
    });
  }

  const buffer = await workbook.xlsx.writeBuffer();
  const safeName = user.name.replace(/[^a-zA-Z0-9]/g, "_").substring(0, 30);
  res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
  res.setHeader("Content-Disposition", `attachment; filename=customer_${safeName}_${id}.xlsx`);
  res.send(buffer);
}

export async function notifyCart(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid customer ID");

  const { messageAr, messageEn } = req.body;
  if (!messageAr || typeof messageAr !== "string" || messageAr.trim().length < 3) {
    throw AppError.badRequest("Arabic message is required (min 3 characters)");
  }

  const [user] = await db.select().from(users).where(eq(users.id, id));
  if (!user) throw AppError.notFound("Customer not found");

  const cartRows = await db
    .select({
      quantity: cartItems.quantity,
      productPrice: products.price,
    })
    .from(cartItems)
    .leftJoin(products, eq(cartItems.productId, products.id))
    .where(eq(cartItems.userId, id));

  const itemsCount = cartRows.reduce((sum, r) => sum + r.quantity, 0);
  const cartTotal = cartRows.reduce((sum, r) => sum + (r.productPrice ?? 0) * r.quantity, 0);

  const title = messageEn && typeof messageEn === "string" && messageEn.trim()
    ? messageEn.trim()
    : messageAr.trim();

  const [notif] = await db.insert(notifications).values({
    userId: String(user.id),
    title: title,
    message: messageAr.trim(),
    read: false,
  }).returning();

  res.json({ success: true });
}

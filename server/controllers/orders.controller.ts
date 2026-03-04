import type { Request, Response } from "express";
import { storage } from "../storage";
import { insertOrderSchema } from "@shared/schema";
import { AppError } from "../utils/AppError";

export async function createOrder(req: Request, res: Response) {
  const sessionId = req.session?.id || "anonymous";
  const userId = req.session?.userId;

  const orderData: any = { ...req.body, sessionId };
  if (userId) orderData.userId = userId;

  const result = insertOrderSchema.safeParse(orderData);
  if (!result.success) throw AppError.badRequest("Invalid order data");

  const items = req.body.items as any[];
  if (items && Array.isArray(items)) {
    for (const item of items) {
      if (item.productId) {
        const product = await storage.getProduct(item.productId);
        if (product && product.stock < (item.quantity || 1)) {
          throw AppError.badRequest(`Insufficient stock for ${product.nameEn}`);
        }
      }
    }
  }

  const order = await storage.createOrder(result.data);
  res.json(order);

  try {
    if (items && Array.isArray(items)) {
      for (const item of items) {
        if (item.productId) {
          const product = await storage.getProduct(item.productId);
          if (product) {
            await storage.updateProductStock(item.productId, Math.max(0, product.stock - (item.quantity || 1)));
          }
        }
      }
    }
    if (userId) await storage.clearCart(`user_${userId}`);
    await storage.clearCart(sessionId);
    if (order.discountCode) {
      const discount = await storage.getDiscountCode(order.discountCode);
      if (discount) await storage.incrementDiscountUsage(discount.id);
    }
  } catch (postOrderError) {
    console.error("Post-order cleanup error:", postOrderError);
  }
}

export async function listOrders(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (userId) {
    return res.json(await storage.getOrdersByUserId(userId));
  }
  const sessionId = req.session?.id || "anonymous";
  res.json(await storage.getOrders(sessionId));
}

export async function getOrder(req: Request, res: Response) {
  const order = await storage.getOrder(parseInt(req.params.id));
  if (!order) throw AppError.notFound("Order not found");
  const items = order.items as any[];
  if (Array.isArray(items)) {
    const enrichedItems = await Promise.all(items.map(async (item: any) => {
      if (item.image || (item.images && item.images.length > 0)) return item;
      if (item.productId) {
        const product = await storage.getProduct(item.productId);
        if (product && product.images && product.images.length > 0) {
          return { ...item, image: product.images[0] };
        }
      }
      return item;
    }));
    return res.json({ ...order, items: enrichedItems });
  }
  res.json(order);
}

export async function adminListOrders(req: Request, res: Response) {
  const { deliveryMethod, status, q, dateFrom, dateTo, sort } = req.query as Record<string, string | undefined>;

  let allOrders = await storage.getAllOrders();

  if (deliveryMethod && deliveryMethod !== "all") {
    const method = deliveryMethod === "store_pickup" ? "pickup" : deliveryMethod;
    allOrders = allOrders.filter(o => o.deliveryMethod === method);
  }

  if (status && status !== "all") {
    allOrders = allOrders.filter(o => o.status === status);
  }

  if (q && q.trim()) {
    const search = q.trim().toLowerCase().replace(/^#/, "");
    allOrders = allOrders.filter(o => {
      if (String(o.id) === search) return true;
      if (o.customerName?.toLowerCase().includes(search)) return true;
      if (o.customerPhone?.toLowerCase().includes(search)) return true;
      if (o.customerEmail?.toLowerCase().includes(search)) return true;
      return false;
    });
  }

  if (dateFrom) {
    const from = new Date(dateFrom);
    if (!isNaN(from.getTime())) {
      allOrders = allOrders.filter(o => o.createdAt && new Date(o.createdAt) >= from);
    }
  }
  if (dateTo) {
    const to = new Date(dateTo);
    if (!isNaN(to.getTime())) {
      to.setHours(23, 59, 59, 999);
      allOrders = allOrders.filter(o => o.createdAt && new Date(o.createdAt) <= to);
    }
  }

  if (sort) {
    switch (sort) {
      case "oldest":
        allOrders.sort((a, b) => new Date(a.createdAt!).getTime() - new Date(b.createdAt!).getTime());
        break;
      case "total_desc":
        allOrders.sort((a, b) => b.total - a.total);
        break;
      case "total_asc":
        allOrders.sort((a, b) => a.total - b.total);
        break;
      default:
        break;
    }
  }

  const enriched = await Promise.all(allOrders.map(async (order) => {
    const items = order.items as any[];
    if (!Array.isArray(items)) return order;
    const enrichedItems = await Promise.all(items.map(async (item: any) => {
      if (item.image || (item.images && item.images.length > 0)) return item;
      if (item.productId) {
        const product = await storage.getProduct(item.productId);
        if (product && product.images && product.images.length > 0) {
          return { ...item, image: product.images[0] };
        }
      }
      return item;
    }));
    return { ...order, items: enrichedItems };
  }));
  res.json(enriched);
}

export async function updateOrderStatus(req: Request, res: Response) {
  const { status, trackingNumber } = req.body;
  if (!status) throw AppError.badRequest("Status is required");
  const order = await storage.updateOrderStatus(parseInt(req.params.id), status, trackingNumber);
  if (!order) throw AppError.notFound("Order not found");

  res.json(order);

  try {
    const notifUserId = order.userId ? String(order.userId) : order.sessionId;
    if (status === "ready_for_pickup" && order.deliveryMethod === "pickup") {
      await storage.createNotification({
        userId: notifUserId, orderId: order.id,
        title: "طلبك جاهز للاستلام",
        message: `الطلب رقم #${order.id} جاهز للاستلام من المتجر`,
        read: false,
      });
    } else if (status === "shipped") {
      await storage.createNotification({
        userId: notifUserId, orderId: order.id,
        title: "تم شحن طلبك",
        message: `الطلب رقم #${order.id} في الطريق إليك${trackingNumber ? ` - رقم التتبع: ${trackingNumber}` : ''}`,
        read: false,
      });
    } else if (status === "delivered") {
      await storage.createNotification({
        userId: notifUserId, orderId: order.id,
        title: "تم توصيل طلبك",
        message: `الطلب رقم #${order.id} تم توصيله بنجاح`,
        read: false,
      });
    }
  } catch (notifError) {
    console.error("Notification creation error:", notifError);
  }
}

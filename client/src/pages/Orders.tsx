import { Link } from "wouter";
import {
  Package, ArrowRight, Truck, Store as StoreIcon, MapPin, Clock,
  CheckCircle, Circle, ArrowLeft,
} from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import type { Order } from "@shared/schema";

const STATUS_CONFIG: Record<string, { label: string; labelAr: string; color: string; icon: typeof Circle }> = {
  processing: { label: "Processing", labelAr: "قيد المعالجة", color: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300", icon: Circle },
  confirmed: { label: "Confirmed", labelAr: "مؤكد", color: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300", icon: Circle },
  shipped: { label: "Shipped", labelAr: "تم الشحن", color: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300", icon: Truck },
  delivered: { label: "Delivered", labelAr: "تم التوصيل", color: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300", icon: CheckCircle },
  ready_for_pickup: { label: "Ready for Pickup", labelAr: "جاهز للاستلام", color: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300", icon: StoreIcon },
  picked_up: { label: "Picked Up", labelAr: "تم الاستلام", color: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300", icon: CheckCircle },
  cancelled: { label: "Cancelled", labelAr: "ملغي", color: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300", icon: Circle },
};

export default function Orders() {
  const { data: orders, isLoading } = useQuery<Order[]>({
    queryKey: ["/api/orders"],
  });

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto px-4 sm:px-6 py-10">
        <Skeleton className="h-8 w-48 mb-6" />
        <div className="flex flex-col gap-4">
          {[1, 2, 3].map(i => <Skeleton key={i} className="h-48 rounded-lg" />)}
        </div>
      </div>
    );
  }

  if (!orders || orders.length === 0) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center gap-6 px-4">
        <div className="w-20 h-20 rounded-full bg-accent flex items-center justify-center">
          <Package className="w-10 h-10 text-muted-foreground" />
        </div>
        <div className="text-center">
          <h2 className="text-2xl font-serif font-bold text-foreground mb-2">No orders yet</h2>
          <p className="text-muted-foreground text-sm max-w-xs">
            Once you place an order, it will appear here.
          </p>
          <p className="text-muted-foreground text-xs mt-1">لا توجد طلبات بعد</p>
        </div>
        <Link href="/shop">
          <Button size="lg">
            Start Shopping
            <ArrowRight className="ml-2 w-4 h-4" />
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        <Link href="/shop">
          <Button variant="ghost" size="sm" className="mb-4">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Continue Shopping
          </Button>
        </Link>

        <div className="mb-6">
          <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-1 block">Golden Pearl</span>
          <h1 className="text-2xl sm:text-3xl font-serif font-bold text-foreground">
            My Orders
          </h1>
          <p className="text-sm text-muted-foreground mt-1">طلباتي</p>
        </div>

        <div className="flex flex-col gap-4">
          {orders.map(order => {
            const statusInfo = STATUS_CONFIG[order.status] ?? STATUS_CONFIG.processing;
            const StatusIcon = statusInfo.icon;
            const items = (order.items as Array<{
              nameEn?: string; nameAr?: string; price: number;
              quantity: number; size: string; color: string; image?: string;
            }>) ?? [];
            const isPickup = order.fulfillmentType === "pickup";

            return (
              <div
                key={order.id}
                className="bg-card border border-card-border rounded-lg p-5 sm:p-6"
              >
                {/* Header */}
                <div className="flex items-start justify-between gap-3 flex-wrap mb-4">
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-serif font-bold text-foreground">Order #{order.id}</h3>
                      <Badge className={`text-xs font-medium ${statusInfo.color}`}>
                        <StatusIcon className="w-3 h-3 mr-1" />
                        {statusInfo.label}
                      </Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {order.createdAt ? new Date(order.createdAt).toLocaleDateString("en-US", {
                        year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit",
                      }) : ""}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-bold text-foreground">${(order.total / 100).toFixed(2)}</p>
                    <p className="text-xs text-muted-foreground">{items.length} item{items.length !== 1 ? "s" : ""}</p>
                  </div>
                </div>

                {/* Fulfillment type badge */}
                <div className="flex items-center gap-2 mb-3">
                  {isPickup ? (
                    <div className="flex items-center gap-1.5 text-xs bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-300 px-2.5 py-1 rounded-full">
                      <StoreIcon className="w-3 h-3" />
                      <span>Pickup / استلام من المتجر</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-1.5 text-xs bg-sky-100 dark:bg-sky-900/30 text-sky-700 dark:text-sky-300 px-2.5 py-1 rounded-full">
                      <Truck className="w-3 h-3" />
                      <span>Delivery / التوصيل</span>
                    </div>
                  )}
                </div>

                {/* Pickup details */}
                {isPickup && order.pickupStoreName && (
                  <div className="bg-accent/40 rounded-md p-3 mb-3">
                    <p className="text-xs font-semibold text-foreground mb-1">Pickup Location / فرع الاستلام:</p>
                    <div className="flex flex-col gap-1">
                      <div className="flex items-start gap-2">
                        <MapPin className="w-3.5 h-3.5 text-muted-foreground mt-0.5 shrink-0" />
                        <span className="text-xs text-muted-foreground">{order.pickupStoreName}</span>
                      </div>
                      {order.pickupAddress && (
                        <div className="flex items-start gap-2">
                          <MapPin className="w-3.5 h-3.5 text-transparent mt-0.5 shrink-0" />
                          <span className="text-xs text-muted-foreground">{order.pickupAddress}</span>
                        </div>
                      )}
                      {order.pickupHours && (
                        <div className="flex items-start gap-2">
                          <Clock className="w-3.5 h-3.5 text-muted-foreground mt-0.5 shrink-0" />
                          <span className="text-xs text-muted-foreground">{order.pickupHours}</span>
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {/* Delivery address */}
                {!isPickup && order.shippingAddress && (
                  <div className="bg-accent/40 rounded-md p-3 mb-3">
                    <p className="text-xs font-semibold text-foreground mb-1">Shipping to:</p>
                    <p className="text-xs text-muted-foreground">
                      {order.shippingAddress}, {order.shippingCity}, {order.shippingCountry}
                    </p>
                    {order.trackingNumber && (
                      <p className="text-xs text-primary mt-1">Tracking: {order.trackingNumber}</p>
                    )}
                  </div>
                )}

                {/* Items */}
                <Separator className="my-3" />
                <div className="flex flex-col gap-2">
                  {items.slice(0, 3).map((item, idx) => (
                    <div key={idx} className="flex items-center gap-3">
                      {item.image && (
                        <div className="w-10 h-12 rounded-md overflow-hidden bg-accent/30 shrink-0">
                          <img src={item.image} alt={item.nameEn ?? ""} className="w-full h-full object-cover" />
                        </div>
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-foreground truncate">{item.nameEn}</p>
                        <p className="text-xs text-muted-foreground">{item.size} / {item.color} x{item.quantity}</p>
                      </div>
                      <span className="text-xs font-medium text-foreground">${(item.price * item.quantity / 100).toFixed(2)}</span>
                    </div>
                  ))}
                  {items.length > 3 && (
                    <p className="text-xs text-muted-foreground">+{items.length - 3} more items</p>
                  )}
                </div>

                {/* Price breakdown */}
                <Separator className="my-3" />
                <div className="flex flex-col gap-1 text-xs">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Subtotal</span>
                    <span className="text-foreground">${(order.subtotal / 100).toFixed(2)}</span>
                  </div>
                  {order.discount > 0 && (
                    <div className="flex justify-between">
                      <span className="text-emerald-600 dark:text-emerald-400">Discount{order.discountCode ? ` (${order.discountCode})` : ""}</span>
                      <span className="text-emerald-600 dark:text-emerald-400">-${(order.discount / 100).toFixed(2)}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Shipping</span>
                    <span className="text-foreground">
                      {order.shipping === 0 ? "Free" : `$${(order.shipping / 100).toFixed(2)}`}
                    </span>
                  </div>
                  <div className="flex justify-between font-bold text-sm mt-1">
                    <span>Total</span>
                    <span>${(order.total / 100).toFixed(2)}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

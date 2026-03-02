import { useState } from "react";
import { Link, useLocation } from "wouter";
import {
  ArrowLeft, ArrowRight, Truck, Store as StoreIcon, MapPin, Clock,
  Phone, ExternalLink, Package, ShieldCheck, Info,
} from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useToast } from "@/hooks/use-toast";
import { apiRequest } from "@/lib/queryClient";
import type { CartItemWithProduct, Store, Order } from "@shared/schema";
import { formatSAR } from "@/lib/utils";

export default function Checkout() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [, setLocation] = useLocation();

  const [fulfillmentType, setFulfillmentType] = useState<"delivery" | "pickup">("delivery");
  const [selectedStoreId, setSelectedStoreId] = useState<number | null>(null);

  // Form fields
  const [customerName, setCustomerName] = useState("");
  const [customerEmail, setCustomerEmail] = useState("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [shippingAddress, setShippingAddress] = useState("");
  const [shippingCity, setShippingCity] = useState("");
  const [shippingCountry, setShippingCountry] = useState("");
  const [notes, setNotes] = useState("");
  const [discountCode, setDiscountCode] = useState("");
  const [discountApplied, setDiscountApplied] = useState<{ type: string; value: number } | null>(null);

  const { data: cartItems, isLoading: cartLoading } = useQuery<CartItemWithProduct[]>({
    queryKey: ["/api/cart"],
  });

  const { data: storesList, isLoading: storesLoading } = useQuery<Store[]>({
    queryKey: ["/api/stores"],
  });

  const selectedStore = storesList?.find(s => s.id === selectedStoreId);

  const subtotal = cartItems?.reduce((sum, item) => sum + item.product.price * item.quantity, 0) ?? 0;
  const FREE_SHIPPING_THRESHOLD = 15000;
  const SHIPPING_FEE = 1500;
  const baseShipping = fulfillmentType === "pickup" ? 0 : (subtotal >= FREE_SHIPPING_THRESHOLD ? 0 : SHIPPING_FEE);

  let discountAmount = 0;
  if (discountApplied) {
    if (discountApplied.type === "percentage") {
      discountAmount = Math.round(subtotal * discountApplied.value / 100);
    } else {
      discountAmount = discountApplied.value;
    }
  }
  const shipping = Math.max(0, baseShipping - (discountApplied?.type === "fixed" ? discountAmount : 0));
  const total = subtotal - (discountApplied?.type === "percentage" ? discountAmount : 0) + (fulfillmentType === "pickup" ? 0 : shipping);

  const validateDiscount = useMutation({
    mutationFn: () => apiRequest("POST", "/api/discounts/validate", { code: discountCode }),
    onSuccess: async (res) => {
      const data = await res.json();
      if (data.minOrder && subtotal < data.minOrder) {
        toast({ title: "Minimum not met", description: `Minimum order of ${formatSAR(data.minOrder)} required.`, variant: "destructive" });
        return;
      }
      setDiscountApplied({ type: data.type, value: data.value });
      toast({ title: "Discount applied!", description: `Code "${discountCode.toUpperCase()}" applied successfully.` });
    },
    onError: () => {
      toast({ title: "Invalid code", description: "This discount code is invalid or expired.", variant: "destructive" });
    },
  });

  const placeOrder = useMutation({
    mutationFn: async () => {
      const orderData: Record<string, unknown> = {
        items: cartItems?.map(item => ({
          productId: item.productId,
          nameEn: item.product.nameEn,
          nameAr: item.product.nameAr,
          price: item.product.price,
          quantity: item.quantity,
          size: item.size,
          color: item.color,
          image: item.product.images[0],
        })),
        subtotal,
        shipping: fulfillmentType === "pickup" ? 0 : shipping,
        discount: discountAmount,
        total,
        fulfillmentType,
        customerName,
        customerEmail: customerEmail || undefined,
        customerPhone,
        shippingAddress: fulfillmentType === "delivery" ? shippingAddress : "",
        shippingCity: fulfillmentType === "delivery" ? shippingCity : "",
        shippingCountry: fulfillmentType === "delivery" ? shippingCountry : "",
        discountCode: discountApplied ? discountCode.toUpperCase() : undefined,
        notes: notes || undefined,
      };

      if (fulfillmentType === "pickup" && selectedStore) {
        orderData.pickupStoreId = selectedStore.id;
        orderData.pickupStoreName = selectedStore.nameEn;
        orderData.pickupAddress = selectedStore.addressEn;
        orderData.pickupHours = selectedStore.hoursEn;
      }

      return apiRequest("POST", "/api/orders", orderData);
    },
    onSuccess: async (res) => {
      const order: Order = await res.json();
      queryClient.invalidateQueries({ queryKey: ["/api/cart"] });
      toast({ title: "Order placed!", description: `Order #${order.id} has been confirmed.` });
      setLocation(`/orders`);
    },
    onError: () => {
      toast({ title: "Order failed", description: "Something went wrong. Please try again.", variant: "destructive" });
    },
  });

  const canSubmit = () => {
    if (!customerName.trim() || !customerPhone.trim()) return false;
    if (fulfillmentType === "delivery" && (!shippingAddress.trim() || !shippingCity.trim() || !shippingCountry.trim())) return false;
    if (fulfillmentType === "pickup" && !selectedStoreId) return false;
    return true;
  };

  if (cartLoading) {
    return (
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-10">
        <Skeleton className="h-8 w-48 mb-6" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 flex flex-col gap-4">
            <Skeleton className="h-64 rounded-lg" />
            <Skeleton className="h-48 rounded-lg" />
          </div>
          <Skeleton className="h-72 rounded-lg" />
        </div>
      </div>
    );
  }

  if (!cartItems || cartItems.length === 0) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center gap-6 px-4">
        <div className="text-center">
          <h2 className="text-2xl font-serif font-bold text-foreground mb-2">Your bag is empty</h2>
          <p className="text-muted-foreground text-sm">Add some items to your bag before checking out.</p>
        </div>
        <Link href="/shop">
          <Button size="lg">
            Continue Shopping
            <ArrowRight className="ml-2 w-4 h-4" />
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8">
        <Link href="/cart">
          <Button variant="ghost" size="sm" className="mb-6">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Bag
          </Button>
        </Link>

        <div className="mb-6">
          <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-1 block">Golden Pearl</span>
          <h1 className="text-2xl sm:text-3xl font-serif font-bold text-foreground">Checkout</h1>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left column - Form */}
          <div className="lg:col-span-2 flex flex-col gap-6">

            {/* Delivery Method Selector */}
            <div className="bg-card border border-card-border rounded-lg p-6">
              <h2 className="text-lg font-serif font-bold text-foreground mb-1">
                Delivery Method
              </h2>
              <p className="text-sm text-muted-foreground mb-4">
                طريقة التوصيل
              </p>

              <RadioGroup
                value={fulfillmentType}
                onValueChange={(val) => {
                  setFulfillmentType(val as "delivery" | "pickup");
                  if (val === "delivery") setSelectedStoreId(null);
                }}
                className="grid grid-cols-1 sm:grid-cols-2 gap-3"
              >
                <label
                  className={`flex items-center gap-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                    fulfillmentType === "delivery"
                      ? "border-primary bg-primary/5"
                      : "border-border hover:border-muted-foreground/30"
                  }`}
                >
                  <RadioGroupItem value="delivery" />
                  <div className="flex items-center gap-3 flex-1">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                      <Truck className="w-5 h-5 text-primary" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm text-foreground">Delivery</p>
                      <p className="text-xs text-muted-foreground">التوصيل</p>
                      <p className="text-xs text-muted-foreground mt-0.5">Ship to your address</p>
                    </div>
                  </div>
                </label>

                <label
                  className={`flex items-center gap-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                    fulfillmentType === "pickup"
                      ? "border-primary bg-primary/5"
                      : "border-border hover:border-muted-foreground/30"
                  }`}
                >
                  <RadioGroupItem value="pickup" />
                  <div className="flex items-center gap-3 flex-1">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                      <StoreIcon className="w-5 h-5 text-primary" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm text-foreground">Pickup from Store</p>
                      <p className="text-xs text-muted-foreground">استلام من المتجر</p>
                      <p className="text-xs text-emerald-600 dark:text-emerald-400 font-medium mt-0.5">Free — no shipping fee</p>
                    </div>
                  </div>
                </label>
              </RadioGroup>
            </div>

            {/* Store Pickup Selector */}
            {fulfillmentType === "pickup" && (
              <div className="bg-card border border-card-border rounded-lg p-6">
                <h2 className="text-lg font-serif font-bold text-foreground mb-1">
                  Choose Pickup Location
                </h2>
                <p className="text-sm text-muted-foreground mb-4">
                  اختر فرع الاستلام
                </p>

                {storesLoading ? (
                  <div className="flex flex-col gap-3">
                    {[1, 2, 3].map(i => <Skeleton key={i} className="h-28 rounded-lg" />)}
                  </div>
                ) : (
                  <RadioGroup
                    value={selectedStoreId?.toString() ?? ""}
                    onValueChange={(val) => setSelectedStoreId(parseInt(val))}
                    className="flex flex-col gap-3"
                  >
                    {storesList?.map(store => (
                      <label
                        key={store.id}
                        className={`flex items-start gap-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                          selectedStoreId === store.id
                            ? "border-primary bg-primary/5"
                            : "border-border hover:border-muted-foreground/30"
                        }`}
                      >
                        <RadioGroupItem value={store.id.toString()} className="mt-1" />
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-sm text-foreground">{store.nameEn}</p>
                          <p className="text-xs text-muted-foreground mb-2">{store.nameAr}</p>

                          <div className="flex flex-col gap-1.5">
                            <div className="flex items-start gap-2">
                              <MapPin className="w-3.5 h-3.5 text-muted-foreground mt-0.5 shrink-0" />
                              <span className="text-xs text-muted-foreground">{store.addressEn}</span>
                            </div>
                            <div className="flex items-start gap-2">
                              <Clock className="w-3.5 h-3.5 text-muted-foreground mt-0.5 shrink-0" />
                              <span className="text-xs text-muted-foreground">{store.hoursEn}</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <Phone className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                              <span className="text-xs text-muted-foreground">{store.phone}</span>
                            </div>
                            {store.mapUrl && (
                              <a
                                href={store.mapUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-1 text-xs text-primary hover:underline mt-1"
                                onClick={e => e.stopPropagation()}
                              >
                                <ExternalLink className="w-3 h-3" />
                                View on Map
                              </a>
                            )}
                          </div>
                        </div>
                      </label>
                    ))}
                  </RadioGroup>
                )}

                {selectedStore && (
                  <div className="mt-4 p-3 rounded-md bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
                    <div className="flex items-start gap-2">
                      <Info className="w-4 h-4 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
                      <div className="text-xs text-amber-800 dark:text-amber-300">
                        <p className="font-semibold mb-1">Pickup Instructions / تعليمات الاستلام:</p>
                        <ul className="list-disc list-inside space-y-0.5">
                          <li>Bring a valid ID / أحضر هوية سارية</li>
                          <li>Quote your order number / اذكر رقم الطلب</li>
                          <li>Order ready within 24 hours / الطلب جاهز خلال 24 ساعة</li>
                        </ul>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Customer Information */}
            <div className="bg-card border border-card-border rounded-lg p-6">
              <h2 className="text-lg font-serif font-bold text-foreground mb-4">
                {fulfillmentType === "pickup" ? "Your Information" : "Shipping Information"}
              </h2>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Full Name *</Label>
                  <Input
                    id="name"
                    placeholder="Enter your full name"
                    value={customerName}
                    onChange={e => setCustomerName(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone *</Label>
                  <Input
                    id="phone"
                    type="tel"
                    placeholder="+965 XXXX XXXX"
                    value={customerPhone}
                    onChange={e => setCustomerPhone(e.target.value)}
                  />
                </div>
                <div className="space-y-2 sm:col-span-2">
                  <Label htmlFor="email">Email (optional)</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="your@email.com"
                    value={customerEmail}
                    onChange={e => setCustomerEmail(e.target.value)}
                  />
                </div>

                {fulfillmentType === "delivery" && (
                  <>
                    <div className="space-y-2 sm:col-span-2">
                      <Label htmlFor="address">Shipping Address *</Label>
                      <Input
                        id="address"
                        placeholder="Street address, building, apartment"
                        value={shippingAddress}
                        onChange={e => setShippingAddress(e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="city">City *</Label>
                      <Input
                        id="city"
                        placeholder="City"
                        value={shippingCity}
                        onChange={e => setShippingCity(e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="country">Country *</Label>
                      <Input
                        id="country"
                        placeholder="Country"
                        value={shippingCountry}
                        onChange={e => setShippingCountry(e.target.value)}
                      />
                    </div>
                  </>
                )}

                <div className="space-y-2 sm:col-span-2">
                  <Label htmlFor="notes">Order Notes (optional)</Label>
                  <Input
                    id="notes"
                    placeholder="Special instructions..."
                    value={notes}
                    onChange={e => setNotes(e.target.value)}
                  />
                </div>
              </div>
            </div>

            {/* Discount Code */}
            <div className="bg-card border border-card-border rounded-lg p-6">
              <h2 className="text-lg font-serif font-bold text-foreground mb-4">Discount Code</h2>
              <div className="flex gap-3">
                <Input
                  placeholder="Enter code"
                  value={discountCode}
                  onChange={e => setDiscountCode(e.target.value)}
                  disabled={!!discountApplied}
                />
                {discountApplied ? (
                  <Button
                    variant="outline"
                    onClick={() => {
                      setDiscountApplied(null);
                      setDiscountCode("");
                    }}
                  >
                    Remove
                  </Button>
                ) : (
                  <Button
                    variant="outline"
                    onClick={() => validateDiscount.mutate()}
                    disabled={!discountCode.trim() || validateDiscount.isPending}
                  >
                    {validateDiscount.isPending ? "..." : "Apply"}
                  </Button>
                )}
              </div>
              {discountApplied && (
                <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-2">
                  {discountApplied.type === "percentage"
                    ? `${discountApplied.value}% discount applied`
                    : `${formatSAR(discountApplied.value)} discount applied`}
                </p>
              )}
            </div>
          </div>

          {/* Right column - Order Summary */}
          <div className="lg:col-span-1">
            <div className="bg-card border border-card-border rounded-lg p-6 sticky top-24">
              <h2 className="text-lg font-serif font-bold text-foreground mb-5">Order Summary</h2>

              {/* Cart items mini list */}
              <div className="flex flex-col gap-3 mb-4">
                {cartItems.map(item => (
                  <div key={item.id} className="flex items-center gap-3">
                    <div className="w-12 h-14 rounded-md overflow-hidden bg-accent/30 shrink-0">
                      <img src={item.product.images[0]} alt={item.product.nameEn} className="w-full h-full object-cover" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-foreground truncate">{item.product.nameEn}</p>
                      <p className="text-xs text-muted-foreground">{item.size} / {item.color} x{item.quantity}</p>
                    </div>
                    <span className="text-xs font-semibold text-foreground shrink-0">
                      {formatSAR(item.product.price * item.quantity)}
                    </span>
                  </div>
                ))}
              </div>

              <Separator className="my-3" />

              <div className="flex flex-col gap-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Subtotal</span>
                  <span className="font-medium text-foreground">{formatSAR(subtotal)}</span>
                </div>

                {discountAmount > 0 && (
                  <div className="flex justify-between text-sm">
                    <span className="text-emerald-600 dark:text-emerald-400">Discount</span>
                    <span className="font-medium text-emerald-600 dark:text-emerald-400">-{formatSAR(discountAmount)}</span>
                  </div>
                )}

                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">
                    Shipping
                    {fulfillmentType === "pickup" && (
                      <span className="text-xs ml-1">(Pickup)</span>
                    )}
                  </span>
                  <span className="font-medium text-foreground">
                    {fulfillmentType === "pickup" || shipping === 0 ? (
                      <span className="text-emerald-600 dark:text-emerald-400">Free</span>
                    ) : (
                      formatSAR(shipping)
                    )}
                  </span>
                </div>

                <Separator className="my-1" />

                <div className="flex justify-between font-bold text-base">
                  <span>Total</span>
                  <span>{formatSAR(total)}</span>
                </div>
              </div>

              {/* Fulfillment info in summary */}
              {fulfillmentType === "pickup" && selectedStore && (
                <>
                  <Separator className="my-3" />
                  <div className="text-xs">
                    <p className="font-semibold text-foreground mb-1">Pickup / استلام من المتجر:</p>
                    <p className="text-muted-foreground">{selectedStore.nameEn}</p>
                    <p className="text-muted-foreground">{selectedStore.addressEn}</p>
                  </div>
                </>
              )}

              <Button
                size="lg"
                className="w-full mt-6"
                onClick={() => placeOrder.mutate()}
                disabled={!canSubmit() || placeOrder.isPending}
              >
                {placeOrder.isPending ? "Placing Order..." : "Place Order"}
                {!placeOrder.isPending && <ArrowRight className="ml-2 w-4 h-4" />}
              </Button>

              <div className="flex items-center justify-center gap-1.5 mt-4 text-xs text-muted-foreground">
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>Secure & encrypted checkout</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

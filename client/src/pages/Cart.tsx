import { Link, useLocation } from "wouter";
import { ShoppingBag, Trash2, Plus, Minus, ArrowLeft, ArrowRight, Package } from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/hooks/use-toast";
import { apiRequest } from "@/lib/queryClient";
import type { CartItemWithProduct } from "@shared/schema";

export default function Cart() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [, setLocation] = useLocation();

  const { data: cartItems, isLoading } = useQuery<CartItemWithProduct[]>({
    queryKey: ["/api/cart"],
  });

  const updateItem = useMutation({
    mutationFn: ({ id, quantity }: { id: number; quantity: number }) =>
      apiRequest("PATCH", `/api/cart/${id}`, { quantity }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["/api/cart"] }),
  });

  const removeItem = useMutation({
    mutationFn: (id: number) => apiRequest("DELETE", `/api/cart/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/cart"] });
      toast({ title: "Item removed", description: "Item removed from your bag." });
    },
  });

  const clearCart = useMutation({
    mutationFn: () => apiRequest("DELETE", "/api/cart"),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/cart"] });
      toast({ title: "Bag cleared", description: "All items have been removed." });
    },
  });

  const subtotal = cartItems?.reduce((sum, item) => sum + item.product.price * item.quantity, 0) ?? 0;
  const FREE_SHIPPING_THRESHOLD = 15000;
  const SHIPPING_FEE = 1500;
  const shipping = subtotal >= FREE_SHIPPING_THRESHOLD ? 0 : SHIPPING_FEE;
  const total = subtotal + shipping;

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 flex flex-col gap-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="flex gap-4 p-4 border border-border rounded-lg">
                <Skeleton className="w-24 h-32 rounded-md shrink-0" />
                <div className="flex flex-col gap-2 flex-1">
                  <Skeleton className="h-5 w-2/3" />
                  <Skeleton className="h-4 w-1/3" />
                  <Skeleton className="h-8 w-24" />
                </div>
              </div>
            ))}
          </div>
          <Skeleton className="h-64 rounded-lg" />
        </div>
      </div>
    );
  }

  if (!cartItems || cartItems.length === 0) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center gap-6 px-4">
        <div className="w-20 h-20 rounded-full bg-accent flex items-center justify-center">
          <ShoppingBag className="w-10 h-10 text-muted-foreground" />
        </div>
        <div className="text-center">
          <h2 className="text-2xl font-serif font-bold text-foreground mb-2">Your bag is empty</h2>
          <p className="text-muted-foreground text-sm max-w-xs">
            Looks like you haven't added anything yet. Start exploring our beautiful collections.
          </p>
        </div>
        <Link href="/shop">
          <Button size="lg" data-testid="button-continue-shopping">
            Continue Shopping
            <ArrowRight className="ml-2 w-4 h-4" />
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
        <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
          <div>
            <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-1 block">Golden Pearl</span>
            <h1 className="text-2xl sm:text-3xl font-serif font-bold text-foreground" data-testid="text-cart-title">
              Shopping Bag
            </h1>
            <p className="text-muted-foreground text-sm mt-1">
              {cartItems.length} item{cartItems.length !== 1 ? "s" : ""}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/shop">
              <button
                data-testid="button-back-to-shop"
                className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-primary transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Continue Shopping
              </button>
            </Link>
            {cartItems.length > 0 && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => clearCart.mutate()}
                disabled={clearCart.isPending}
                className="text-muted-foreground"
                data-testid="button-clear-cart"
              >
                <Trash2 className="w-4 h-4 mr-1.5" />
                Clear all
              </Button>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 flex flex-col gap-4">
            {cartItems.map(item => (
              <div
                key={item.id}
                data-testid={`card-cart-item-${item.id}`}
                className="flex gap-4 p-4 bg-card border border-card-border rounded-lg"
              >
                <Link href={`/product/${item.productId}`}>
                  <div className="w-20 sm:w-28 h-28 sm:h-36 rounded-md overflow-hidden bg-accent/30 shrink-0 cursor-pointer">
                    <img
                      src={item.product.images[0]}
                      alt={item.product.nameEn}
                      className="w-full h-full object-cover"
                    />
                  </div>
                </Link>

                <div className="flex flex-col justify-between flex-1 min-w-0 gap-2">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <Link href={`/product/${item.productId}`}>
                        <h3
                          data-testid={`text-cart-item-name-${item.id}`}
                          className="font-semibold text-sm text-foreground hover:text-primary cursor-pointer transition-colors truncate"
                        >
                          {item.product.nameEn}
                        </h3>
                      </Link>
                      <div className="flex flex-wrap gap-2 mt-1">
                        <span className="text-xs text-muted-foreground bg-accent/60 px-2 py-0.5 rounded-full">
                          {item.size}
                        </span>
                        <span className="text-xs text-muted-foreground bg-accent/60 px-2 py-0.5 rounded-full">
                          {item.color}
                        </span>
                      </div>
                    </div>
                    <Button
                      size="icon"
                      variant="ghost"
                      data-testid={`button-remove-${item.id}`}
                      onClick={() => removeItem.mutate(item.id)}
                      disabled={removeItem.isPending}
                      aria-label={`Remove ${item.product.nameEn}`}
                      className="shrink-0 text-muted-foreground"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>

                  <div className="flex items-center justify-between gap-2 flex-wrap">
                    <div className="flex items-center gap-2">
                      <Button
                        size="icon"
                        variant="outline"
                        onClick={() => {
                          if (item.quantity <= 1) {
                            removeItem.mutate(item.id);
                          } else {
                            updateItem.mutate({ id: item.id, quantity: item.quantity - 1 });
                          }
                        }}
                        disabled={updateItem.isPending}
                        data-testid={`button-decrease-${item.id}`}
                        aria-label="Decrease quantity"
                      >
                        <Minus className="w-3 h-3" />
                      </Button>
                      <span
                        data-testid={`text-quantity-${item.id}`}
                        className="text-sm font-semibold w-6 text-center"
                      >
                        {item.quantity}
                      </span>
                      <Button
                        size="icon"
                        variant="outline"
                        onClick={() => updateItem.mutate({ id: item.id, quantity: item.quantity + 1 })}
                        disabled={updateItem.isPending}
                        data-testid={`button-increase-${item.id}`}
                        aria-label="Increase quantity"
                      >
                        <Plus className="w-3 h-3" />
                      </Button>
                    </div>
                    <div className="flex flex-col items-end">
                      <span
                        data-testid={`text-item-price-${item.id}`}
                        className="font-bold text-foreground"
                      >
                        ${(item.product.price * item.quantity / 100).toFixed(2)}
                      </span>
                      {item.quantity > 1 && (
                        <span className="text-xs text-muted-foreground">
                          ${(item.product.price / 100).toFixed(2)} each
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="lg:col-span-1">
            <div className="bg-card border border-card-border rounded-lg p-6 sticky top-24">
              <h2 className="text-lg font-serif font-bold text-foreground mb-5">Order Summary</h2>

              <div className="flex flex-col gap-3">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Subtotal ({cartItems.length} items)</span>
                  <span className="font-medium text-foreground" data-testid="text-subtotal">${(subtotal / 100).toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Shipping</span>
                  <span className="font-medium text-foreground" data-testid="text-shipping">
                    {shipping === 0 ? (
                      <span className="text-emerald-600 dark:text-emerald-400">Free</span>
                    ) : (
                      `$${(shipping / 100).toFixed(2)}`
                    )}
                  </span>
                </div>
                {subtotal < FREE_SHIPPING_THRESHOLD && (
                  <p className="text-xs text-muted-foreground bg-accent/40 rounded-md px-3 py-2">
                    Add ${((FREE_SHIPPING_THRESHOLD - subtotal) / 100).toFixed(2)} more for free shipping
                  </p>
                )}

                <Separator className="my-1" />

                <div className="flex justify-between font-bold text-base">
                  <span>Total</span>
                  <span data-testid="text-total">${(total / 100).toFixed(2)}</span>
                </div>
              </div>

              <Button
                size="lg"
                className="w-full mt-6"
                data-testid="button-checkout"
                onClick={() => setLocation("/checkout")}
              >
                Proceed to Checkout
                <ArrowRight className="ml-2 w-4 h-4" />
              </Button>

              <div className="flex items-center justify-center gap-1.5 mt-4 text-xs text-muted-foreground">
                <Package className="w-3.5 h-3.5" />
                <span>Secure & encrypted checkout</span>
              </div>

              <Separator className="my-4" />

              <div className="text-xs text-muted-foreground text-center leading-relaxed">
                Free returns within 30 days. See our{" "}
                <span className="text-primary cursor-pointer hover:underline">return policy</span>.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

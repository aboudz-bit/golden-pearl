import { useState, useEffect } from "react";
import { useRoute, Link } from "wouter";
import { ArrowLeft, Star, ShoppingBag, Heart, Truck, RotateCcw, ShieldCheck, Minus, Plus } from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import { apiRequest } from "@/lib/queryClient";
import type { Product } from "@shared/schema";
import { ProductCard } from "@/components/ProductCard";
import { formatSAR } from "@/lib/utils";

const badgeVariantMap: Record<string, string> = {
  Sale: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300",
  New: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300",
  Bestseller: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300",
  Exclusive: "bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-300",
  Popular: "bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300",
  Gift: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300",
  Luxury: "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300",
  Eid: "bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300",
};

export default function ProductDetail() {
  const [, params] = useRoute("/product/:id");
  const id = params?.id ?? "";
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [selectedSize, setSelectedSize] = useState<string>("");
  const [selectedColor, setSelectedColor] = useState<string>("");
  const [quantity, setQuantity] = useState(1);

  const { data: product, isLoading } = useQuery<Product>({
    queryKey: ["/api/products", id],
    queryFn: () => fetch(`/api/products/${id}`).then(r => r.json()),
    enabled: !!id,
  });

  const { data: allProducts } = useQuery<Product[]>({
    queryKey: ["/api/products"],
  });

  const related = allProducts?.filter(p => String(p.id) !== id && p.category === product?.category).slice(0, 4) ?? [];

  useEffect(() => {
    if (product) {
      if (product.sizes.length > 0) setSelectedSize(product.sizes[0]);
      if (product.colors.length > 0) setSelectedColor(product.colors[0]);
      setQuantity(1);
    }
  }, [product?.id]);

  const addToCart = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/cart", {
        productId: id,
        quantity,
        size: selectedSize || product?.sizes[0],
        color: selectedColor || product?.colors[0],
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/cart"] });
      toast({ title: "Added to bag", description: `${product?.nameEn} added to your bag.` });
    },
  });

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          <Skeleton className="aspect-[3/4] rounded-lg" />
          <div className="flex flex-col gap-4">
            <Skeleton className="h-8 w-2/3" />
            <Skeleton className="h-6 w-1/3" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-4/5" />
            <Skeleton className="h-12 w-full" />
          </div>
        </div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center gap-4">
        <h2 className="text-xl font-semibold">Product not found</h2>
        <Link href="/shop">
          <Button variant="outline" data-testid="button-back-to-shop">Back to Shop</Button>
        </Link>
      </div>
    );
  }

  const discount = product.originalPrice
    ? Math.round((1 - product.price / product.originalPrice) * 100)
    : null;

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        <Link href="/shop">
          <Button variant="ghost" size="sm" data-testid="button-back" className="mb-6">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Collection
          </Button>
        </Link>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 xl:gap-16">
          <div className="relative">
            <div className="aspect-[3/4] rounded-lg overflow-hidden bg-accent/20">
              <img
                src={product.images[0]}
                alt={product.nameEn}
                className="w-full h-full object-cover"
                data-testid="img-product-detail"
              />
            </div>
            {product.badge && (
              <span className={`absolute top-4 left-4 text-xs font-semibold px-2.5 py-1 rounded-md ${badgeVariantMap[product.badge] ?? "bg-primary/10 text-primary"}`}>
                {product.badge}
              </span>
            )}
            {discount && (
              <span className="absolute top-4 right-4 bg-destructive text-destructive-foreground text-xs font-bold px-2 py-1 rounded-md">
                -{discount}%
              </span>
            )}
          </div>

          <div className="flex flex-col gap-5">
            <div>
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-[0.15em] capitalize">
                {product.category} / {product.subcategory?.replace(/-/g, " ")}
              </span>
              <h1
                data-testid="text-product-detail-name"
                className="text-2xl sm:text-3xl font-serif font-bold text-foreground mt-1.5 leading-tight"
              >
                {product.nameEn}
              </h1>
              <div className="flex items-center gap-2 mt-2">
                <div className="flex gap-0.5">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      className={`w-4 h-4 ${i < Math.floor(product.rating) ? "fill-amber-400 text-amber-400" : "text-muted fill-muted"}`}
                    />
                  ))}
                </div>
                <span className="text-sm font-medium text-foreground">{product.rating}</span>
                <span className="text-sm text-muted-foreground">({product.reviewCount} reviews)</span>
              </div>
            </div>

            <div className="flex items-baseline gap-3">
              <span
                data-testid="text-detail-price"
                className="text-3xl font-bold text-foreground"
              >
                {formatSAR(product.price)}
              </span>
              {product.originalPrice && (
                <span className="text-lg text-muted-foreground line-through">
                  {formatSAR(product.originalPrice)}
                </span>
              )}
              {discount && (
                <span className="text-sm font-semibold text-destructive">Save {discount}%</span>
              )}
            </div>

            <p className="text-muted-foreground leading-relaxed text-sm" data-testid="text-detail-description">
              {product.descriptionEn}
            </p>

            {product.fabricEn && (
              <div className="text-sm">
                <span className="font-semibold text-foreground">Fabric: </span>
                <span className="text-muted-foreground">{product.fabricEn}</span>
              </div>
            )}

            <div className="border-t border-border pt-5 flex flex-col gap-5">
              <div>
                <p className="text-sm font-semibold text-foreground mb-3">
                  Size: <span className="font-normal text-muted-foreground">{selectedSize}</span>
                </p>
                <div className="flex flex-wrap gap-2">
                  {product.sizes.map(size => (
                    <Button
                      key={size}
                      variant={selectedSize === size ? "default" : "outline"}
                      size="sm"
                      data-testid={`button-size-${size.replace(/\s/g, "-")}`}
                      onClick={() => setSelectedSize(size)}
                    >
                      {size}
                    </Button>
                  ))}
                </div>
              </div>

              <div>
                <p className="text-sm font-semibold text-foreground mb-3">
                  Color: <span className="font-normal text-muted-foreground">{selectedColor}</span>
                </p>
                <div className="flex flex-wrap gap-2">
                  {product.colors.map(color => (
                    <Button
                      key={color}
                      variant={selectedColor === color ? "default" : "outline"}
                      size="sm"
                      data-testid={`button-color-${color.replace(/\s/g, "-")}`}
                      onClick={() => setSelectedColor(color)}
                    >
                      {color}
                    </Button>
                  ))}
                </div>
              </div>

              <div>
                <p className="text-sm font-semibold text-foreground mb-3">Quantity</p>
                <div className="flex items-center gap-3">
                  <Button
                    size="icon"
                    variant="outline"
                    onClick={() => setQuantity(q => Math.max(1, q - 1))}
                    disabled={quantity <= 1}
                    data-testid="button-quantity-decrease"
                    aria-label="Decrease quantity"
                  >
                    <Minus className="w-4 h-4" />
                  </Button>
                  <span data-testid="text-quantity" className="text-base font-semibold w-8 text-center">{quantity}</span>
                  <Button
                    size="icon"
                    variant="outline"
                    onClick={() => setQuantity(q => q + 1)}
                    data-testid="button-quantity-increase"
                    aria-label="Increase quantity"
                  >
                    <Plus className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            </div>

            <div className="flex gap-3 flex-wrap">
              <Button
                size="lg"
                className="flex-1 min-w-40"
                onClick={() => addToCart.mutate()}
                disabled={!product.inStock || addToCart.isPending}
                data-testid="button-add-to-bag"
              >
                <ShoppingBag className="mr-2 w-4 h-4" />
                {addToCart.isPending ? "Adding..." : "Add to Bag"}
              </Button>
              <Button
                size="lg"
                variant="outline"
                data-testid="button-wishlist-detail"
                aria-label="Add to wishlist"
              >
                <Heart className="w-4 h-4" />
              </Button>
            </div>

            <div className="grid grid-cols-3 gap-3 pt-2">
              {[
                { icon: Truck, text: "Worldwide shipping" },
                { icon: RotateCcw, text: "30-day returns" },
                { icon: ShieldCheck, text: "Secure checkout" },
              ].map(item => (
                <div key={item.text} className="flex flex-col items-center text-center gap-1.5 p-3 rounded-md bg-accent/40">
                  <item.icon className="w-4 h-4 text-primary" />
                  <span className="text-xs text-muted-foreground leading-tight">{item.text}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {related.length > 0 && (
          <section className="mt-16">
            <h2 className="text-2xl font-serif font-bold text-foreground mb-6">You May Also Like</h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6">
              {related.map(p => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}

import { Link } from "wouter";
import { Heart, Star, ShoppingBag } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { Product } from "@shared/schema";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

interface ProductCardProps {
  product: Product;
}

const badgeVariantMap: Record<string, string> = {
  Sale: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300",
  New: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300",
  Bestseller: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300",
  Organic: "bg-lime-100 dark:bg-lime-900/30 text-lime-700 dark:text-lime-300",
  Gift: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300",
  Luxury: "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300",
  Exclusive: "bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-300",
  Popular: "bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300",
  Eid: "bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300",
};

export function ProductCard({ product }: ProductCardProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const addToCart = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/cart", {
        productId: product.id,
        quantity: 1,
        size: product.sizes[0],
        color: product.colors[0],
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/cart"] });
      toast({ title: "Added to bag", description: `${product.nameEn} has been added to your bag.` });
    },
  });

  return (
    <div
      data-testid={`card-product-${product.id}`}
      className="group relative flex flex-col bg-card border border-card-border rounded-lg overflow-visible hover-elevate"
    >
      <Link href={`/product/${product.id}`}>
        <div className="relative aspect-[3/4] overflow-hidden rounded-t-lg cursor-pointer bg-accent/30">
          <img
            src={product.images[0]}
            alt={product.nameEn}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
            data-testid={`img-product-${product.id}`}
          />
          <button
            data-testid={`button-wishlist-${product.id}`}
            className="absolute top-3 right-3 p-2 bg-background/80 backdrop-blur-sm rounded-full opacity-0 group-hover:opacity-100 transition-all duration-200 hover:bg-background"
            onClick={e => { e.preventDefault(); }}
          >
            <Heart className="w-4 h-4 text-foreground" />
          </button>
          {product.badge && (
            <span className={`absolute top-3 left-3 text-xs font-semibold px-2 py-1 rounded-md ${badgeVariantMap[product.badge] ?? "bg-primary/10 text-primary"}`}>
              {product.badge}
            </span>
          )}
          {!product.inStock && (
            <div className="absolute inset-0 bg-background/60 flex items-center justify-center">
              <span className="text-sm font-semibold text-muted-foreground">Out of Stock</span>
            </div>
          )}
        </div>
      </Link>

      <div className="flex flex-col gap-2 p-4">
        <div className="flex items-start justify-between gap-2">
          <Link href={`/product/${product.id}`}>
            <h3
              data-testid={`text-product-name-${product.id}`}
              className="font-semibold text-sm text-foreground leading-snug cursor-pointer hover:text-primary transition-colors line-clamp-2"
            >
              {product.nameEn}
            </h3>
          </Link>
        </div>

        <div className="flex items-center gap-1">
          <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
          <span className="text-xs text-muted-foreground font-medium">{product.rating}</span>
          <span className="text-xs text-muted-foreground">({product.reviewCount})</span>
        </div>

        <div className="flex items-center justify-between gap-2 mt-auto">
          <div className="flex items-baseline gap-1.5 flex-wrap">
            <span
              data-testid={`text-product-price-${product.id}`}
              className="text-base font-bold text-foreground"
            >
              ${(product.price / 100).toFixed(2)}
            </span>
            {product.originalPrice && (
              <span className="text-sm text-muted-foreground line-through">
                ${(product.originalPrice / 100).toFixed(2)}
              </span>
            )}
          </div>
          <Button
            size="icon"
            variant="default"
            onClick={() => addToCart.mutate()}
            disabled={!product.inStock || addToCart.isPending}
            data-testid={`button-add-to-cart-${product.id}`}
            className="shrink-0"
          >
            <ShoppingBag className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}

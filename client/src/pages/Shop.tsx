import { useState, useEffect } from "react";
import { Link, useLocation, useSearch } from "wouter";
import { SlidersHorizontal, X } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { ProductCard } from "@/components/ProductCard";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import type { Product } from "@shared/schema";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const CATEGORIES = [
  { value: "all", label: "All" },
  { value: "dresses", label: "Dresses" },
  { value: "jalabiyas", label: "Jalabiyas" },
  { value: "kids", label: "Kids" },
  { value: "gifts", label: "Gifts" },
];

const SORT_OPTIONS = [
  { value: "default", label: "Featured" },
  { value: "price-asc", label: "Price: Low to High" },
  { value: "price-desc", label: "Price: High to Low" },
  { value: "rating", label: "Highest Rated" },
  { value: "name", label: "Alphabetical" },
];

export default function Shop() {
  const [location, setLocation] = useLocation();
  const searchString = useSearch();
  const params = new URLSearchParams(searchString);
  const categoryParam = params.get("category") ?? "all";
  const searchParam = params.get("search") ?? "";

  const [selectedCategory, setSelectedCategory] = useState(categoryParam);
  const [sortBy, setSortBy] = useState("default");
  const [priceRange, setPriceRange] = useState<"all" | "under100" | "100-250" | "over250">("all");

  useEffect(() => {
    setSelectedCategory(categoryParam);
  }, [categoryParam]);

  const queryUrl = searchParam
    ? `/api/products?search=${encodeURIComponent(searchParam)}`
    : selectedCategory && selectedCategory !== "all"
    ? `/api/products?category=${selectedCategory}`
    : "/api/products";

  const { data: products, isLoading } = useQuery<Product[]>({
    queryKey: [queryUrl],
  });

  const filtered = (products ?? [])
    .filter(p => {
      const dollars = p.price / 100;
      if (priceRange === "under100") return dollars < 100;
      if (priceRange === "100-250") return dollars >= 100 && dollars <= 250;
      if (priceRange === "over250") return dollars > 250;
      return true;
    })
    .sort((a, b) => {
      if (sortBy === "price-asc") return a.price - b.price;
      if (sortBy === "price-desc") return b.price - a.price;
      if (sortBy === "rating") return b.rating - a.rating;
      if (sortBy === "name") return a.nameEn.localeCompare(b.nameEn);
      return 0;
    });

  const handleCategoryChange = (val: string) => {
    setSelectedCategory(val);
    if (val === "all") {
      setLocation("/shop");
    } else {
      setLocation(`/shop?category=${val}`);
    }
  };

  const categoryLabels: Record<string, string> = {
    all: "All Products",
    dresses: "Dresses Collection",
    jalabiyas: "Jalabiyas Collection",
    kids: "Kids Collection",
    gifts: "Gift Packaging",
  };

  const pageTitle = searchParam
    ? `Search: "${searchParam}"`
    : categoryLabels[selectedCategory] ?? "All Products";

  return (
    <div className="min-h-screen">
      <div className="bg-card border-b border-card-border py-8 px-4 sm:px-6">
        <div className="max-w-7xl mx-auto">
          <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-1 block">Golden Pearl</span>
          <h1 className="text-3xl font-serif font-bold text-foreground mb-1" data-testid="text-shop-title">
            {pageTitle}
          </h1>
          <p className="text-muted-foreground text-sm">
            {isLoading ? "Loading..." : `${filtered.length} item${filtered.length !== 1 ? "s" : ""}`}
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="flex items-center gap-2 flex-wrap flex-1">
            <SlidersHorizontal className="w-4 h-4 text-muted-foreground shrink-0" />
            <div className="flex flex-wrap gap-2">
              {CATEGORIES.map(cat => (
                <Button
                  key={cat.value}
                  variant={selectedCategory === cat.value ? "default" : "outline"}
                  size="sm"
                  data-testid={`button-filter-${cat.value}`}
                  onClick={() => handleCategoryChange(cat.value)}
                  className="rounded-full"
                >
                  {cat.label}
                </Button>
              ))}
            </div>
          </div>

          <div className="flex items-center gap-3 shrink-0 flex-wrap">
            <Select value={priceRange} onValueChange={(v) => setPriceRange(v as typeof priceRange)}>
              <SelectTrigger className="w-40" data-testid="select-price-range">
                <SelectValue placeholder="Price Range" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Prices</SelectItem>
                <SelectItem value="under100">Under $100</SelectItem>
                <SelectItem value="100-250">$100 - $250</SelectItem>
                <SelectItem value="over250">Over $250</SelectItem>
              </SelectContent>
            </Select>

            <Select value={sortBy} onValueChange={setSortBy}>
              <SelectTrigger className="w-44" data-testid="select-sort">
                <SelectValue placeholder="Sort By" />
              </SelectTrigger>
              <SelectContent>
                {SORT_OPTIONS.map(opt => (
                  <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        {searchParam && (
          <div className="flex items-center gap-2 mb-6">
            <span className="text-sm text-muted-foreground">Showing results for:</span>
            <Badge variant="secondary" className="flex items-center gap-1">
              {searchParam}
              <Link href="/shop">
                <X className="w-3 h-3 ml-1 cursor-pointer" data-testid="button-clear-search" />
              </Link>
            </Badge>
          </div>
        )}

        {isLoading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="flex flex-col gap-3">
                <Skeleton className="aspect-[3/4] rounded-lg" />
                <Skeleton className="h-4 w-3/4" />
                <Skeleton className="h-4 w-1/2" />
                <Skeleton className="h-8 w-full" />
              </div>
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center gap-4">
            <div className="w-16 h-16 rounded-full bg-accent flex items-center justify-center">
              <SlidersHorizontal className="w-8 h-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground">No products found</h3>
            <p className="text-muted-foreground max-w-sm text-sm">
              Try adjusting your filters or search terms to find what you're looking for.
            </p>
            <Button variant="outline" onClick={() => { handleCategoryChange("all"); setPriceRange("all"); }} data-testid="button-clear-filters">
              Clear Filters
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6" data-testid="grid-products">
            {filtered.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

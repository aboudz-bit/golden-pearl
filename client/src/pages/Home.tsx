import { Link } from "wouter";
import { ArrowRight, Gift, Sparkles, Truck, RefreshCw, Shield, Star, Crown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useQuery } from "@tanstack/react-query";
import { ProductCard } from "@/components/ProductCard";
import { Skeleton } from "@/components/ui/skeleton";
import type { Product } from "@shared/schema";

const categories = [
  {
    id: "dresses",
    label: "Dresses",
    description: "Elegant embroidered evening gowns",
    image: "/images/category-dresses.png",
    href: "/shop?category=dresses",
    testId: "card-category-dresses",
  },
  {
    id: "jalabiyas",
    label: "Jalabiyas",
    description: "Luxury traditional wear with modern flair",
    image: "/images/category-jalabiyas.png",
    href: "/shop?category=jalabiyas",
    testId: "card-category-jalabiyas",
  },
  {
    id: "kids",
    label: "Kids Collection",
    description: "Adorable styles for little ones",
    image: "/images/category-kids.png",
    href: "/shop?category=kids",
    testId: "card-category-kids",
  },
  {
    id: "gifts",
    label: "Gift Packaging",
    description: "Luxury gift sets for every occasion",
    image: "/images/category-gifts.png",
    href: "/shop?category=gifts",
    testId: "card-category-gifts",
  },
];

const perks = [
  { icon: Truck, title: "Worldwide Shipping", desc: "Delivered to your door" },
  { icon: RefreshCw, title: "Easy Returns", desc: "30-day return policy" },
  { icon: Shield, title: "Secure Payment", desc: "100% protected" },
  { icon: Crown, title: "Premium Quality", desc: "Handcrafted with care" },
];

const testimonials = [
  {
    name: "Fatima A.",
    text: "The embroidery is absolutely stunning. I wore the Royal Maroon Gown to my sister's wedding and received so many compliments. Exceptional quality.",
    stars: 5,
    product: "Royal Maroon Embroidered Gown",
  },
  {
    name: "Sarah K.",
    text: "Ordered the gift set for a friend's baby shower. The packaging was so elegant she didn't want to open it! The attention to detail is remarkable.",
    stars: 5,
    product: "Golden Pearl Luxury Gift Set",
  },
  {
    name: "Amina R.",
    text: "My daughter looked like a princess in her party dress! The fabric is so soft and the gold accents are just beautiful. Will definitely order again.",
    stars: 5,
    product: "Little Princess Party Dress",
  },
];

export default function Home() {
  const { data: featured, isLoading } = useQuery<Product[]>({
    queryKey: ["/api/products", { featured: true }],
    queryFn: () => fetch("/api/products?featured=true").then(r => r.json()),
  });

  return (
    <div className="min-h-screen">
      <section className="relative h-[75vh] min-h-[500px] overflow-hidden">
        <img
          src="/images/hero.png"
          alt="Golden Pearl collection"
          className="absolute inset-0 w-full h-full object-cover"
          data-testid="img-hero"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-black/65 via-black/35 to-transparent" />
        <div className="relative z-10 h-full flex items-center">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 w-full">
            <div className="max-w-lg">
              <span className="inline-block text-amber-300/90 text-sm font-medium tracking-[0.25em] uppercase mb-4">
                New Collection 2026
              </span>
              <h1
                data-testid="text-hero-title"
                className="text-4xl sm:text-5xl md:text-6xl font-serif font-bold text-white leading-tight mb-4"
              >
                Elegance
                <br />
                Redefined
              </h1>
              <p className="text-white/80 text-base sm:text-lg mb-8 leading-relaxed">
                Discover our curated collection of luxury dresses, jalabiyas, and kids' fashion — handcrafted with the finest embroidery and fabrics.
              </p>
              <div className="flex flex-wrap gap-3">
                <Link href="/shop">
                  <Button size="lg" data-testid="button-hero-shop">
                    Explore Collection
                    <ArrowRight className="ml-2 w-4 h-4" />
                  </Button>
                </Link>
                <Link href="/shop?category=gifts">
                  <Button size="lg" variant="outline" className="bg-white/10 border-white/40 text-white backdrop-blur-sm" data-testid="button-hero-gifts">
                    Gift Sets
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="py-16 px-4 sm:px-6 max-w-7xl mx-auto">
        <div className="text-center mb-10">
          <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-2 block">Our Collections</span>
          <h2 className="text-3xl font-serif font-bold text-foreground mb-3" data-testid="text-categories-title">
            Shop by Category
          </h2>
          <p className="text-muted-foreground max-w-md mx-auto">
            Every piece handcrafted with meticulous attention to detail
          </p>
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {categories.map(cat => (
            <Link href={cat.href} key={cat.id}>
              <div
                data-testid={cat.testId}
                className="group relative aspect-[3/4] overflow-hidden rounded-lg cursor-pointer hover-elevate"
              >
                <img
                  src={cat.image}
                  alt={cat.label}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                <div className="absolute bottom-0 left-0 right-0 p-4 sm:p-5">
                  <h3 className="text-white font-serif font-bold text-lg sm:text-xl">{cat.label}</h3>
                  <p className="text-white/70 text-xs sm:text-sm mt-0.5">{cat.description}</p>
                  <span className="inline-flex items-center gap-1 mt-2 text-white/90 text-sm font-medium group-hover:gap-2 transition-all">
                    Shop <ArrowRight className="w-3.5 h-3.5" />
                  </span>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </section>

      <section className="py-16 px-4 sm:px-6 bg-card border-y border-card-border">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-10">
            <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-2 block">Curated For You</span>
            <h2 className="text-3xl font-serif font-bold text-foreground mb-3" data-testid="text-featured-title">
              Featured Pieces
            </h2>
            <p className="text-muted-foreground max-w-md mx-auto">
              Our most loved designs, chosen by the Golden Pearl community
            </p>
          </div>
          {isLoading ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 sm:gap-6">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="flex flex-col gap-3">
                  <Skeleton className="aspect-[3/4] rounded-lg" />
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-4 w-1/2" />
                </div>
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 sm:gap-6">
              {featured?.map(product => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}
          <div className="text-center mt-10">
            <Link href="/shop">
              <Button variant="outline" size="lg" data-testid="button-view-all">
                View All Products
                <ArrowRight className="ml-2 w-4 h-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      <section className="py-16 px-4 sm:px-6">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 sm:gap-6">
            {perks.map(perk => (
              <div key={perk.title} className="flex flex-col items-center text-center gap-3 p-5 sm:p-6 rounded-lg bg-card border border-card-border">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                  <perk.icon className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <h4 className="font-semibold text-sm text-foreground">{perk.title}</h4>
                  <p className="text-xs text-muted-foreground mt-0.5">{perk.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-16 px-4 sm:px-6 bg-accent/30">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-10">
            <span className="text-xs font-medium tracking-[0.2em] uppercase text-primary mb-2 block">Testimonials</span>
            <h2 className="text-3xl font-serif font-bold text-foreground mb-3">
              What Our Clients Say
            </h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            {testimonials.map((t, i) => (
              <div key={i} className="bg-card border border-card-border rounded-lg p-6 flex flex-col gap-4">
                <div className="flex gap-0.5">
                  {Array.from({ length: t.stars }).map((_, j) => (
                    <Star key={j} className="w-4 h-4 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <p className="text-sm text-foreground leading-relaxed italic">"{t.text}"</p>
                <div className="mt-auto">
                  <p className="font-semibold text-sm text-foreground">{t.name}</p>
                  <p className="text-xs text-muted-foreground">{t.product}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-20 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full mb-6">
            <Gift className="w-3.5 h-3.5" />
            Perfect for every occasion
          </div>
          <h2 className="text-3xl sm:text-4xl font-serif font-bold text-foreground mb-4">
            The Art of Gifting
          </h2>
          <p className="text-muted-foreground mb-8 leading-relaxed">
            Our luxury gift sets are beautifully curated and presented in signature Golden Pearl packaging. Whether it's Eid, a wedding, or a new baby celebration — make every moment unforgettable.
          </p>
          <Link href="/shop?category=gifts">
            <Button size="lg" data-testid="button-shop-gifts">
              Explore Gift Sets
              <ArrowRight className="ml-2 w-4 h-4" />
            </Button>
          </Link>
        </div>
      </section>
    </div>
  );
}

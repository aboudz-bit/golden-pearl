import { useState } from "react";
import { Link, useLocation } from "wouter";
import { ShoppingBag, Search, Menu, X, Heart } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useQuery } from "@tanstack/react-query";
import type { CartItemWithProduct } from "@shared/schema";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";

const navLinks = [
  { label: "Home", href: "/" },
  { label: "Dresses", href: "/shop?category=dresses" },
  { label: "Jalabiyas", href: "/shop?category=jalabiyas" },
  { label: "Kids", href: "/shop?category=kids" },
  { label: "Gifts", href: "/shop?category=gifts" },
  { label: "All", href: "/shop" },
];

export function Navbar() {
  const [location, setLocation] = useLocation();
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [mobileOpen, setMobileOpen] = useState(false);

  const { data: cartItems } = useQuery<CartItemWithProduct[]>({
    queryKey: ["/api/cart"],
  });

  const cartCount = cartItems?.reduce((sum, item) => sum + item.quantity, 0) ?? 0;

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      setLocation(`/shop?search=${encodeURIComponent(searchQuery.trim())}`);
      setSearchOpen(false);
      setSearchQuery("");
    }
  };

  return (
    <header className="sticky top-0 z-50 bg-background/95 backdrop-blur-sm border-b border-border">
      <div className="max-w-7xl mx-auto px-4 sm:px-6">
        <div className="flex items-center justify-between h-16 gap-4">
          <div className="flex items-center gap-8">
            <Link href="/" data-testid="link-logo">
              <span className="text-xl sm:text-2xl font-serif font-bold tracking-wide cursor-pointer select-none">
                <span className="text-primary">Golden</span>{" "}
                <span className="text-foreground">Pearl</span>
              </span>
            </Link>
            <nav className="hidden lg:flex items-center gap-1">
              {navLinks.map(link => (
                <Link key={link.href} href={link.href}>
                  <span
                    data-testid={`link-nav-${link.label.toLowerCase()}`}
                    className={`px-3 py-1.5 text-sm font-medium rounded-md cursor-pointer transition-colors ${
                      location === link.href
                        ? "text-primary"
                        : "text-muted-foreground"
                    }`}
                  >
                    {link.label}
                  </span>
                </Link>
              ))}
            </nav>
          </div>

          <div className="flex items-center gap-2">
            {searchOpen ? (
              <form onSubmit={handleSearch} className="flex items-center gap-2">
                <Input
                  data-testid="input-search"
                  type="search"
                  placeholder="Search collections..."
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                  className="w-48 sm:w-64"
                  autoFocus
                />
                <Button type="submit" size="icon" variant="ghost" data-testid="button-search-submit" aria-label="Submit search">
                  <Search className="w-4 h-4" />
                </Button>
                <Button type="button" size="icon" variant="ghost" onClick={() => setSearchOpen(false)} data-testid="button-search-close" aria-label="Close search">
                  <X className="w-4 h-4" />
                </Button>
              </form>
            ) : (
              <Button size="icon" variant="ghost" onClick={() => setSearchOpen(true)} data-testid="button-search-open" aria-label="Open search">
                <Search className="w-4 h-4" />
              </Button>
            )}

            <Button size="icon" variant="ghost" data-testid="button-wishlist" aria-label="Wishlist">
              <Heart className="w-4 h-4" />
            </Button>

            <Link href="/cart" data-testid="link-cart">
              <Button size="icon" variant="ghost" className="relative" data-testid="button-cart" aria-label="Shopping bag">
                <ShoppingBag className="w-4 h-4" />
                {cartCount > 0 && (
                  <span
                    data-testid="text-cart-count"
                    className="absolute -top-1 -right-1 bg-primary text-primary-foreground text-xs font-bold rounded-full h-4 w-4 flex items-center justify-center"
                  >
                    {cartCount}
                  </span>
                )}
              </Button>
            </Link>

            <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
              <SheetTrigger asChild>
                <Button size="icon" variant="ghost" className="lg:hidden" data-testid="button-mobile-menu" aria-label="Open menu">
                  <Menu className="w-4 h-4" />
                </Button>
              </SheetTrigger>
              <SheetContent side="right" className="w-72">
                <div className="flex flex-col gap-6 pt-8">
                  <span className="text-xl font-serif font-bold">
                    <span className="text-primary">Golden</span>{" "}
                    <span className="text-foreground">Pearl</span>
                  </span>
                  <nav className="flex flex-col gap-1">
                    {navLinks.map(link => (
                      <Link key={link.href} href={link.href}>
                        <span
                          data-testid={`link-mobile-${link.label.toLowerCase()}`}
                          onClick={() => setMobileOpen(false)}
                          className="block px-3 py-3 text-base font-medium rounded-md cursor-pointer text-foreground"
                        >
                          {link.label}
                        </span>
                      </Link>
                    ))}
                  </nav>
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </div>
    </header>
  );
}

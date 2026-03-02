import { Link } from "wouter";
import { Heart, Instagram, Facebook, Twitter } from "lucide-react";

export function Footer() {
  return (
    <footer className="bg-card border-t border-card-border mt-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="md:col-span-1">
            <span className="text-xl font-serif font-bold">
              <span className="text-primary">Golden</span>{" "}
              <span className="text-foreground">Pearl</span>
            </span>
            <p className="mt-3 text-sm text-muted-foreground leading-relaxed">
              Premium fashion house specializing in luxury dresses, jalabiyas, and kids' collections. Worldwide shipping.
            </p>
            <div className="flex items-center gap-3 mt-4">
              <a href="#" data-testid="link-instagram" className="text-muted-foreground hover:text-primary transition-colors">
                <Instagram className="w-5 h-5" />
              </a>
              <a href="#" data-testid="link-facebook" className="text-muted-foreground hover:text-primary transition-colors">
                <Facebook className="w-5 h-5" />
              </a>
              <a href="#" data-testid="link-twitter" className="text-muted-foreground hover:text-primary transition-colors">
                <Twitter className="w-5 h-5" />
              </a>
            </div>
          </div>

          <div>
            <h4 className="font-semibold text-sm text-foreground mb-4 tracking-wide uppercase">Collections</h4>
            <ul className="space-y-2">
              {[
                { label: "Dresses", href: "/shop?category=dresses" },
                { label: "Jalabiyas", href: "/shop?category=jalabiyas" },
                { label: "Kids Dresses", href: "/shop?category=kids" },
                { label: "Gift Packaging", href: "/shop?category=gifts" },
                { label: "New Arrivals", href: "/shop" },
              ].map(link => (
                <li key={link.label}>
                  <Link href={link.href}>
                    <span className="text-sm text-muted-foreground hover:text-primary cursor-pointer transition-colors">
                      {link.label}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-sm text-foreground mb-4 tracking-wide uppercase">Customer Care</h4>
            <ul className="space-y-2">
              {["Size Guide", "Shipping & Delivery", "Returns & Exchanges", "Contact Us", "Track Order"].map(item => (
                <li key={item}>
                  <span className="text-sm text-muted-foreground hover:text-primary cursor-pointer transition-colors">
                    {item}
                  </span>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-sm text-foreground mb-4 tracking-wide uppercase">Stay Connected</h4>
            <p className="text-sm text-muted-foreground mb-3">
              Subscribe for exclusive access to new collections and special offers.
            </p>
            <form className="flex flex-col gap-2" onSubmit={e => e.preventDefault()}>
              <input
                data-testid="input-newsletter-email"
                type="email"
                placeholder="Your email address"
                className="w-full px-3 py-2 text-sm rounded-md border border-input bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
              <button
                data-testid="button-newsletter-subscribe"
                type="submit"
                className="w-full px-4 py-2 bg-primary text-primary-foreground text-sm font-medium rounded-md hover:opacity-90 transition-opacity"
              >
                Subscribe
              </button>
            </form>
          </div>
        </div>

        <div className="border-t border-border mt-10 pt-6 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p className="text-xs text-muted-foreground flex items-center gap-1">
            Crafted with <Heart className="w-3 h-3 text-primary" /> Golden Pearl Fashion House
          </p>
          <p className="text-xs text-muted-foreground">
            &copy; {new Date().getFullYear()} Golden Pearl. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}

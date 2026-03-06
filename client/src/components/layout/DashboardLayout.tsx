import { useState } from "react";
import { Link, useLocation } from "wouter";
import { useAuth } from "../../hooks/use-auth";
import {
  LayoutDashboard, Building2, Users, Package, Image, Sparkles,
  Send, BarChart3, Settings, LogOut, Menu, X, ChevronDown, Eye
} from "lucide-react";

const navItems = [
  { path: "/dashboard", label: "Overview", icon: LayoutDashboard },
  { path: "/dashboard/companies", label: "Companies", icon: Building2 },
  { path: "/dashboard/users", label: "Users", icon: Users },
  { path: "/dashboard/products", label: "Products", icon: Package },
  { path: "/dashboard/assets", label: "Assets", icon: Image },
  { path: "/dashboard/experiences", label: "Experiences", icon: Sparkles },
  { path: "/dashboard/publish", label: "Publish Center", icon: Send },
  { path: "/dashboard/analytics", label: "Analytics", icon: BarChart3 },
  { path: "/dashboard/settings", label: "Settings", icon: Settings },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [location] = useLocation();
  const { user, logout, memberships, companyId, switchCompany } = useAuth();
  const [showCompanySwitch, setShowCompanySwitch] = useState(false);

  const currentCompany = memberships.find(m => m.companyId === companyId);

  return (
    <div className="min-h-screen bg-[hsl(222.2,84%,4.9%)] flex">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/60 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`fixed lg:static inset-y-0 left-0 z-50 w-64 bg-[#0c1222] border-r border-white/[0.06] transform transition-transform duration-200 ease-in-out flex flex-col ${sidebarOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}`}>
        {/* Brand */}
        <div className="h-16 px-5 flex items-center justify-between border-b border-white/[0.06]">
          <Link href="/dashboard" className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center">
              <Eye className="w-4 h-4 text-white" />
            </div>
            <div>
              <span className="text-sm font-bold text-white tracking-tight">AR-core-7</span>
              <span className="block text-[10px] text-zinc-500 -mt-0.5">B2B AR Platform</span>
            </div>
          </Link>
          <button className="lg:hidden text-zinc-400" onClick={() => setSidebarOpen(false)}>
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Company selector */}
        {memberships.length > 0 && (
          <div className="px-3 py-3 border-b border-white/[0.06]">
            <button
              onClick={() => setShowCompanySwitch(!showCompanySwitch)}
              className="w-full flex items-center justify-between px-3 py-2 rounded-lg bg-white/[0.03] hover:bg-white/[0.06] transition-colors"
            >
              <div className="flex items-center gap-2 min-w-0">
                <div className="w-6 h-6 rounded bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shrink-0">
                  <span className="text-[10px] font-bold text-white">{currentCompany?.companyName?.charAt(0) || "?"}</span>
                </div>
                <span className="text-xs font-medium text-zinc-300 truncate">{currentCompany?.companyName || "Select Company"}</span>
              </div>
              <ChevronDown className={`w-3.5 h-3.5 text-zinc-500 transition-transform ${showCompanySwitch ? "rotate-180" : ""}`} />
            </button>
            {showCompanySwitch && (
              <div className="mt-1 space-y-0.5">
                {memberships.map(m => (
                  <button
                    key={m.companyId}
                    onClick={() => { switchCompany(m.companyId); setShowCompanySwitch(false); }}
                    className={`w-full text-left px-3 py-1.5 rounded text-xs transition-colors ${m.companyId === companyId ? "bg-blue-500/10 text-blue-400" : "text-zinc-400 hover:bg-white/[0.03]"}`}
                  >
                    {m.companyName}
                    <span className="ml-1 text-[10px] text-zinc-600">({m.role})</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Navigation */}
        <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto scrollbar-thin">
          {navItems.map(item => {
            const isActive = location === item.path || (item.path !== "/dashboard" && location.startsWith(item.path));
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                href={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all duration-150 ${
                  isActive
                    ? "bg-blue-500/10 text-blue-400 font-medium"
                    : "text-zinc-400 hover:text-zinc-200 hover:bg-white/[0.03]"
                }`}
              >
                <Icon className={`w-4 h-4 shrink-0 ${isActive ? "text-blue-400" : ""}`} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* User */}
        <div className="px-3 py-3 border-t border-white/[0.06]">
          <div className="flex items-center gap-3 px-3 py-2">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center shrink-0">
              <span className="text-xs font-bold text-white">{user?.firstName?.charAt(0)}{user?.lastName?.charAt(0)}</span>
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium text-zinc-200 truncate">{user?.firstName} {user?.lastName}</p>
              <p className="text-[10px] text-zinc-500 truncate">{user?.role?.replace("_", " ")}</p>
            </div>
            <button onClick={logout} className="p-1.5 rounded hover:bg-white/[0.06] text-zinc-500 hover:text-red-400 transition-colors" title="Sign out">
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-h-screen min-w-0">
        {/* Top bar */}
        <header className="h-14 px-4 lg:px-6 flex items-center gap-4 border-b border-white/[0.06] bg-[#0c1222]/80 backdrop-blur-sm sticky top-0 z-30">
          <button className="lg:hidden p-2 -ml-2 text-zinc-400 hover:text-white" onClick={() => setSidebarOpen(true)}>
            <Menu className="w-5 h-5" />
          </button>
          <div className="flex-1" />
          <div className="flex items-center gap-2 text-xs text-zinc-500">
            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            System Active
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 p-4 lg:p-6 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}

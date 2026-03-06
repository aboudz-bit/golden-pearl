import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { formatRelativeTime } from "../../lib/utils";
import {
  Package, Sparkles, Send, Image, Building2, Users,
  Eye, Smartphone, Camera, TrendingUp
} from "lucide-react";

function StatCard({ label, value, icon: Icon, color }: { label: string; value: number | string; icon: any; color: string }) {
  return (
    <div className="stat-card rounded-xl p-4 lg:p-5">
      <div className="flex items-center justify-between mb-3">
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${color}`}>
          <Icon className="w-4.5 h-4.5 text-white" />
        </div>
      </div>
      <p className="text-2xl font-bold text-white">{value}</p>
      <p className="text-xs text-zinc-500 mt-0.5">{label}</p>
    </div>
  );
}

export default function OverviewPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["dashboard-stats"],
    queryFn: () => api.get<any>("/dashboard/stats"),
  });

  const { data: recentProducts } = useQuery({
    queryKey: ["products"],
    queryFn: () => api.get<any[]>("/products"),
  });

  const { data: recentExperiences } = useQuery({
    queryKey: ["experiences"],
    queryFn: () => api.get<any[]>("/experiences"),
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const analytics = stats?.analytics || {};

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Dashboard Overview</h1>
        <p className="text-sm text-zinc-500 mt-1">Platform performance at a glance</p>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 lg:gap-4">
        <StatCard label="Total Products" value={stats?.totalProducts || 0} icon={Package} color="bg-blue-600" />
        <StatCard label="Experiences" value={stats?.totalExperiences || 0} icon={Sparkles} color="bg-violet-600" />
        <StatCard label="Published" value={stats?.publishedExperiences || 0} icon={Send} color="bg-emerald-600" />
        <StatCard label="Assets" value={stats?.totalAssets || 0} icon={Image} color="bg-amber-600" />
      </div>

      {/* Platform stats (super admin) */}
      {stats?.totalCompanies !== undefined && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 lg:gap-4">
          <StatCard label="Companies" value={stats.totalCompanies} icon={Building2} color="bg-indigo-600" />
          <StatCard label="Users" value={stats.totalUsers} icon={Users} color="bg-pink-600" />
          <StatCard label="Page Views (30d)" value={analytics.page_view || 0} icon={Eye} color="bg-cyan-600" />
          <StatCard label="AR Launches (30d)" value={analytics.ar_launch || 0} icon={Smartphone} color="bg-orange-600" />
        </div>
      )}

      {/* Analytics summary */}
      <div className="glass-card rounded-xl p-5">
        <h2 className="text-sm font-semibold text-white mb-4">30-Day Analytics Summary</h2>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          {[
            { label: "Page Views", key: "page_view", icon: Eye, color: "text-blue-400" },
            { label: "Viewer Opens", key: "viewer_open", icon: TrendingUp, color: "text-violet-400" },
            { label: "AR Launches", key: "ar_launch", icon: Smartphone, color: "text-emerald-400" },
            { label: "Camera Grants", key: "camera_granted", icon: Camera, color: "text-amber-400" },
            { label: "Tracking Sessions", key: "tracking_session", icon: Sparkles, color: "text-pink-400" },
          ].map(item => (
            <div key={item.key} className="text-center">
              <item.icon className={`w-5 h-5 mx-auto mb-1.5 ${item.color}`} />
              <p className="text-lg font-bold text-white">{analytics[item.key] || 0}</p>
              <p className="text-[10px] text-zinc-500">{item.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Recent products & experiences */}
      <div className="grid lg:grid-cols-2 gap-4">
        <div className="glass-card rounded-xl p-5">
          <h2 className="text-sm font-semibold text-white mb-4">Recent Products</h2>
          {(!recentProducts || recentProducts.length === 0) ? (
            <p className="text-xs text-zinc-500 py-4 text-center">No products yet</p>
          ) : (
            <div className="space-y-2">
              {recentProducts.slice(0, 5).map((p: any) => (
                <a key={p.id} href={`/dashboard/products/${p.id}`} className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-white/[0.03] transition-colors">
                  <div className="w-9 h-9 rounded-lg bg-white/[0.05] overflow-hidden shrink-0">
                    {p.thumbnail ? <img src={p.thumbnail} alt="" className="w-full h-full object-cover" /> : <Package className="w-4 h-4 m-2.5 text-zinc-600" />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-medium text-zinc-200 truncate">{p.title}</p>
                    <p className="text-[10px] text-zinc-500">{p.category} · {p.status}</p>
                  </div>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border ${p.publishStatus === "published" ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" : "bg-zinc-500/10 text-zinc-400 border-zinc-500/20"}`}>
                    {p.publishStatus}
                  </span>
                </a>
              ))}
            </div>
          )}
        </div>

        <div className="glass-card rounded-xl p-5">
          <h2 className="text-sm font-semibold text-white mb-4">Recent Experiences</h2>
          {(!recentExperiences || recentExperiences.length === 0) ? (
            <p className="text-xs text-zinc-500 py-4 text-center">No experiences yet</p>
          ) : (
            <div className="space-y-2">
              {recentExperiences.slice(0, 5).map((e: any) => (
                <a key={e.id} href={`/dashboard/experiences/${e.id}`} className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-white/[0.03] transition-colors">
                  <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-violet-500/20 to-blue-500/20 flex items-center justify-center shrink-0">
                    <Sparkles className="w-4 h-4 text-violet-400" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-medium text-zinc-200 truncate">{e.name}</p>
                    <p className="text-[10px] text-zinc-500">{e.experienceType?.replace("_", " ")} · {formatRelativeTime(e.createdAt)}</p>
                  </div>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border ${e.status === "published" ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" : "bg-zinc-500/10 text-zinc-400 border-zinc-500/20"}`}>
                    {e.status}
                  </span>
                </a>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { formatDate, getStatusColor } from "../../lib/utils";
import { Building2, Plus, Globe, Palette, X } from "lucide-react";
import { useAuth } from "../../hooks/use-auth";

export default function CompaniesPage() {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ name: "", slug: "", domain: "", brandPrimaryColor: "#6366f1" });

  const { data: companies = [], isLoading } = useQuery({
    queryKey: ["companies"],
    queryFn: () => api.get<any[]>("/companies"),
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => api.post("/companies", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["companies"] });
      setShowCreate(false);
      setForm({ name: "", slug: "", domain: "", brandPrimaryColor: "#6366f1" });
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">Companies</h1>
          <p className="text-sm text-zinc-500 mt-1">Manage client workspaces and brands</p>
        </div>
        {user?.role === "super_admin" && (
          <button
            onClick={() => setShowCreate(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Company
          </button>
        )}
      </div>

      {/* Create modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setShowCreate(false)}>
          <div className="bg-[#0f1729] border border-white/[0.08] rounded-2xl p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-white">New Company</h2>
              <button onClick={() => setShowCreate(false)} className="text-zinc-500 hover:text-white"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createMutation.mutate(form); }} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Company Name</label>
                <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value, slug: e.target.value.toLowerCase().replace(/[^a-z0-9]+/g, "-") })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Slug</label>
                <input value={form.slug} onChange={e => setForm({ ...form, slug: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Domain</label>
                <input value={form.domain} onChange={e => setForm({ ...form, domain: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" placeholder="brand.com" />
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Brand Color</label>
                <div className="flex gap-2">
                  <input type="color" value={form.brandPrimaryColor} onChange={e => setForm({ ...form, brandPrimaryColor: e.target.value })} className="w-10 h-10 rounded border-0 bg-transparent cursor-pointer" />
                  <input value={form.brandPrimaryColor} onChange={e => setForm({ ...form, brandPrimaryColor: e.target.value })} className="flex-1 px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" />
                </div>
              </div>
              <button type="submit" disabled={createMutation.isPending} className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors disabled:opacity-50">
                {createMutation.isPending ? "Creating..." : "Create Company"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Companies grid */}
      {isLoading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : companies.length === 0 ? (
        <div className="glass-card rounded-xl p-12 text-center">
          <Building2 className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
          <p className="text-sm text-zinc-400">No companies yet</p>
          <p className="text-xs text-zinc-600 mt-1">Create your first company to get started</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {companies.map((c: any) => (
            <div key={c.id} className="glass-card rounded-xl p-5 hover:border-white/[0.12] transition-colors">
              <div className="flex items-start gap-3 mb-4">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: c.brandPrimaryColor + "20" }}>
                  {c.logo ? (
                    <img src={c.logo} alt="" className="w-6 h-6 rounded object-contain" />
                  ) : (
                    <span className="text-sm font-bold" style={{ color: c.brandPrimaryColor }}>{c.name?.charAt(0)}</span>
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <h3 className="text-sm font-semibold text-white truncate">{c.name}</h3>
                  <p className="text-[10px] text-zinc-500">/{c.slug}</p>
                </div>
                <span className={`text-[10px] px-2 py-0.5 rounded-full border ${c.isActive ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" : "bg-red-500/10 text-red-400 border-red-500/20"}`}>
                  {c.isActive ? "Active" : "Inactive"}
                </span>
              </div>
              <div className="space-y-2 text-xs text-zinc-400">
                {c.domain && (
                  <div className="flex items-center gap-2">
                    <Globe className="w-3.5 h-3.5 text-zinc-600" />
                    {c.domain}
                  </div>
                )}
                <div className="flex items-center gap-2">
                  <Palette className="w-3.5 h-3.5 text-zinc-600" />
                  <div className="w-4 h-4 rounded" style={{ backgroundColor: c.brandPrimaryColor }} />
                  {c.brandPrimaryColor}
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-white/[0.04] text-[10px] text-zinc-600">
                Created {formatDate(c.createdAt)}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

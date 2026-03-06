import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Link } from "wouter";
import { api } from "../../lib/api";
import { getStatusColor, getExperienceTypeLabel, formatRelativeTime } from "../../lib/utils";
import { Sparkles, Plus, X, Eye, Trash2, Send, Search } from "lucide-react";

export default function ExperiencesPage() {
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [form, setForm] = useState({
    name: "", experienceType: "product_viewer", productId: "", lightingPreset: "studio",
    backgroundMode: "transparent", autoRotate: true, scale: 1.0,
  });

  const { data: experiences = [], isLoading } = useQuery({
    queryKey: ["experiences"],
    queryFn: () => api.get<any[]>("/experiences"),
  });

  const { data: products = [] } = useQuery({
    queryKey: ["products"],
    queryFn: () => api.get<any[]>("/products"),
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => api.post("/experiences", {
      ...data,
      productId: data.productId ? parseInt(data.productId) : null,
      scale: parseFloat(data.scale),
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["experiences"] });
      setShowCreate(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/experiences/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experiences"] }),
  });

  const publishMutation = useMutation({
    mutationFn: (id: number) => api.post(`/experiences/${id}/publish`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experiences"] }),
  });

  const filtered = experiences.filter((e: any) => {
    const matchesSearch = !searchQuery || e.name?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = !typeFilter || e.experienceType === typeFilter;
    return matchesSearch && matchesType;
  });

  const typeColors: Record<string, string> = {
    product_viewer: "from-blue-500/20 to-cyan-500/20",
    surface_ar: "from-violet-500/20 to-pink-500/20",
    image_target: "from-emerald-500/20 to-teal-500/20",
    qr_launch: "from-amber-500/20 to-orange-500/20",
    embed_viewer: "from-indigo-500/20 to-blue-500/20",
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">Experiences</h1>
          <p className="text-sm text-zinc-500 mt-1">Build and manage AR experiences</p>
        </div>
        <button onClick={() => setShowCreate(true)} className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors">
          <Plus className="w-4 h-4" />
          New Experience
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-600" />
          <input value={searchQuery} onChange={e => setSearchQuery(e.target.value)} placeholder="Search experiences..." className="w-full pl-9 pr-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white placeholder-zinc-600 focus:outline-none focus:border-blue-500/50" />
        </div>
        <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)} className="px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-zinc-300 focus:outline-none focus:border-blue-500/50">
          <option value="">All Types</option>
          <option value="product_viewer">3D Viewer</option>
          <option value="surface_ar">Surface AR</option>
          <option value="image_target">Image Target</option>
          <option value="qr_launch">QR Launch</option>
          <option value="embed_viewer">Embed</option>
        </select>
      </div>

      {/* Create modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setShowCreate(false)}>
          <div className="bg-[#0f1729] border border-white/[0.08] rounded-2xl p-6 w-full max-w-lg" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-white">New Experience</h2>
              <button onClick={() => setShowCreate(false)} className="text-zinc-500 hover:text-white"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createMutation.mutate(form); }} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Experience Name</label>
                <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Type</label>
                  <select value={form.experienceType} onChange={e => setForm({ ...form, experienceType: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50">
                    <option value="product_viewer">3D Viewer</option>
                    <option value="surface_ar">Surface AR</option>
                    <option value="image_target">Image Target</option>
                    <option value="qr_launch">QR Launch</option>
                    <option value="embed_viewer">Embed</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Product</label>
                  <select value={form.productId} onChange={e => setForm({ ...form, productId: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50">
                    <option value="">None</option>
                    {products.map((p: any) => <option key={p.id} value={p.id}>{p.title}</option>)}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Lighting</label>
                  <select value={form.lightingPreset} onChange={e => setForm({ ...form, lightingPreset: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50">
                    <option value="studio">Studio</option>
                    <option value="outdoor">Outdoor</option>
                    <option value="soft">Soft</option>
                    <option value="dramatic">Dramatic</option>
                    <option value="neutral">Neutral</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Scale</label>
                  <input type="number" step="0.1" min="0.1" max="10" value={form.scale} onChange={e => setForm({ ...form, scale: parseFloat(e.target.value) })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" />
                </div>
              </div>
              <button type="submit" disabled={createMutation.isPending} className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors disabled:opacity-50">
                {createMutation.isPending ? "Creating..." : "Create Experience"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Experiences grid */}
      {isLoading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="glass-card rounded-xl p-12 text-center">
          <Sparkles className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
          <p className="text-sm text-zinc-400">{searchQuery || typeFilter ? "No matching experiences" : "No experiences yet"}</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((e: any) => (
            <div key={e.id} className="glass-card rounded-xl overflow-hidden hover:border-white/[0.12] transition-colors">
              <div className={`h-24 bg-gradient-to-br ${typeColors[e.experienceType] || "from-zinc-500/20 to-zinc-600/20"} flex items-center justify-center relative`}>
                <Sparkles className="w-8 h-8 text-white/20" />
                <div className="absolute top-3 right-3">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border ${getStatusColor(e.status)}`}>{e.status}</span>
                </div>
                <div className="absolute bottom-3 left-3">
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-black/40 text-white border border-white/10 backdrop-blur-sm">
                    {getExperienceTypeLabel(e.experienceType)}
                  </span>
                </div>
              </div>
              <div className="p-4">
                <h3 className="text-sm font-semibold text-white truncate mb-1">{e.name}</h3>
                <p className="text-[10px] text-zinc-500 mb-3">
                  {e.lightingPreset} lighting · {e.scale}x scale · {formatRelativeTime(e.createdAt)}
                </p>
                <div className="flex items-center justify-between pt-3 border-t border-white/[0.04]">
                  <div className="flex gap-1">
                    {e.status !== "published" && (
                      <button onClick={() => publishMutation.mutate(e.id)} className="flex items-center gap-1 px-2 py-1 text-[10px] rounded-lg bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20 transition-colors">
                        <Send className="w-3 h-3" /> Publish
                      </button>
                    )}
                  </div>
                  <div className="flex gap-1">
                    <Link href={`/dashboard/experiences/${e.id}`} className="p-1.5 rounded hover:bg-white/[0.06] text-zinc-500 hover:text-blue-400 transition-colors">
                      <Eye className="w-3.5 h-3.5" />
                    </Link>
                    <button onClick={() => { if (confirm("Delete this experience?")) deleteMutation.mutate(e.id); }} className="p-1.5 rounded hover:bg-white/[0.06] text-zinc-500 hover:text-red-400 transition-colors">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

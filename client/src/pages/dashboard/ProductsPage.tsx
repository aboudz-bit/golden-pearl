import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Link } from "wouter";
import { api } from "../../lib/api";
import { getStatusColor, formatDate } from "../../lib/utils";
import { Package, Plus, X, Tag, Search, Filter, Trash2, Eye } from "lucide-react";

export default function ProductsPage() {
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [form, setForm] = useState({ title: "", sku: "", category: "", description: "", brand: "", status: "draft", anchorType: "floor" });

  const { data: products = [], isLoading } = useQuery({
    queryKey: ["products"],
    queryFn: () => api.get<any[]>("/products"),
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => api.post("/products", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      setShowCreate(false);
      setForm({ title: "", sku: "", category: "", description: "", brand: "", status: "draft", anchorType: "floor" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/products/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["products"] }),
  });

  const filtered = products.filter((p: any) => {
    const matchesSearch = !searchQuery || p.title?.toLowerCase().includes(searchQuery.toLowerCase()) || p.sku?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = !statusFilter || p.publishStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">Products</h1>
          <p className="text-sm text-zinc-500 mt-1">Manage 3D-ready products and assets</p>
        </div>
        <button onClick={() => setShowCreate(true)} className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors">
          <Plus className="w-4 h-4" />
          Add Product
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-600" />
          <input
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Search products..."
            className="w-full pl-9 pr-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white placeholder-zinc-600 focus:outline-none focus:border-blue-500/50"
          />
        </div>
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          className="px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-zinc-300 focus:outline-none focus:border-blue-500/50"
        >
          <option value="">All Status</option>
          <option value="draft">Draft</option>
          <option value="ready">Ready</option>
          <option value="published">Published</option>
          <option value="archived">Archived</option>
        </select>
      </div>

      {/* Create modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setShowCreate(false)}>
          <div className="bg-[#0f1729] border border-white/[0.08] rounded-2xl p-6 w-full max-w-lg" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-white">New Product</h2>
              <button onClick={() => setShowCreate(false)} className="text-zinc-500 hover:text-white"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createMutation.mutate(form); }} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Product Title</label>
                <input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">SKU</label>
                  <input value={form.sku} onChange={e => setForm({ ...form, sku: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Category</label>
                  <input value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Description</label>
                <textarea rows={3} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50 resize-none" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Brand</label>
                  <input value={form.brand} onChange={e => setForm({ ...form, brand: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Anchor Type</label>
                  <select value={form.anchorType} onChange={e => setForm({ ...form, anchorType: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50">
                    <option value="floor">Floor</option>
                    <option value="wall">Wall</option>
                    <option value="tabletop">Tabletop</option>
                    <option value="face">Face</option>
                  </select>
                </div>
              </div>
              <button type="submit" disabled={createMutation.isPending} className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors disabled:opacity-50">
                {createMutation.isPending ? "Creating..." : "Create Product"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Products grid */}
      {isLoading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="glass-card rounded-xl p-12 text-center">
          <Package className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
          <p className="text-sm text-zinc-400">{searchQuery || statusFilter ? "No matching products" : "No products yet"}</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((p: any) => (
            <div key={p.id} className="glass-card rounded-xl overflow-hidden hover:border-white/[0.12] transition-colors group">
              <div className="h-40 bg-gradient-to-br from-zinc-800/50 to-zinc-900/50 relative">
                {p.thumbnail ? (
                  <img src={p.thumbnail} alt="" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Package className="w-12 h-12 text-zinc-700" />
                  </div>
                )}
                <div className="absolute top-3 right-3 flex gap-1.5">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border backdrop-blur-sm ${getStatusColor(p.publishStatus)}`}>
                    {p.publishStatus}
                  </span>
                </div>
                {/* Completeness bar */}
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/30">
                  <div className="h-full bg-gradient-to-r from-blue-500 to-violet-500 transition-all" style={{ width: `${p.assetCompletenessScore || 0}%` }} />
                </div>
              </div>
              <div className="p-4">
                <div className="flex items-start justify-between mb-2">
                  <div className="min-w-0 flex-1">
                    <h3 className="text-sm font-semibold text-white truncate">{p.title}</h3>
                    <div className="flex items-center gap-2 mt-0.5">
                      {p.sku && <span className="text-[10px] text-zinc-500 font-mono">{p.sku}</span>}
                      {p.category && (
                        <span className="text-[10px] px-1.5 py-0 rounded bg-white/[0.04] text-zinc-500">
                          <Tag className="w-2.5 h-2.5 inline mr-0.5" />{p.category}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
                {p.description && (
                  <p className="text-xs text-zinc-500 line-clamp-2 mb-3">{p.description}</p>
                )}
                <div className="flex items-center justify-between pt-3 border-t border-white/[0.04]">
                  <span className="text-[10px] text-zinc-600">{p.assetCompletenessScore || 0}% complete</span>
                  <div className="flex gap-1">
                    <Link href={`/dashboard/products/${p.id}`} className="p-1.5 rounded hover:bg-white/[0.06] text-zinc-500 hover:text-blue-400 transition-colors">
                      <Eye className="w-3.5 h-3.5" />
                    </Link>
                    <button onClick={() => { if (confirm("Delete this product?")) deleteMutation.mutate(p.id); }} className="p-1.5 rounded hover:bg-white/[0.06] text-zinc-500 hover:text-red-400 transition-colors">
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

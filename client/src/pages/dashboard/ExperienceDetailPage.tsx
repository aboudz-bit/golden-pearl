import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useParams, Link } from "wouter";
import { api } from "../../lib/api";
import { getStatusColor, getExperienceTypeLabel, formatDate } from "../../lib/utils";
import { ArrowLeft, Sparkles, Send, ExternalLink, Copy, QrCode, Code, Box } from "lucide-react";
import { useState } from "react";

export default function ExperienceDetailPage() {
  const { id } = useParams<{ id: string }>();
  const queryClient = useQueryClient();
  const [copied, setCopied] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["experience", id],
    queryFn: () => api.get<any>(`/experiences/${id}`),
  });

  const publishMutation = useMutation({
    mutationFn: () => api.post(`/experiences/${id}/publish`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experience", id] }),
  });

  const unpublishMutation = useMutation({
    mutationFn: () => api.post(`/experiences/${id}/unpublish`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experience", id] }),
  });

  function copyToClipboard(text: string, label: string) {
    navigator.clipboard.writeText(text);
    setCopied(label);
    setTimeout(() => setCopied(""), 2000);
  }

  if (isLoading) {
    return <div className="flex items-center justify-center h-64"><div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>;
  }

  if (!data) {
    return <div className="glass-card rounded-xl p-12 text-center"><Sparkles className="w-12 h-12 mx-auto text-zinc-600 mb-3" /><p className="text-sm text-zinc-400">Experience not found</p></div>;
  }

  const exp = data;
  const product = data.product;
  const assets = data.assets || [];
  const glbAsset = assets.find((a: any) => a.assetType === "glb" || a.assetType === "gltf");
  const publicUrl = `/ar/${exp.slug}`;
  const viewerUrl = product ? `/viewer/${exp.companySlug || "demo"}/${product.slug}` : null;
  const embedCode = `<iframe src="${window.location.origin}/ar/${exp.slug}?embed=1" width="100%" height="500" frameborder="0" allow="camera;xr-spatial-tracking"></iframe>`;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Link href="/dashboard/experiences" className="p-2 rounded-lg hover:bg-white/[0.06] text-zinc-400 hover:text-white transition-colors">
          <ArrowLeft className="w-4 h-4" />
        </Link>
        <div className="flex-1">
          <h1 className="text-xl font-bold text-white">{exp.name}</h1>
          <div className="flex items-center gap-2 mt-0.5">
            <span className="text-xs text-zinc-500">{getExperienceTypeLabel(exp.experienceType)}</span>
            <span className={`text-[10px] px-2 py-0.5 rounded-full border ${getStatusColor(exp.status)}`}>{exp.status}</span>
          </div>
        </div>
        <div className="flex gap-2">
          {exp.status === "published" ? (
            <button onClick={() => unpublishMutation.mutate()} className="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white text-sm rounded-xl transition-colors">
              Unpublish
            </button>
          ) : (
            <button onClick={() => publishMutation.mutate()} className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-medium rounded-xl transition-colors">
              <Send className="w-4 h-4" /> Publish
            </button>
          )}
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Preview */}
        <div className="lg:col-span-2 space-y-4">
          <div className="glass-card rounded-xl overflow-hidden">
            <div className="aspect-video bg-gradient-to-br from-zinc-900 to-zinc-800">
              {glbAsset ? (
                <model-viewer
                  src={glbAsset.filePath}
                  poster={product?.thumbnail}
                  camera-controls
                  auto-rotate={exp.autoRotate ? "" : undefined}
                  shadow-intensity="1"
                  exposure="1"
                  ar
                  ar-modes="webxr scene-viewer quick-look"
                  style={{ width: "100%", height: "100%", background: exp.backgroundMode === "dark" ? "#111" : exp.backgroundMode === "white" ? "#fff" : "transparent" }}
                >
                  <button slot="ar-button" className="absolute bottom-4 right-4 px-4 py-2 bg-white text-black text-sm font-medium rounded-lg shadow-lg">
                    View in AR
                  </button>
                </model-viewer>
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center">
                  <Box className="w-16 h-16 text-zinc-700 mb-3" />
                  <p className="text-sm text-zinc-500">No 3D model linked</p>
                </div>
              )}
            </div>
          </div>

          {/* Sharing */}
          <div className="glass-card rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white mb-4">Share & Embed</h3>
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <ExternalLink className="w-4 h-4 text-zinc-500 shrink-0" />
                <code className="flex-1 text-xs text-zinc-400 bg-white/[0.03] px-3 py-2 rounded-lg truncate">{window.location.origin}{publicUrl}</code>
                <button onClick={() => copyToClipboard(`${window.location.origin}${publicUrl}`, "url")} className={`px-3 py-1.5 text-xs rounded-lg transition-colors ${copied === "url" ? "bg-emerald-500/10 text-emerald-400" : "bg-white/[0.04] text-zinc-400 hover:text-white"}`}>
                  {copied === "url" ? "Copied!" : "Copy"}
                </button>
              </div>
              <div className="flex items-center gap-2">
                <QrCode className="w-4 h-4 text-zinc-500 shrink-0" />
                <code className="flex-1 text-xs text-zinc-400 bg-white/[0.03] px-3 py-2 rounded-lg truncate">{window.location.origin}/qr/{exp.slug}</code>
                <button onClick={() => copyToClipboard(`${window.location.origin}/qr/${exp.slug}`, "qr")} className={`px-3 py-1.5 text-xs rounded-lg transition-colors ${copied === "qr" ? "bg-emerald-500/10 text-emerald-400" : "bg-white/[0.04] text-zinc-400 hover:text-white"}`}>
                  {copied === "qr" ? "Copied!" : "Copy"}
                </button>
              </div>
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <Code className="w-4 h-4 text-zinc-500" />
                  <span className="text-xs text-zinc-500">Embed Code</span>
                </div>
                <div className="relative">
                  <pre className="text-[10px] text-zinc-400 bg-white/[0.03] px-3 py-2 rounded-lg overflow-x-auto">{embedCode}</pre>
                  <button onClick={() => copyToClipboard(embedCode, "embed")} className={`absolute top-2 right-2 px-2 py-1 text-[10px] rounded transition-colors ${copied === "embed" ? "bg-emerald-500/10 text-emerald-400" : "bg-white/[0.06] text-zinc-400 hover:text-white"}`}>
                    <Copy className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Config sidebar */}
        <div className="space-y-4">
          <div className="glass-card rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white mb-3">Scene Configuration</h3>
            <div className="space-y-3 text-xs">
              <div className="flex justify-between"><span className="text-zinc-500">Type</span><span className="text-zinc-300">{getExperienceTypeLabel(exp.experienceType)}</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Scale</span><span className="text-zinc-300">{exp.scale}x</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Rotation</span><span className="text-zinc-300">{exp.rotationX}° / {exp.rotationY}° / {exp.rotationZ}°</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Lighting</span><span className="text-zinc-300 capitalize">{exp.lightingPreset}</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Background</span><span className="text-zinc-300 capitalize">{exp.backgroundMode}</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Auto Rotate</span><span className="text-zinc-300">{exp.autoRotate ? "Yes" : "No"}</span></div>
              <div className="flex justify-between"><span className="text-zinc-500">Analytics</span><span className="text-zinc-300">{exp.analyticsEnabled ? "Enabled" : "Disabled"}</span></div>
            </div>
          </div>

          {(exp.ctaText || exp.ctaLink) && (
            <div className="glass-card rounded-xl p-5">
              <h3 className="text-sm font-semibold text-white mb-3">Call to Action</h3>
              <div className="space-y-2 text-xs">
                {exp.ctaText && <div className="flex justify-between"><span className="text-zinc-500">Text</span><span className="text-zinc-300">{exp.ctaText}</span></div>}
                {exp.ctaLink && <div className="flex justify-between"><span className="text-zinc-500">Link</span><span className="text-blue-400 truncate ml-2">{exp.ctaLink}</span></div>}
              </div>
            </div>
          )}

          {product && (
            <div className="glass-card rounded-xl p-5">
              <h3 className="text-sm font-semibold text-white mb-3">Linked Product</h3>
              <Link href={`/dashboard/products/${product.id}`} className="flex items-center gap-3 p-2 rounded-lg hover:bg-white/[0.03] transition-colors">
                <div className="w-10 h-10 rounded-lg bg-white/[0.05] overflow-hidden shrink-0">
                  {product.thumbnail ? <img src={product.thumbnail} alt="" className="w-full h-full object-cover" /> : <Box className="w-5 h-5 m-2.5 text-zinc-600" />}
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-medium text-zinc-200 truncate">{product.title}</p>
                  <p className="text-[10px] text-zinc-500">{product.category} · {product.sku}</p>
                </div>
              </Link>
            </div>
          )}

          <div className="text-[10px] text-zinc-600 px-1">
            Slug: {exp.slug}<br />
            Created {formatDate(exp.createdAt)} · Updated {formatDate(exp.updatedAt)}
          </div>
        </div>
      </div>
    </div>
  );
}

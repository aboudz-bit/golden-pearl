import { useQuery } from "@tanstack/react-query";
import { useParams, Link } from "wouter";
import { api } from "../../lib/api";
import { getStatusColor, formatDate } from "../../lib/utils";
import { Package, ArrowLeft, Tag, Ruler, Box, Image, FileType2, AlertCircle, CheckCircle } from "lucide-react";

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();

  const { data, isLoading } = useQuery({
    queryKey: ["product", id],
    queryFn: () => api.get<any>(`/products/${id}`),
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!data) {
    return (
      <div className="glass-card rounded-xl p-12 text-center">
        <Package className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
        <p className="text-sm text-zinc-400">Product not found</p>
      </div>
    );
  }

  const product = data;
  const assets = data.assets || [];
  const glbAsset = assets.find((a: any) => a.assetType === "glb" || a.assetType === "gltf");
  const posterAsset = assets.find((a: any) => a.assetType === "poster");

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Link href="/dashboard/products" className="p-2 rounded-lg hover:bg-white/[0.06] text-zinc-400 hover:text-white transition-colors">
          <ArrowLeft className="w-4 h-4" />
        </Link>
        <div>
          <h1 className="text-xl font-bold text-white">{product.title}</h1>
          <div className="flex items-center gap-2 mt-0.5">
            {product.sku && <span className="text-xs text-zinc-500 font-mono">{product.sku}</span>}
            <span className={`text-[10px] px-2 py-0.5 rounded-full border ${getStatusColor(product.publishStatus)}`}>{product.publishStatus}</span>
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* 3D Viewer */}
        <div className="lg:col-span-2">
          <div className="glass-card rounded-xl overflow-hidden">
            <div className="aspect-[4/3] bg-gradient-to-br from-zinc-900 to-zinc-800 relative">
              {glbAsset ? (
                <model-viewer
                  src={glbAsset.filePath}
                  poster={posterAsset?.filePath || product.thumbnail}
                  camera-controls
                  auto-rotate
                  shadow-intensity="1"
                  shadow-softness="0.5"
                  exposure="1"
                  ar
                  ar-modes="webxr scene-viewer quick-look"
                  style={{ width: "100%", height: "100%", background: "transparent" }}
                >
                  <button slot="ar-button" className="absolute bottom-4 right-4 px-4 py-2 bg-white text-black text-sm font-medium rounded-lg shadow-lg hover:bg-zinc-100 transition-colors">
                    View in AR
                  </button>
                </model-viewer>
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center">
                  {product.thumbnail ? (
                    <img src={product.thumbnail} alt="" className="max-h-full max-w-full object-contain" />
                  ) : (
                    <>
                      <Box className="w-16 h-16 text-zinc-700 mb-3" />
                      <p className="text-sm text-zinc-500">No 3D model uploaded</p>
                      <p className="text-xs text-zinc-600 mt-1">Upload a GLB/GLTF file to preview</p>
                    </>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Details sidebar */}
        <div className="space-y-4">
          <div className="glass-card rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white mb-3">Product Details</h3>
            <div className="space-y-3 text-xs">
              {product.category && (
                <div className="flex items-center justify-between">
                  <span className="text-zinc-500 flex items-center gap-1.5"><Tag className="w-3.5 h-3.5" /> Category</span>
                  <span className="text-zinc-300">{product.category}</span>
                </div>
              )}
              {product.brand && (
                <div className="flex items-center justify-between">
                  <span className="text-zinc-500">Brand</span>
                  <span className="text-zinc-300">{product.brand}</span>
                </div>
              )}
              <div className="flex items-center justify-between">
                <span className="text-zinc-500">Status</span>
                <span className={`px-2 py-0.5 rounded-full border text-[10px] ${getStatusColor(product.status)}`}>{product.status}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-zinc-500">Anchor Type</span>
                <span className="text-zinc-300">{product.anchorType}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-zinc-500">Scale Preset</span>
                <span className="text-zinc-300">{product.scalePreset}x</span>
              </div>
              {(product.dimensionsWidth || product.dimensionsHeight || product.dimensionsDepth) && (
                <div className="flex items-center justify-between">
                  <span className="text-zinc-500 flex items-center gap-1.5"><Ruler className="w-3.5 h-3.5" /> Dimensions</span>
                  <span className="text-zinc-300">
                    {product.dimensionsWidth || 0} x {product.dimensionsHeight || 0} x {product.dimensionsDepth || 0} {product.dimensionsUnit}
                  </span>
                </div>
              )}
            </div>
          </div>

          {product.description && (
            <div className="glass-card rounded-xl p-5">
              <h3 className="text-sm font-semibold text-white mb-2">Description</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">{product.description}</p>
            </div>
          )}

          {/* Asset completeness */}
          <div className="glass-card rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white mb-3">Asset Completeness</h3>
            <div className="relative h-2 bg-zinc-800 rounded-full mb-3">
              <div className="h-full bg-gradient-to-r from-blue-500 to-violet-500 rounded-full transition-all" style={{ width: `${product.assetCompletenessScore || 0}%` }} />
            </div>
            <p className="text-xs text-zinc-500 mb-3">{product.assetCompletenessScore || 0}% complete</p>
            <div className="space-y-2 text-xs">
              {["glb", "poster", "image", "usdz", "target_image"].map(type => {
                const hasAsset = assets.some((a: any) => a.assetType === type);
                return (
                  <div key={type} className="flex items-center gap-2">
                    {hasAsset ? (
                      <CheckCircle className="w-3.5 h-3.5 text-emerald-400" />
                    ) : (
                      <AlertCircle className="w-3.5 h-3.5 text-zinc-600" />
                    )}
                    <span className={hasAsset ? "text-zinc-300" : "text-zinc-600"}>{type.toUpperCase().replace("_", " ")}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Assets list */}
          <div className="glass-card rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white mb-3">Assets ({assets.length})</h3>
            {assets.length === 0 ? (
              <p className="text-xs text-zinc-500">No assets uploaded</p>
            ) : (
              <div className="space-y-2">
                {assets.map((a: any) => (
                  <div key={a.id} className="flex items-center gap-3 p-2 rounded-lg bg-white/[0.02]">
                    <div className="w-8 h-8 rounded bg-white/[0.05] flex items-center justify-center shrink-0">
                      {a.assetType === "glb" || a.assetType === "gltf" ? <Box className="w-4 h-4 text-violet-400" /> :
                       a.assetType === "poster" || a.assetType === "image" ? <Image className="w-4 h-4 text-blue-400" /> :
                       <FileType2 className="w-4 h-4 text-zinc-500" />}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-xs text-zinc-300 truncate">{a.fileName}</p>
                      <p className="text-[10px] text-zinc-600">{a.assetType} · {a.fileSize ? `${(a.fileSize / 1024).toFixed(0)} KB` : "—"}</p>
                    </div>
                    {a.isValid ? (
                      <CheckCircle className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                    ) : (
                      <AlertCircle className="w-3.5 h-3.5 text-amber-500 shrink-0" />
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="text-[10px] text-zinc-600 px-1">
            Created {formatDate(product.createdAt)} · Updated {formatDate(product.updatedAt)}
          </div>
        </div>
      </div>
    </div>
  );
}

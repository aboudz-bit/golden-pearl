import { useEffect, useState } from "react";
import { useParams } from "wouter";
import { Box, ExternalLink, Smartphone, RotateCcw } from "lucide-react";

export default function ViewerPage() {
  const { companySlug, productSlug } = useParams<{ companySlug: string; productSlug: string }>();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch(`/api/public/viewer/${companySlug}/${productSlug}`)
      .then(r => r.ok ? r.json() : Promise.reject("Not found"))
      .then(d => { setData(d); setLoading(false); })
      .catch(e => { setError(String(e)); setLoading(false); });

    // Track page view
    fetch("/api/analytics/event", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        companyId: 0, // will be set properly
        eventType: "page_view",
        sessionId: `viewer-${Date.now().toString(36)}`,
        deviceType: /mobile/i.test(navigator.userAgent) ? "mobile" : "desktop",
        browser: navigator.userAgent.includes("Safari") && !navigator.userAgent.includes("Chrome") ? "Safari" : "Chrome",
      }),
    }).catch(() => {});
  }, [companySlug, productSlug]);

  if (loading) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-white/30 border-t-white rounded-full animate-spin" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center text-white p-4">
        <Box className="w-16 h-16 text-zinc-600 mb-4" />
        <h1 className="text-xl font-bold mb-2">Product Not Found</h1>
        <p className="text-sm text-zinc-500">This product viewer is not available.</p>
      </div>
    );
  }

  const { company, product, assets } = data;
  const glbAsset = assets?.find((a: any) => a.assetType === "glb" || a.assetType === "gltf");
  const usdzAsset = assets?.find((a: any) => a.assetType === "usdz");
  const posterAsset = assets?.find((a: any) => a.assetType === "poster");

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="absolute top-0 left-0 right-0 z-10 p-4 flex items-center justify-between bg-gradient-to-b from-black/60 to-transparent">
        <div className="flex items-center gap-3">
          {company?.logo && <img src={company.logo} alt="" className="w-8 h-8 rounded-lg object-contain" />}
          <div>
            <h1 className="text-sm font-semibold text-white">{product.title}</h1>
            <p className="text-[10px] text-white/60">{company?.name}</p>
          </div>
        </div>
      </header>

      {/* 3D Viewer */}
      <div className="h-screen w-full">
        {glbAsset ? (
          <model-viewer
            src={glbAsset.filePath}
            ios-src={usdzAsset?.filePath}
            poster={posterAsset?.filePath || product.thumbnail}
            camera-controls
            auto-rotate
            shadow-intensity="1"
            shadow-softness="0.5"
            exposure="1.2"
            ar
            ar-modes="webxr scene-viewer quick-look"
            environment-image="neutral"
            style={{ width: "100%", height: "100%", background: "radial-gradient(ellipse at center, #1a1a2e 0%, #0a0a0f 100%)" }}
          >
            <button slot="ar-button" style={{
              position: "absolute", bottom: "24px", left: "50%", transform: "translateX(-50%)",
              padding: "12px 28px", background: company?.brandPrimaryColor || "#6366f1",
              color: "white", border: "none", borderRadius: "12px", fontSize: "14px",
              fontWeight: "600", cursor: "pointer", display: "flex", alignItems: "center", gap: "8px",
              boxShadow: "0 4px 20px rgba(0,0,0,0.4)",
            }}>
              <span style={{ fontSize: "16px" }}>📱</span> View in Your Space
            </button>

            <div slot="poster" style={{
              display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
              height: "100%", gap: "12px",
            }}>
              {(posterAsset?.filePath || product.thumbnail) && (
                <img src={posterAsset?.filePath || product.thumbnail} alt="" style={{ maxHeight: "60%", maxWidth: "80%", objectFit: "contain", borderRadius: "8px" }} />
              )}
              <p style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Loading 3D model...</p>
            </div>
          </model-viewer>
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center p-8">
            {product.thumbnail ? (
              <img src={product.thumbnail} alt="" className="max-h-[60vh] max-w-full object-contain rounded-xl mb-4" />
            ) : (
              <Box className="w-24 h-24 text-zinc-700 mb-4" />
            )}
            <h2 className="text-lg font-semibold mb-2">{product.title}</h2>
            <p className="text-sm text-zinc-500 text-center max-w-md">{product.description}</p>
          </div>
        )}
      </div>

      {/* Bottom info bar */}
      <div className="fixed bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-4 pb-6">
        <div className="max-w-lg mx-auto">
          {product.description && (
            <p className="text-xs text-white/60 text-center line-clamp-2 mb-2">{product.description}</p>
          )}
          <div className="flex items-center justify-center gap-4 text-[10px] text-white/40">
            <span className="flex items-center gap-1"><RotateCcw className="w-3 h-3" /> Drag to rotate</span>
            <span className="flex items-center gap-1"><Smartphone className="w-3 h-3" /> Pinch to zoom</span>
          </div>
        </div>
      </div>
    </div>
  );
}

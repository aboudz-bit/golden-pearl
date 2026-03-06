import { useEffect, useState } from "react";
import { useParams } from "wouter";
import { Box, Smartphone, AlertCircle, ExternalLink } from "lucide-react";

export default function ARPage() {
  const { experienceSlug } = useParams<{ experienceSlug: string }>();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch(`/api/public/experience/${experienceSlug}`)
      .then(r => r.ok ? r.json() : Promise.reject("Not found"))
      .then(d => { setData(d); setLoading(false); })
      .catch(e => { setError(String(e)); setLoading(false); });
  }, [experienceSlug]);

  useEffect(() => {
    if (data?.experience) {
      fetch("/api/analytics/event", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          companyId: data.experience.companyId,
          experienceId: data.experience.id,
          productId: data.experience.productId,
          eventType: "viewer_open",
          sessionId: `ar-${Date.now().toString(36)}`,
          deviceType: /mobile/i.test(navigator.userAgent) ? "mobile" : "desktop",
          browser: navigator.userAgent.includes("Safari") && !navigator.userAgent.includes("Chrome") ? "Safari" : "Chrome",
        }),
      }).catch(() => {});
    }
  }, [data]);

  if (loading) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          <p className="text-xs text-white/40">Loading AR experience...</p>
        </div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center text-white p-4">
        <AlertCircle className="w-16 h-16 text-zinc-600 mb-4" />
        <h1 className="text-xl font-bold mb-2">Experience Not Found</h1>
        <p className="text-sm text-zinc-500">This AR experience is not available.</p>
      </div>
    );
  }

  const { experience, company, product, assets } = data;
  const glbAsset = assets?.find((a: any) => a.assetType === "glb" || a.assetType === "gltf");
  const usdzAsset = assets?.find((a: any) => a.assetType === "usdz");
  const posterAsset = assets?.find((a: any) => a.assetType === "poster");
  const isEmbed = new URLSearchParams(window.location.search).has("embed");

  const bgStyle = experience.backgroundMode === "dark" ? "#111" :
    experience.backgroundMode === "white" ? "#fff" :
    experience.backgroundMode === "gradient" ? "linear-gradient(135deg, #1a1a2e, #0a0a0f)" :
    "transparent";

  return (
    <div className="min-h-screen bg-black text-white" style={{ background: typeof bgStyle === "string" && bgStyle.startsWith("linear") ? bgStyle : undefined, backgroundColor: typeof bgStyle === "string" && !bgStyle.startsWith("linear") ? bgStyle : undefined }}>
      {/* Header (hidden in embed mode) */}
      {!isEmbed && (
        <header className="absolute top-0 left-0 right-0 z-10 p-4 flex items-center justify-between bg-gradient-to-b from-black/60 to-transparent">
          <div className="flex items-center gap-3">
            {company?.logo && <img src={company.logo} alt="" className="w-8 h-8 rounded-lg object-contain" />}
            <div>
              <h1 className="text-sm font-semibold">{experience.name}</h1>
              <p className="text-[10px] text-white/60">{company?.name}</p>
            </div>
          </div>
        </header>
      )}

      {/* AR Viewer */}
      <div className={isEmbed ? "w-full h-full min-h-[400px]" : "h-screen w-full"}>
        {glbAsset ? (
          <model-viewer
            src={glbAsset.filePath}
            ios-src={usdzAsset?.filePath}
            poster={posterAsset?.filePath || product?.thumbnail}
            camera-controls
            auto-rotate={experience.autoRotate ? "" : undefined}
            shadow-intensity={experience.lightingPreset === "dramatic" ? "2" : "1"}
            shadow-softness="0.5"
            exposure={experience.lightingPreset === "dramatic" ? "0.8" : experience.lightingPreset === "outdoor" ? "1.5" : "1"}
            ar
            ar-modes="webxr scene-viewer quick-look"
            ar-scale={experience.scale < 1 ? "fixed" : "auto"}
            environment-image={experience.lightingPreset === "outdoor" ? "legacy" : "neutral"}
            style={{ width: "100%", height: "100%", background: "transparent" }}
          >
            <button slot="ar-button" style={{
              position: "absolute", bottom: "24px", left: "50%", transform: "translateX(-50%)",
              padding: "14px 32px", background: company?.brandPrimaryColor || "#6366f1",
              color: "white", border: "none", borderRadius: "14px", fontSize: "15px",
              fontWeight: "600", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px",
              boxShadow: `0 4px 24px ${company?.brandPrimaryColor || "#6366f1"}40`,
            }}>
              <Smartphone size={18} /> {experience.ctaText || "View in AR"}
            </button>
          </model-viewer>
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center p-8">
            <Box className="w-20 h-20 text-zinc-700 mb-4" />
            <h2 className="text-lg font-semibold mb-2">{experience.name}</h2>
            <p className="text-sm text-zinc-500 text-center">No 3D model available for this experience.</p>
          </div>
        )}
      </div>

      {/* CTA + footer (hidden in embed) */}
      {!isEmbed && experience.ctaLink && (
        <div className="fixed bottom-0 left-0 right-0 p-4 pb-6 bg-gradient-to-t from-black/80 to-transparent">
          <a
            href={experience.ctaLink}
            target="_blank"
            rel="noopener noreferrer"
            className="block w-full max-w-md mx-auto py-3 text-center text-sm font-medium rounded-xl transition-colors"
            style={{ backgroundColor: company?.brandPrimaryColor || "#6366f1", color: "white" }}
          >
            {experience.ctaText || "Learn More"} <ExternalLink className="w-4 h-4 inline ml-1" />
          </a>
        </div>
      )}
    </div>
  );
}

import { useEffect, useState } from "react";
import { useParams } from "wouter";
import { QrCode, Smartphone, AlertCircle, ExternalLink, Box } from "lucide-react";

export default function QRPage() {
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-white/30 border-t-white rounded-full animate-spin" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex flex-col items-center justify-center text-white p-4">
        <AlertCircle className="w-16 h-16 text-zinc-600 mb-4" />
        <h1 className="text-xl font-bold mb-2">Experience Not Found</h1>
        <p className="text-sm text-zinc-500">This QR link is no longer valid.</p>
      </div>
    );
  }

  const { experience, company, product } = data;
  const arUrl = `/ar/${experience.slug}`;
  const brandColor = company?.brandPrimaryColor || "#6366f1";

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex flex-col items-center justify-center text-white p-6">
      {/* Brand header */}
      <div className="text-center mb-8">
        {company?.logo && (
          <img src={company.logo} alt="" className="w-16 h-16 rounded-2xl mx-auto mb-4 object-contain shadow-lg" />
        )}
        <h1 className="text-2xl font-bold mb-1">{experience.name}</h1>
        <p className="text-sm text-white/60">{company?.name}</p>
      </div>

      {/* Product preview */}
      {product && (
        <div className="w-full max-w-xs mb-8">
          <div className="rounded-2xl overflow-hidden bg-white/5 backdrop-blur border border-white/10 shadow-xl">
            {product.thumbnail ? (
              <img src={product.thumbnail} alt="" className="w-full h-48 object-cover" />
            ) : (
              <div className="w-full h-48 flex items-center justify-center">
                <Box className="w-16 h-16 text-zinc-600" />
              </div>
            )}
            <div className="p-4">
              <h2 className="text-sm font-semibold mb-1">{product.title}</h2>
              {product.description && (
                <p className="text-xs text-white/50 line-clamp-2">{product.description}</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* AR Launch button */}
      <a
        href={arUrl}
        className="w-full max-w-xs py-4 flex items-center justify-center gap-3 rounded-2xl text-white text-base font-semibold transition-all hover:scale-[1.02] active:scale-[0.98] shadow-xl"
        style={{ backgroundColor: brandColor, boxShadow: `0 8px 32px ${brandColor}40` }}
      >
        <Smartphone className="w-5 h-5" />
        Launch AR Experience
      </a>

      <p className="text-xs text-white/30 mt-4 text-center max-w-xs">
        Opens an augmented reality experience in your browser. Camera access may be required.
      </p>

      {/* Powered by */}
      <div className="mt-12 flex items-center gap-2 text-[10px] text-white/20">
        <QrCode className="w-3 h-3" />
        Powered by AR-core-7
      </div>
    </div>
  );
}

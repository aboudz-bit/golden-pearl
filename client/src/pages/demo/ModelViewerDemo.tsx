import { useState } from "react";
import { ArrowLeft, RotateCcw, Smartphone, Sun, Moon } from "lucide-react";

const DEMO_MODELS = [
  { name: "Astronaut", url: "https://modelviewer.dev/shared-assets/models/Astronaut.glb", poster: "" },
  { name: "Horse", url: "https://modelviewer.dev/shared-assets/models/Horse.glb", poster: "" },
  { name: "Shishkebab", url: "https://modelviewer.dev/shared-assets/models/shishkebab.glb", poster: "" },
];

export default function ModelViewerDemo() {
  const [activeModel, setActiveModel] = useState(0);
  const [bgMode, setBgMode] = useState<"dark" | "light">("dark");
  const [autoRotate, setAutoRotate] = useState(true);

  const model = DEMO_MODELS[activeModel];

  return (
    <div className={`min-h-screen ${bgMode === "dark" ? "bg-slate-950 text-white" : "bg-gray-100 text-gray-900"}`}>
      <header className="p-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <a href="/dashboard" className="p-2 rounded-lg hover:bg-white/10 text-zinc-400 hover:text-white transition-colors">
            <ArrowLeft className="w-4 h-4" />
          </a>
          <div>
            <h1 className="text-sm font-bold">model-viewer Demo</h1>
            <p className="text-[10px] text-zinc-500">Google model-viewer integration</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => setAutoRotate(!autoRotate)} className={`p-2 rounded-lg transition-colors ${autoRotate ? "bg-blue-500/20 text-blue-400" : "bg-white/5 text-zinc-500"}`} title="Toggle auto-rotate">
            <RotateCcw className="w-4 h-4" />
          </button>
          <button onClick={() => setBgMode(bgMode === "dark" ? "light" : "dark")} className="p-2 rounded-lg bg-white/5 text-zinc-400 hover:text-white transition-colors" title="Toggle background">
            {bgMode === "dark" ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
        </div>
      </header>

      <div className="px-4">
        {/* Model selector */}
        <div className="flex gap-2 mb-4">
          {DEMO_MODELS.map((m, i) => (
            <button
              key={m.name}
              onClick={() => setActiveModel(i)}
              className={`px-4 py-2 rounded-xl text-xs font-medium transition-colors ${i === activeModel ? "bg-blue-600 text-white" : "bg-white/5 text-zinc-400 hover:text-white"}`}
            >
              {m.name}
            </button>
          ))}
        </div>

        {/* Viewer */}
        <div className="rounded-2xl overflow-hidden border border-white/10 shadow-2xl" style={{ height: "60vh" }}>
          <model-viewer
            key={model.url}
            src={model.url}
            camera-controls
            auto-rotate={autoRotate ? "" : undefined}
            shadow-intensity="1"
            shadow-softness="0.5"
            exposure="1"
            ar
            ar-modes="webxr scene-viewer quick-look"
            environment-image="neutral"
            style={{
              width: "100%",
              height: "100%",
              background: bgMode === "dark" ? "radial-gradient(ellipse at center, #1a1a2e 0%, #0a0a0f 100%)" : "radial-gradient(ellipse at center, #f8fafc 0%, #e2e8f0 100%)",
            }}
          >
            <button slot="ar-button" style={{
              position: "absolute", bottom: "16px", left: "50%", transform: "translateX(-50%)",
              padding: "12px 24px", background: "#6366f1", color: "white", border: "none",
              borderRadius: "12px", fontSize: "14px", fontWeight: "600", cursor: "pointer",
              display: "flex", alignItems: "center", gap: "8px", boxShadow: "0 4px 20px rgba(99,102,241,0.4)",
            }}>
              <Smartphone size={16} /> View in AR
            </button>
          </model-viewer>
        </div>

        {/* Info */}
        <div className="mt-4 p-4 rounded-xl bg-white/5 border border-white/10">
          <h2 className="text-sm font-semibold mb-2">About model-viewer</h2>
          <p className="text-xs text-zinc-400 leading-relaxed">
            Google's model-viewer provides a web component for rendering 3D models with support for WebXR AR,
            Scene Viewer (Android), and Quick Look (iOS). It handles loading, poster images, camera controls,
            and graceful fallbacks automatically. Apache 2.0 licensed.
          </p>
          <div className="mt-3 flex gap-2 text-[10px]">
            <span className="px-2 py-1 rounded bg-blue-500/10 text-blue-400">WebXR</span>
            <span className="px-2 py-1 rounded bg-emerald-500/10 text-emerald-400">Scene Viewer</span>
            <span className="px-2 py-1 rounded bg-violet-500/10 text-violet-400">Quick Look</span>
            <span className="px-2 py-1 rounded bg-amber-500/10 text-amber-400">Apache 2.0</span>
          </div>
        </div>
      </div>
    </div>
  );
}

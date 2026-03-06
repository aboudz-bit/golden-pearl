import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Camera, AlertCircle, RefreshCw, Eye } from "lucide-react";

export default function MindARDemo() {
  const [status, setStatus] = useState<"idle" | "loading" | "running" | "error">("idle");
  const [cameraGranted, setCameraGranted] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const containerRef = useRef<HTMLDivElement>(null);
  const mindARRef = useRef<any>(null);

  async function startAR() {
    setStatus("loading");
    setErrorMsg("");

    try {
      // Dynamically import MindAR Three.js integration
      const { MindARThree } = await import("mind-ar/dist/mindar-image-three.prod.js");

      if (!containerRef.current) return;

      // Initialize MindAR with a demo target
      const mindarThree = new MindARThree({
        container: containerRef.current,
        imageTargetSrc: "https://cdn.jsdelivr.net/gh/nicolo-ribaudo/mind-ar-ts@main/examples/image-tracking/assets/card-example/card.mind",
      });

      mindARRef.current = mindarThree;

      const { renderer, scene, camera } = mindarThree;
      const THREE = await import("three");

      // Create anchor and overlay
      const anchor = mindarThree.addAnchor(0);

      // Create a simple 3D object to show on tracking
      const geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5);
      const material = new THREE.MeshStandardMaterial({
        color: 0x6366f1,
        metalness: 0.3,
        roughness: 0.5,
      });
      const cube = new THREE.Mesh(geometry, material);
      anchor.group.add(cube);

      // Add lights
      const light = new THREE.DirectionalLight(0xffffff, 1);
      light.position.set(0, 1, 1);
      scene.add(light);
      scene.add(new THREE.AmbientLight(0xffffff, 0.6));

      // Track anchor events
      anchor.onTargetFound = () => {
        setStatus("running");
      };

      anchor.onTargetLost = () => {
        setStatus("loading");
      };

      await mindarThree.start();
      setCameraGranted(true);
      setStatus("running");

      // Animation loop
      renderer.setAnimationLoop(() => {
        cube.rotation.x += 0.01;
        cube.rotation.y += 0.01;
        renderer.render(scene, camera);
      });

    } catch (err: any) {
      console.error("MindAR error:", err);
      if (err.name === "NotAllowedError") {
        setErrorMsg("Camera permission denied. Please allow camera access and try again.");
      } else {
        setErrorMsg(err.message || "Failed to start AR. Ensure camera is available.");
      }
      setStatus("error");
    }
  }

  function stopAR() {
    if (mindARRef.current) {
      mindARRef.current.stop();
      mindARRef.current = null;
    }
    setStatus("idle");
  }

  useEffect(() => {
    return () => {
      if (mindARRef.current) {
        mindARRef.current.stop();
      }
    };
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <header className="p-4 flex items-center justify-between relative z-20">
        <div className="flex items-center gap-3">
          <a href="/dashboard" className="p-2 rounded-lg hover:bg-white/10 text-zinc-400 hover:text-white transition-colors">
            <ArrowLeft className="w-4 h-4" />
          </a>
          <div>
            <h1 className="text-sm font-bold">MindAR Image Tracking Demo</h1>
            <p className="text-[10px] text-zinc-500">Point camera at target image</p>
          </div>
        </div>
        {status === "running" || status === "loading" ? (
          <button onClick={stopAR} className="px-3 py-1.5 bg-red-600 hover:bg-red-500 text-white text-xs rounded-lg transition-colors">
            Stop
          </button>
        ) : null}
      </header>

      {status === "idle" && (
        <div className="flex flex-col items-center justify-center px-4" style={{ minHeight: "70vh" }}>
          <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center mb-6 shadow-xl shadow-emerald-500/20">
            <Camera className="w-10 h-10 text-white" />
          </div>
          <h2 className="text-xl font-bold mb-2">MindAR Image Tracking</h2>
          <p className="text-sm text-zinc-400 text-center max-w-sm mb-6">
            This demo uses MindAR.js with Three.js for markerless image tracking.
            Point your camera at the target image to see a 3D cube overlay.
          </p>

          <button
            onClick={startAR}
            className="px-8 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-sm font-semibold rounded-xl transition-all shadow-lg shadow-emerald-500/20"
          >
            <Camera className="w-4 h-4 inline mr-2" />
            Start Camera
          </button>

          <div className="mt-8 p-4 rounded-xl bg-white/5 border border-white/10 max-w-sm">
            <h3 className="text-xs font-semibold mb-2">How it works:</h3>
            <ol className="text-[10px] text-zinc-400 space-y-1 list-decimal list-inside">
              <li>Camera permission is requested</li>
              <li>MindAR initializes image tracking engine</li>
              <li>Camera feed is displayed with tracking overlay</li>
              <li>When target image is detected, 3D content appears</li>
              <li>Three.js handles scene rendering and animation</li>
            </ol>
          </div>

          <div className="mt-4 flex gap-2 text-[10px]">
            <span className="px-2 py-1 rounded bg-emerald-500/10 text-emerald-400">MindAR</span>
            <span className="px-2 py-1 rounded bg-blue-500/10 text-blue-400">Three.js</span>
            <span className="px-2 py-1 rounded bg-violet-500/10 text-violet-400">MIT License</span>
          </div>
        </div>
      )}

      {status === "error" && (
        <div className="flex flex-col items-center justify-center px-4" style={{ minHeight: "70vh" }}>
          <AlertCircle className="w-16 h-16 text-red-500 mb-4" />
          <h2 className="text-lg font-bold mb-2">AR Error</h2>
          <p className="text-sm text-zinc-400 text-center max-w-sm mb-6">{errorMsg}</p>
          <button onClick={() => setStatus("idle")} className="flex items-center gap-2 px-6 py-2.5 bg-white/10 hover:bg-white/20 text-white text-sm rounded-xl transition-colors">
            <RefreshCw className="w-4 h-4" /> Try Again
          </button>
        </div>
      )}

      {/* AR Container */}
      <div
        ref={containerRef}
        className={`w-full relative ${status === "loading" || status === "running" ? "block" : "hidden"}`}
        style={{ height: "calc(100vh - 60px)" }}
      />

      {/* Tracking status overlay */}
      {status === "loading" && (
        <div className="fixed bottom-8 left-1/2 -translate-x-1/2 z-20">
          <div className="flex items-center gap-2 px-4 py-2 bg-black/80 backdrop-blur rounded-full">
            <div className="w-3 h-3 border-2 border-white/40 border-t-white rounded-full animate-spin" />
            <span className="text-xs text-white/70">Looking for target image...</span>
          </div>
        </div>
      )}

      {status === "running" && (
        <div className="fixed bottom-8 left-1/2 -translate-x-1/2 z-20">
          <div className="flex items-center gap-2 px-4 py-2 bg-emerald-600/90 backdrop-blur rounded-full">
            <Eye className="w-3.5 h-3.5 text-white" />
            <span className="text-xs text-white font-medium">Target Detected - Tracking Active</span>
          </div>
        </div>
      )}
    </div>
  );
}

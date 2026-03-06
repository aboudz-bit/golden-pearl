import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { formatDate } from "../../lib/utils";
import { Image, Box, FileType2, CheckCircle, AlertCircle, HardDrive } from "lucide-react";

export default function AssetsPage() {
  const { data: assets = [], isLoading } = useQuery({
    queryKey: ["assets"],
    queryFn: () => api.get<any[]>("/assets"),
  });

  const totalSize = assets.reduce((sum: number, a: any) => sum + (a.fileSize || 0), 0);
  const byType = assets.reduce((acc: Record<string, number>, a: any) => {
    acc[a.assetType] = (acc[a.assetType] || 0) + 1;
    return acc;
  }, {});

  const typeIcons: Record<string, any> = {
    glb: { icon: Box, color: "text-violet-400", bg: "bg-violet-500/10" },
    gltf: { icon: Box, color: "text-violet-400", bg: "bg-violet-500/10" },
    poster: { icon: Image, color: "text-blue-400", bg: "bg-blue-500/10" },
    image: { icon: Image, color: "text-cyan-400", bg: "bg-cyan-500/10" },
    usdz: { icon: Box, color: "text-orange-400", bg: "bg-orange-500/10" },
    target_image: { icon: Image, color: "text-emerald-400", bg: "bg-emerald-500/10" },
    metadata: { icon: FileType2, color: "text-zinc-400", bg: "bg-zinc-500/10" },
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Assets</h1>
        <p className="text-sm text-zinc-500 mt-1">All uploaded product assets and media files</p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="stat-card rounded-xl p-4">
          <HardDrive className="w-5 h-5 text-blue-400 mb-2" />
          <p className="text-lg font-bold text-white">{assets.length}</p>
          <p className="text-[10px] text-zinc-500">Total Assets</p>
        </div>
        <div className="stat-card rounded-xl p-4">
          <Box className="w-5 h-5 text-violet-400 mb-2" />
          <p className="text-lg font-bold text-white">{byType["glb"] || 0}</p>
          <p className="text-[10px] text-zinc-500">3D Models</p>
        </div>
        <div className="stat-card rounded-xl p-4">
          <Image className="w-5 h-5 text-cyan-400 mb-2" />
          <p className="text-lg font-bold text-white">{(byType["image"] || 0) + (byType["poster"] || 0)}</p>
          <p className="text-[10px] text-zinc-500">Images</p>
        </div>
        <div className="stat-card rounded-xl p-4">
          <HardDrive className="w-5 h-5 text-emerald-400 mb-2" />
          <p className="text-lg font-bold text-white">{(totalSize / (1024 * 1024)).toFixed(1)} MB</p>
          <p className="text-[10px] text-zinc-500">Total Size</p>
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : assets.length === 0 ? (
        <div className="glass-card rounded-xl p-12 text-center">
          <Image className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
          <p className="text-sm text-zinc-400">No assets uploaded yet</p>
          <p className="text-xs text-zinc-600 mt-1">Assets will appear here when products have uploaded files</p>
        </div>
      ) : (
        <div className="glass-card rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/[0.06]">
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">File</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Type</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Size</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Status</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Optimization</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {assets.map((a: any) => {
                  const ti = typeIcons[a.assetType] || typeIcons.metadata;
                  const Icon = ti.icon;
                  return (
                    <tr key={a.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          <div className={`w-8 h-8 rounded-lg ${ti.bg} flex items-center justify-center shrink-0`}>
                            <Icon className={`w-4 h-4 ${ti.color}`} />
                          </div>
                          <div>
                            <p className="text-sm text-white truncate max-w-[200px]">{a.fileName}</p>
                            <p className="text-[10px] text-zinc-600">{a.mimeType || "—"}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <span className="text-xs text-zinc-400 capitalize">{a.assetType?.replace("_", " ")}</span>
                      </td>
                      <td className="px-5 py-3 text-xs text-zinc-400">
                        {a.fileSize ? `${(a.fileSize / 1024).toFixed(0)} KB` : "—"}
                      </td>
                      <td className="px-5 py-3">
                        {a.isValid ? (
                          <span className="flex items-center gap-1 text-[10px] text-emerald-400"><CheckCircle className="w-3 h-3" /> Valid</span>
                        ) : (
                          <span className="flex items-center gap-1 text-[10px] text-amber-400"><AlertCircle className="w-3 h-3" /> Issues</span>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        <span className={`text-[10px] px-2 py-0.5 rounded-full border ${
                          a.optimizationStatus === "optimized" ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" :
                          a.optimizationStatus === "processing" ? "bg-blue-500/10 text-blue-400 border-blue-500/20" :
                          "bg-zinc-500/10 text-zinc-400 border-zinc-500/20"
                        }`}>{a.optimizationStatus}</span>
                      </td>
                      <td className="px-5 py-3 text-xs text-zinc-500">{formatDate(a.createdAt)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

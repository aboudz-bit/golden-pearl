import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { getStatusColor, getExperienceTypeLabel, formatDate } from "../../lib/utils";
import { Send, Globe, ExternalLink, Copy, QrCode } from "lucide-react";
import { useState } from "react";

export default function PublishPage() {
  const queryClient = useQueryClient();
  const [copied, setCopied] = useState("");

  const { data: experiences = [], isLoading } = useQuery({
    queryKey: ["experiences"],
    queryFn: () => api.get<any[]>("/experiences"),
  });

  const publishMutation = useMutation({
    mutationFn: (id: number) => api.post(`/experiences/${id}/publish`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experiences"] }),
  });

  const unpublishMutation = useMutation({
    mutationFn: (id: number) => api.post(`/experiences/${id}/unpublish`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["experiences"] }),
  });

  function copy(text: string, label: string) {
    navigator.clipboard.writeText(text);
    setCopied(label);
    setTimeout(() => setCopied(""), 2000);
  }

  const published = experiences.filter((e: any) => e.status === "published");
  const ready = experiences.filter((e: any) => e.status === "ready" || e.status === "draft");

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Publish Center</h1>
        <p className="text-sm text-zinc-500 mt-1">Manage AR experience publishing and distribution</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="stat-card rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-white">{published.length}</p>
          <p className="text-[10px] text-zinc-500">Published</p>
        </div>
        <div className="stat-card rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-white">{ready.length}</p>
          <p className="text-[10px] text-zinc-500">Unpublished</p>
        </div>
        <div className="stat-card rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-white">{experiences.length}</p>
          <p className="text-[10px] text-zinc-500">Total</p>
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-40"><div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>
      ) : (
        <div className="space-y-4">
          {/* Published */}
          {published.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-emerald-400 mb-3 flex items-center gap-2"><Globe className="w-4 h-4" /> Live Experiences</h2>
              <div className="space-y-2">
                {published.map((e: any) => {
                  const url = `${window.location.origin}/ar/${e.slug}`;
                  return (
                    <div key={e.id} className="glass-card rounded-xl p-4">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-3">
                          <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                          <h3 className="text-sm font-medium text-white">{e.name}</h3>
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-white/[0.04] text-zinc-500">{getExperienceTypeLabel(e.experienceType)}</span>
                        </div>
                        <button onClick={() => unpublishMutation.mutate(e.id)} className="px-3 py-1.5 text-xs bg-zinc-700 hover:bg-zinc-600 text-zinc-300 rounded-lg transition-colors">
                          Unpublish
                        </button>
                      </div>
                      <div className="flex items-center gap-2 mt-2">
                        <code className="flex-1 text-[10px] text-zinc-400 bg-white/[0.03] px-3 py-1.5 rounded truncate">{url}</code>
                        <button onClick={() => copy(url, e.id)} className={`p-1.5 rounded-lg transition-colors ${copied === e.id ? "text-emerald-400" : "text-zinc-500 hover:text-white"}`}>
                          <Copy className="w-3.5 h-3.5" />
                        </button>
                        <a href={`/ar/${e.slug}`} target="_blank" className="p-1.5 rounded-lg text-zinc-500 hover:text-blue-400 transition-colors">
                          <ExternalLink className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Ready to publish */}
          {ready.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-zinc-400 mb-3">Ready to Publish</h2>
              <div className="space-y-2">
                {ready.map((e: any) => (
                  <div key={e.id} className="glass-card rounded-xl p-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className={`text-[10px] px-2 py-0.5 rounded-full border ${getStatusColor(e.status)}`}>{e.status}</span>
                      <h3 className="text-sm text-zinc-300">{e.name}</h3>
                      <span className="text-[10px] text-zinc-600">{getExperienceTypeLabel(e.experienceType)}</span>
                    </div>
                    <button onClick={() => publishMutation.mutate(e.id)} className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-medium rounded-lg transition-colors">
                      <Send className="w-3 h-3" /> Publish
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {experiences.length === 0 && (
            <div className="glass-card rounded-xl p-12 text-center">
              <Send className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
              <p className="text-sm text-zinc-400">No experiences to publish</p>
              <p className="text-xs text-zinc-600 mt-1">Create an experience first</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

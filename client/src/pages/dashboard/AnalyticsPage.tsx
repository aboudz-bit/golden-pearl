import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { BarChart3, Eye, Smartphone, Camera, Sparkles, TrendingUp } from "lucide-react";

export default function AnalyticsPage() {
  const { data: summary = [], isLoading: loadingSummary } = useQuery({
    queryKey: ["analytics-summary"],
    queryFn: () => api.get<any[]>("/analytics/summary"),
  });

  const { data: timeline = [], isLoading: loadingTimeline } = useQuery({
    queryKey: ["analytics-timeline"],
    queryFn: () => api.get<any[]>("/analytics/timeline"),
  });

  const summaryMap = summary.reduce((acc: Record<string, number>, s: any) => {
    acc[s.eventType] = parseInt(s.count);
    return acc;
  }, {});

  // Group timeline by date
  const timelineByDate = timeline.reduce((acc: Record<string, Record<string, number>>, t: any) => {
    if (!acc[t.date]) acc[t.date] = {};
    acc[t.date][t.eventType] = parseInt(t.count);
    return acc;
  }, {});

  const dates = Object.keys(timelineByDate).sort().slice(-14); // Last 14 days
  const maxValue = Math.max(1, ...dates.map(d => Object.values(timelineByDate[d] || {}).reduce((s: number, v: any) => s + (v as number), 0)));

  const cards = [
    { key: "page_view", label: "Page Views", icon: Eye, color: "from-blue-600 to-blue-500", textColor: "text-blue-400" },
    { key: "viewer_open", label: "Viewer Opens", icon: TrendingUp, color: "from-violet-600 to-violet-500", textColor: "text-violet-400" },
    { key: "ar_launch", label: "AR Launches", icon: Smartphone, color: "from-emerald-600 to-emerald-500", textColor: "text-emerald-400" },
    { key: "camera_granted", label: "Camera Grants", icon: Camera, color: "from-amber-600 to-amber-500", textColor: "text-amber-400" },
    { key: "tracking_session", label: "Tracking Sessions", icon: Sparkles, color: "from-pink-600 to-pink-500", textColor: "text-pink-400" },
  ];

  const isLoading = loadingSummary || loadingTimeline;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Analytics</h1>
        <p className="text-sm text-zinc-500 mt-1">Track engagement across AR experiences (last 30 days)</p>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-40"><div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" /></div>
      ) : (
        <>
          {/* Summary cards */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            {cards.map(c => (
              <div key={c.key} className="stat-card rounded-xl p-4">
                <c.icon className={`w-5 h-5 ${c.textColor} mb-2`} />
                <p className="text-2xl font-bold text-white">{(summaryMap[c.key] || 0).toLocaleString()}</p>
                <p className="text-[10px] text-zinc-500">{c.label}</p>
              </div>
            ))}
          </div>

          {/* Timeline chart */}
          <div className="glass-card rounded-xl p-5">
            <h2 className="text-sm font-semibold text-white mb-4">14-Day Trend</h2>
            <div className="flex items-end gap-1.5 h-48">
              {dates.map(date => {
                const dayData = timelineByDate[date] || {};
                const total = Object.values(dayData).reduce((s: number, v: any) => s + (v as number), 0);
                const height = Math.max(4, (total / maxValue) * 100);
                const dayLabel = new Date(date + "T12:00:00").toLocaleDateString("en-US", { month: "short", day: "numeric" });

                return (
                  <div key={date} className="flex-1 flex flex-col items-center gap-1">
                    <span className="text-[9px] text-zinc-500">{total}</span>
                    <div className="w-full flex flex-col-reverse gap-0.5" style={{ height: `${height}%` }}>
                      {Object.entries(dayData).map(([type, count]) => {
                        const card = cards.find(c => c.key === type);
                        const portion = Math.max(2, ((count as number) / total) * 100);
                        return (
                          <div
                            key={type}
                            className={`w-full rounded-sm bg-gradient-to-t ${card?.color || "from-zinc-600 to-zinc-500"}`}
                            style={{ height: `${portion}%`, minHeight: "2px" }}
                            title={`${type}: ${count}`}
                          />
                        );
                      })}
                    </div>
                    <span className="text-[8px] text-zinc-600 whitespace-nowrap">{dayLabel}</span>
                  </div>
                );
              })}
            </div>
            <div className="flex items-center justify-center gap-4 mt-4">
              {cards.map(c => (
                <div key={c.key} className="flex items-center gap-1.5">
                  <div className={`w-2 h-2 rounded-full bg-gradient-to-r ${c.color}`} />
                  <span className="text-[9px] text-zinc-500">{c.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Total summary */}
          <div className="glass-card rounded-xl p-5">
            <h2 className="text-sm font-semibold text-white mb-3">Engagement Funnel</h2>
            <div className="space-y-2">
              {cards.map((c, i) => {
                const val = summaryMap[c.key] || 0;
                const maxVal = Math.max(1, ...Object.values(summaryMap));
                const width = Math.max(5, (val / maxVal) * 100);
                return (
                  <div key={c.key} className="flex items-center gap-3">
                    <span className="text-xs text-zinc-500 w-32 text-right">{c.label}</span>
                    <div className="flex-1 h-6 bg-white/[0.03] rounded-lg overflow-hidden">
                      <div className={`h-full bg-gradient-to-r ${c.color} rounded-lg flex items-center px-2 transition-all`} style={{ width: `${width}%` }}>
                        <span className="text-[10px] font-medium text-white">{val.toLocaleString()}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

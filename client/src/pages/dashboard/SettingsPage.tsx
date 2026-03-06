import { Settings, Palette, Eye, Smartphone, Upload, BarChart3, Globe } from "lucide-react";
import { useAuth } from "../../hooks/use-auth";

export default function SettingsPage() {
  const { user, memberships, companyId } = useAuth();
  const currentCompany = memberships.find(m => m.companyId === companyId);

  const settingSections = [
    {
      title: "Branding",
      icon: Palette,
      items: [
        { label: "Company Name", value: currentCompany?.companyName || "—" },
        { label: "Company Slug", value: currentCompany?.companySlug || "—" },
        { label: "Primary Color", value: "#6366f1", type: "color" },
      ],
    },
    {
      title: "Default Viewer Behavior",
      icon: Eye,
      items: [
        { label: "Auto-Rotate", value: "Enabled" },
        { label: "Camera Controls", value: "Orbit" },
        { label: "Shadow Intensity", value: "1.0" },
        { label: "Exposure", value: "1.0" },
      ],
    },
    {
      title: "AR Defaults",
      icon: Smartphone,
      items: [
        { label: "Default AR Mode", value: "Surface Placement" },
        { label: "Fallback Behavior", value: "Show 3D Viewer" },
        { label: "Camera Permission Prompt", value: "Standard" },
      ],
    },
    {
      title: "Upload Settings",
      icon: Upload,
      items: [
        { label: "Max Upload Size", value: "50 MB" },
        { label: "Allowed File Types", value: "GLB, GLTF, USDZ, PNG, JPG, WebP" },
        { label: "Auto-Optimization", value: "Pending (not yet implemented)" },
      ],
    },
    {
      title: "Analytics",
      icon: BarChart3,
      items: [
        { label: "Analytics Enabled", value: "Yes" },
        { label: "Track Page Views", value: "Yes" },
        { label: "Track AR Launches", value: "Yes" },
        { label: "Session Duration", value: "Yes" },
      ],
    },
    {
      title: "Domain & Display",
      icon: Globe,
      items: [
        { label: "Custom Domain", value: "Not configured" },
        { label: "White-label Mode", value: "Disabled" },
        { label: "Language", value: "English (Arabic-ready)" },
        { label: "Direction", value: "LTR (RTL supported)" },
      ],
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Settings</h1>
        <p className="text-sm text-zinc-500 mt-1">Platform configuration and preferences</p>
      </div>

      <div className="grid lg:grid-cols-2 gap-4">
        {settingSections.map(section => (
          <div key={section.title} className="glass-card rounded-xl p-5">
            <div className="flex items-center gap-2 mb-4">
              <section.icon className="w-4 h-4 text-blue-400" />
              <h2 className="text-sm font-semibold text-white">{section.title}</h2>
            </div>
            <div className="space-y-3">
              {section.items.map(item => (
                <div key={item.label} className="flex items-center justify-between">
                  <span className="text-xs text-zinc-500">{item.label}</span>
                  <span className="text-xs text-zinc-300">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Account info */}
      <div className="glass-card rounded-xl p-5">
        <h2 className="text-sm font-semibold text-white mb-4">Account Information</h2>
        <div className="grid md:grid-cols-2 gap-4 text-xs">
          <div className="space-y-2">
            <div className="flex justify-between"><span className="text-zinc-500">Email</span><span className="text-zinc-300">{user?.email}</span></div>
            <div className="flex justify-between"><span className="text-zinc-500">Name</span><span className="text-zinc-300">{user?.firstName} {user?.lastName}</span></div>
            <div className="flex justify-between"><span className="text-zinc-500">Role</span><span className="text-zinc-300 capitalize">{user?.role?.replace("_", " ")}</span></div>
          </div>
          <div className="space-y-2">
            <div className="flex justify-between"><span className="text-zinc-500">Companies</span><span className="text-zinc-300">{memberships.length}</span></div>
            <div className="flex justify-between"><span className="text-zinc-500">Active Company</span><span className="text-zinc-300">{currentCompany?.companyName || "—"}</span></div>
            <div className="flex justify-between"><span className="text-zinc-500">Platform</span><span className="text-zinc-300">AR-core-7 v1.0</span></div>
          </div>
        </div>
      </div>
    </div>
  );
}

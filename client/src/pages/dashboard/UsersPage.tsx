import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import { formatDate } from "../../lib/utils";
import { Users, Plus, X, Mail, Shield } from "lucide-react";
import { useAuth } from "../../hooks/use-auth";

const roleColors: Record<string, string> = {
  super_admin: "bg-red-500/10 text-red-400 border-red-500/20",
  company_admin: "bg-blue-500/10 text-blue-400 border-blue-500/20",
  content_manager: "bg-violet-500/10 text-violet-400 border-violet-500/20",
  viewer: "bg-zinc-500/10 text-zinc-400 border-zinc-500/20",
};

export default function UsersPage() {
  const { user: currentUser } = useAuth();
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ email: "", password: "", firstName: "", lastName: "", role: "viewer" });

  const { data: usersList = [], isLoading } = useQuery({
    queryKey: ["users"],
    queryFn: () => api.get<any[]>("/users"),
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => api.post("/users", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      setShowCreate(false);
      setForm({ email: "", password: "", firstName: "", lastName: "", role: "viewer" });
    },
  });

  const isSuperAdmin = currentUser?.role === "super_admin";
  const canCreate = isSuperAdmin || currentUser?.role === "company_admin";

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">Users</h1>
          <p className="text-sm text-zinc-500 mt-1">Manage platform users and roles</p>
        </div>
        {canCreate && (
          <button onClick={() => setShowCreate(true)} className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors">
            <Plus className="w-4 h-4" />
            Add User
          </button>
        )}
      </div>

      {/* Create modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setShowCreate(false)}>
          <div className="bg-[#0f1729] border border-white/[0.08] rounded-2xl p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-white">New User</h2>
              <button onClick={() => setShowCreate(false)} className="text-zinc-500 hover:text-white"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={e => { e.preventDefault(); createMutation.mutate(form); }} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">First Name</label>
                  <input value={form.firstName} onChange={e => setForm({ ...form, firstName: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
                </div>
                <div>
                  <label className="block text-xs font-medium text-zinc-400 mb-1">Last Name</label>
                  <input value={form.lastName} onChange={e => setForm({ ...form, lastName: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Email</label>
                <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Password</label>
                <input type="password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50" required />
              </div>
              <div>
                <label className="block text-xs font-medium text-zinc-400 mb-1">Role</label>
                <select value={form.role} onChange={e => setForm({ ...form, role: e.target.value })} className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500/50">
                  <option value="viewer">Viewer</option>
                  <option value="content_manager">Content Manager</option>
                  <option value="company_admin">Company Admin</option>
                  {isSuperAdmin && <option value="super_admin">Super Admin</option>}
                </select>
              </div>
              <button type="submit" disabled={createMutation.isPending} className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-xl transition-colors disabled:opacity-50">
                {createMutation.isPending ? "Creating..." : "Create User"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Users table */}
      {isLoading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : usersList.length === 0 ? (
        <div className="glass-card rounded-xl p-12 text-center">
          <Users className="w-12 h-12 mx-auto text-zinc-600 mb-3" />
          <p className="text-sm text-zinc-400">No users found</p>
        </div>
      ) : (
        <div className="glass-card rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/[0.06]">
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">User</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Email</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Role</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Status</th>
                  <th className="px-5 py-3 text-left text-[10px] font-medium text-zinc-500 uppercase tracking-wider">Last Login</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {usersList.map((u: any) => (
                  <tr key={u.id} className="hover:bg-white/[0.02] transition-colors">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center shrink-0">
                          <span className="text-[10px] font-bold text-white">{u.firstName?.charAt(0)}{u.lastName?.charAt(0)}</span>
                        </div>
                        <span className="text-sm text-white">{u.firstName} {u.lastName}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-1.5 text-sm text-zinc-400">
                        <Mail className="w-3.5 h-3.5 text-zinc-600" />
                        {u.email}
                      </div>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`text-[10px] px-2 py-0.5 rounded-full border ${roleColors[u.role] || roleColors.viewer}`}>
                        <Shield className="w-3 h-3 inline mr-1" />
                        {u.role?.replace("_", " ")}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`text-[10px] px-2 py-0.5 rounded-full border ${u.isActive ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" : "bg-red-500/10 text-red-400 border-red-500/20"}`}>
                        {u.isActive ? "Active" : "Disabled"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-zinc-500">
                      {u.lastLoginAt ? formatDate(u.lastLoginAt) : "Never"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

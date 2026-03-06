import { create } from "zustand";
import { api } from "../lib/api";

interface AuthUser {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  avatar: string | null;
}

interface CompanyMembership {
  companyId: number;
  companyName: string;
  companySlug: string;
  role: string;
}

interface AuthState {
  user: AuthUser | null;
  companyId: number | null;
  memberships: CompanyMembership[];
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  switchCompany: (companyId: number) => Promise<void>;
}

export const useAuth = create<AuthState>((set, get) => ({
  user: null,
  companyId: null,
  memberships: [],
  isLoading: true,
  isAuthenticated: false,

  login: async (email: string, password: string) => {
    const data = await api.post<any>("/auth/login", { email, password });
    set({
      user: data.user,
      companyId: data.companyId,
      memberships: data.memberships,
      isAuthenticated: true,
      isLoading: false,
    });
  },

  logout: async () => {
    await api.post("/auth/logout");
    set({ user: null, companyId: null, memberships: [], isAuthenticated: false });
  },

  checkAuth: async () => {
    try {
      const data = await api.get<any>("/auth/me");
      set({
        user: data.user,
        companyId: data.companyId,
        memberships: data.memberships,
        isAuthenticated: true,
        isLoading: false,
      });
    } catch {
      set({ user: null, companyId: null, memberships: [], isAuthenticated: false, isLoading: false });
    }
  },

  switchCompany: async (companyId: number) => {
    await api.post("/auth/switch-company", { companyId });
    set({ companyId });
  },
}));

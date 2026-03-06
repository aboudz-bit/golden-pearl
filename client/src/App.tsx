import { useEffect } from "react";
import { Switch, Route, Redirect } from "wouter";
import { useAuth } from "./hooks/use-auth";
import LoginPage from "./pages/auth/LoginPage";
import DashboardLayout from "./components/layout/DashboardLayout";
import OverviewPage from "./pages/dashboard/OverviewPage";
import CompaniesPage from "./pages/dashboard/CompaniesPage";
import UsersPage from "./pages/dashboard/UsersPage";
import ProductsPage from "./pages/dashboard/ProductsPage";
import ProductDetailPage from "./pages/dashboard/ProductDetailPage";
import AssetsPage from "./pages/dashboard/AssetsPage";
import ExperiencesPage from "./pages/dashboard/ExperiencesPage";
import ExperienceDetailPage from "./pages/dashboard/ExperienceDetailPage";
import PublishPage from "./pages/dashboard/PublishPage";
import AnalyticsPage from "./pages/dashboard/AnalyticsPage";
import SettingsPage from "./pages/dashboard/SettingsPage";
import ViewerPage from "./pages/viewer/ViewerPage";
import ARPage from "./pages/ar/ARPage";
import QRPage from "./pages/ar/QRPage";
import ModelViewerDemo from "./pages/demo/ModelViewerDemo";
import MindARDemo from "./pages/demo/MindARDemo";

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[hsl(222.2,84%,4.9%)]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-zinc-400">Loading AR-core-7...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Redirect to="/login" />;
  }

  return <>{children}</>;
}

export default function App() {
  const { checkAuth } = useAuth();

  useEffect(() => {
    checkAuth();
  }, []);

  return (
    <Switch>
      <Route path="/login" component={LoginPage} />

      {/* Public viewer routes - no auth required */}
      <Route path="/viewer/:companySlug/:productSlug" component={ViewerPage} />
      <Route path="/ar/:experienceSlug" component={ARPage} />
      <Route path="/qr/:experienceSlug" component={QRPage} />

      {/* Demo routes */}
      <Route path="/demo/model-viewer" component={ModelViewerDemo} />
      <Route path="/demo/mindar-image" component={MindARDemo} />

      {/* Dashboard routes - auth required */}
      <Route path="/dashboard/:rest*">
        {() => (
          <ProtectedRoute>
            <DashboardLayout>
              <Switch>
                <Route path="/dashboard" component={OverviewPage} />
                <Route path="/dashboard/companies" component={CompaniesPage} />
                <Route path="/dashboard/users" component={UsersPage} />
                <Route path="/dashboard/products" component={ProductsPage} />
                <Route path="/dashboard/products/:id" component={ProductDetailPage} />
                <Route path="/dashboard/assets" component={AssetsPage} />
                <Route path="/dashboard/experiences" component={ExperiencesPage} />
                <Route path="/dashboard/experiences/:id" component={ExperienceDetailPage} />
                <Route path="/dashboard/publish" component={PublishPage} />
                <Route path="/dashboard/analytics" component={AnalyticsPage} />
                <Route path="/dashboard/settings" component={SettingsPage} />
              </Switch>
            </DashboardLayout>
          </ProtectedRoute>
        )}
      </Route>

      {/* Root redirects */}
      <Route path="/">
        {() => {
          const { isAuthenticated } = useAuth();
          return <Redirect to={isAuthenticated ? "/dashboard" : "/login"} />;
        }}
      </Route>
    </Switch>
  );
}

import { Authenticated } from "@refinedev/core";
import {
  AuthPage,
  ErrorComponent,
  ThemedLayoutV2,
  ThemedTitleV2,
} from "@refinedev/mantine";
import {
  CatchAllNavigate,
  NavigateToResource,
} from "@refinedev/react-router-v6";
import { Outlet, Route, Routes } from "react-router-dom";
import { AppIcon } from "./components/app-icon";
import { Header } from "./components/header";
import { ClientList } from "./pages/clients/list";
import { ClientCreate } from "./pages/clients/create";
import { ClientEdit } from "./pages/clients/edit";
import { ClientShow } from "./pages/clients/show";
import { CarList } from "./pages/cars/list";
import { CarCreate } from "./pages/cars/create";
import { CarEdit } from "./pages/cars/edit";
import { CarShow } from "./pages/cars/show";

export const AppRoutes = () => (
  <Routes>
    <Route
      element={
        <Authenticated
          key="authenticated-inner"
          fallback={<CatchAllNavigate to="/login" />}
        >
          <ThemedLayoutV2
            Header={() => <Header sticky />}
            Title={({ collapsed }) => (
              <ThemedTitleV2
                collapsed={collapsed}
                text="Garage Manager"
                icon={<AppIcon />}
              />
            )}
          >
            <Outlet />
          </ThemedLayoutV2>
        </Authenticated>
      }
    >
      <Route index element={<NavigateToResource resource="clients" />} />
      <Route path="/clients">
        <Route index element={<ClientList />} />
        <Route path="create" element={<ClientCreate />} />
        <Route path="edit/:id" element={<ClientEdit />} />
        <Route path="show/:id" element={<ClientShow />} />
      </Route>
      <Route path="/cars">
        <Route index element={<CarList />} />
        <Route path="create" element={<CarCreate />} />
        <Route path="edit/:id" element={<CarEdit />} />
        <Route path="show/:id" element={<CarShow />} />
      </Route>
      <Route path="*" element={<ErrorComponent />} />
    </Route>
    <Route
      element={
        <Authenticated key="authenticated-outer" fallback={<Outlet />}>
          <NavigateToResource />
        </Authenticated>
      }
    >
      <Route
        path="/login"
        element={
          <AuthPage
            type="login"
            title={
              <ThemedTitleV2
                collapsed={false}
                text="Garage Manager"
                icon={<AppIcon />}
              />
            }
            formProps={{
              initialValues: {
                email: "john@dow.com",
                password: "Password1!",
              },
            }}
          />
        }
      />
      <Route
        path="/forgot-password"
        element={<AuthPage type="forgotPassword" />}
      />
    </Route>
  </Routes>
);

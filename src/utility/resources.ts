export const resources = [
  {
    name: "clients",
    list: "/clients",
    create: "/clients/create",
    edit: "/clients/edit/:id",
    show: "/clients/show/:id",
    meta: {
      canDelete: true,
    },
  },
  {
    name: "cars",
    list: "/cars",
    create: "/cars/create",
    edit: "/cars/edit/:id",
    show: "/cars/show/:id",
    meta: {
      canDelete: true,
    },
  },
];

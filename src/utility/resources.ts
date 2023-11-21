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
  {
    name: "budgets",
    list: "/budgets",
    create: "/budgets/create",
    edit: "/budgets/edit/:id",
    show: "/budgets/show/:id",
    meta: {
      canDelete: true,
    },
  },
]

export type Client = {
  $id?: string
  id: string
  name: string
  phone: string
  cars?: Car[]
}

export type Car = {
  id: string
  brand: string
  model: string
  plate: string
  client: Client
}

export type Budget = {
  date: string
  total: number
  car: Car
  parts: Part[]
}

export type Part = {
  name: string
  quantity: number
  price: number
}

export type PartForm = {
  [x: string]: any
  name: string
  quantity: number
  price: string
}

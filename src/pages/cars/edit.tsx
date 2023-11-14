import {
  IResourceComponentsProps,
  useList,
  useTranslate,
} from "@refinedev/core"
import { Edit, useForm } from "@refinedev/mantine"
import { TextInput, Select, Loader } from "@mantine/core"

export const CarEdit: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const {
    getInputProps,
    saveButtonProps,
    setFieldValue,
    refineCore: { queryResult },
  } = useForm({
    initialValues: {
      id: "",
      brand: "",
      model: "",
      plate: "",
      client: { $id: "", name: "" },
    },
    validate: {
      brand: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      model: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      plate: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      client: (value) =>
        value[`$id`].length < 2 ? translate("pages.error.required") : null,
    },
    transformValues: (values) => ({
      brand: values.brand,
      model: values.model,
      plate: values.plate,
      client: values.client,
    }),
  })

  const carsData = queryResult?.data?.data

  const { data: clientsData } = useList({
    resource: "clients",
  })

  const clientsSelect = clientsData?.data.map((client) => ({
    label: client.name,
    value: client.id,
  })) as unknown as {
    label: string
    value: string
  }[]

  if (carsData)
    return (
      <Edit saveButtonProps={saveButtonProps}>
        <TextInput
          label={translate("cars.fields.id")}
          disabled
          {...getInputProps("id")}
        />

        <TextInput
          mt="sm"
          label={translate("cars.fields.brand")}
          required
          {...getInputProps("brand")}
        />

        <TextInput
          mt="sm"
          label={translate("cars.fields.model")}
          required
          {...getInputProps("model")}
        />

        <TextInput
          mt="sm"
          label={translate("cars.fields.plate")}
          required
          {...getInputProps("plate")}
        />

        {clientsData && (
          <Select
            mt="sm"
            label={translate("cars.fields.client")}
            defaultValue={carsData?.client["$id"]}
            required
            data={clientsSelect}
            onChange={(v) => {
              const client = clientsSelect.find((c) => c.value === v)!
              setFieldValue("client", {
                $id: client?.value,
                name: client?.label,
              })
            }}
          />
        )}
      </Edit>
    )

  return <Loader />
}

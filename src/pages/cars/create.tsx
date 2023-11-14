import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { Create, useForm, useSelect } from "@refinedev/mantine"
import { TextInput, Select } from "@mantine/core"

export const CarCreate: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const {
    getInputProps,
    saveButtonProps,
    refineCore: { formLoading },
  } = useForm({
    initialValues: {
      brand: "",
      model: "",
      plate: "",
      client: { id: "" },
    },
    validate: {
      brand: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      model: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      plate: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      client: (value) =>
        value.id.length < 2 ? translate("pages.error.required") : null,
    },
    transformValues: (values) => {
      const client = clientSelectProps.data.find(
        (c) => c.value === values.client.id
      )!

      return {
        brand: values.brand,
        model: values.model,
        plate: values.plate,
        client: { id: client.value, name: client.label },
      }
    },
  })

  const { selectProps: clientSelectProps } = useSelect({
    resource: "clients",
    optionLabel: "name",
  })

  return (
    <Create isLoading={formLoading} saveButtonProps={saveButtonProps}>
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

      <Select
        mt="sm"
        label={translate("cars.fields.client")}
        required
        {...getInputProps("client.id")}
        {...clientSelectProps}
      />
    </Create>
  )
}

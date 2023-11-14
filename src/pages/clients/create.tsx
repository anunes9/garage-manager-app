import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { Create, useForm } from "@refinedev/mantine"
import { TextInput } from "@mantine/core"

export const ClientCreate: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const {
    getInputProps,
    saveButtonProps,
    refineCore: { formLoading },
  } = useForm({
    initialValues: { name: "", phone: "" },
    validate: {
      name: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      phone: (value) =>
        value.length !== 9 ? translate("pages.error.required") : null,
    },
  })

  return (
    <Create isLoading={formLoading} saveButtonProps={saveButtonProps}>
      <TextInput
        mt="sm"
        label={translate("clients.fields.name")}
        required
        {...getInputProps("name")}
      />

      <TextInput
        mt="sm"
        label={translate("clients.fields.phone")}
        required
        minLength={9}
        maxLength={9}
        {...getInputProps("phone")}
      />
    </Create>
  )
}

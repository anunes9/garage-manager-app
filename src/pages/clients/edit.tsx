import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { Edit, useForm } from "@refinedev/mantine"
import { TextInput } from "@mantine/core"

export const ClientEdit: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const { getInputProps, saveButtonProps } = useForm({
    initialValues: { id: "", name: "", phone: "", car: [] },
    validate: {
      name: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      phone: (value) =>
        value.length !== 9 ? translate("pages.error.required") : null,
    },
  })

  return (
    <Edit saveButtonProps={saveButtonProps}>
      <TextInput
        label={translate("clients.fields.id")}
        disabled
        {...getInputProps("id")}
      />

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
    </Edit>
  )
}

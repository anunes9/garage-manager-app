import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { Create, SaveButton, useForm } from "@refinedev/mantine"
import { Button, Group, TextInput } from "@mantine/core"
import { useNavigate } from "react-router-dom"

export const ClientCreate: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
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
    <Create
      isLoading={formLoading}
      saveButtonProps={saveButtonProps}
      footerButtons={() => (
        <Group>
          <Button color="gray" onClick={() => navigate("/cars")}>
            {translate("buttons.cancel")}
          </Button>

          <SaveButton {...saveButtonProps} />
        </Group>
      )}
    >
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

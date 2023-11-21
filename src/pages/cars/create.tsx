import {
  IResourceComponentsProps,
  useList,
  useTranslate,
} from "@refinedev/core"
import { Create, SaveButton, useForm } from "@refinedev/mantine"
import { TextInput, Select, LoadingOverlay, Group, Button } from "@mantine/core"
import { useNavigate } from "react-router-dom"

export const CarCreate: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
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
      client: "",
    },
    validate: {
      brand: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      model: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      plate: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      client: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
    },
  })

  const { data: clientsData, isLoading } = useList({
    resource: "clients",
  })

  return (
    <Create
      isLoading={formLoading || formLoading}
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
      <LoadingOverlay visible={isLoading} />

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
        // @ts-expect-error data is correct
        data={
          isLoading
            ? []
            : clientsData?.data.map((c) => ({
                value: c.id,
                label: `${c.name} ${c.phone}`,
              }))
        }
        {...getInputProps("client")}
      />
    </Create>
  )
}

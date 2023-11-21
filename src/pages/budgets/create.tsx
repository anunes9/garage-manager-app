import {
  IResourceComponentsProps,
  useList,
  useTranslate,
} from "@refinedev/core"
import { Create, useForm } from "@refinedev/mantine"
import {
  TextInput,
  NumberInput,
  Select,
  Table,
  Text,
  ActionIcon,
  Button,
} from "@mantine/core"
import { Part, PartForm } from "../../utility/resources"
import { IconTrash } from "@tabler/icons"
import { randomId } from "@mantine/hooks"

export const BudgetCreate: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const {
    errors,
    values,
    getInputProps,
    saveButtonProps,
    removeListItem,
    insertListItem,
    setFieldError,
    refineCore: { formLoading },
  } = useForm({
    initialValues: {
      date: new Date().toISOString().split("T")[0],
      car: "",
      km: 0,
      part: [] as unknown as PartForm,
    },
    validate: {
      km: (value) => (value > 0 ? null : translate("pages.error.required")),
      car: (value) =>
        value.length < 2 ? translate("pages.error.required") : null,
      part: {
        name: (value) =>
          value.length < 2 ? translate("pages.error.required") : null,
        quantity: (value: number) =>
          value > 0 ? null : translate("pages.error.required"),
      },
    },
    transformValues: (values) => {
      if (values.part.length === 0) {
        setFieldError("part", translate("pages.error.required"))
        return {}
      }

      const total = values.part.reduce(
        (accumulator: number, currentValue: PartForm) =>
          accumulator + parseFloat(currentValue.price),
        0
      )

      return {
        date: values.date,
        km: values.km,
        total,
        car: values.car,
        part: values.part.map((p: PartForm) => ({
          name: p.name,
          quantity: p.quantity,
          price: p.price,
        })),
      }
    },
  })

  const { data: carsData, isLoading } = useList({
    resource: "cars",
  })

  return (
    <Create
      isLoading={isLoading || formLoading}
      saveButtonProps={saveButtonProps}
    >
      <TextInput
        mt="sm"
        type="date"
        label={translate("budgets.fields.date")}
        {...getInputProps("date")}
      />

      <Select
        mt="sm"
        label={translate("budgets.fields.car")}
        {...getInputProps("car")}
        // @ts-expect-error data is correct
        data={
          isLoading
            ? []
            : carsData?.data.map((c) => ({
                value: c.id,
                label: c.plate,
              }))
        }
      />

      <NumberInput
        mt="sm"
        type="number"
        label={translate("budgets.fields.km")}
        {...getInputProps("km")}
      />

      <Text mt="md" fw={500} size="sm" color={errors?.part ? "red" : "black"}>
        {translate("budgets.fields.part")}
      </Text>

      <Table highlightOnHover>
        <thead>
          <tr>
            <th>{translate(`parts.fields.name`)}</th>
            <th>{translate(`parts.fields.quantity`)}</th>
            <th>{translate(`parts.fields.price`)}</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {values.part.length === 0 && (
            <tr>
              <td colSpan={4}>
                <Text color={errors?.part ? "red" : "black"}>
                  {translate(`parts.empty`)}
                </Text>
              </td>
            </tr>
          )}

          {values?.part?.map((p: Part, index: number) => (
            <tr key={index}>
              <td>
                <TextInput
                  withAsterisk
                  placeholder={translate(`parts.parts`)}
                  {...getInputProps(`part.${index}.name`)}
                />
              </td>
              <td>
                <NumberInput
                  min={1}
                  {...getInputProps(`part.${index}.quantity`)}
                />
              </td>
              <td>
                <TextInput
                  min={0}
                  type="number"
                  rightSection="€"
                  {...getInputProps(`part.${index}.price`)}
                />
              </td>
              <td>
                <ActionIcon
                  color="red"
                  onClick={() => removeListItem("part", index)}
                >
                  <IconTrash size="1rem" />
                </ActionIcon>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>

      <Button
        mt="lg"
        onClick={() =>
          insertListItem("part", {
            name: "",
            quantity: 1,
            price: "0",
            key: randomId(),
          })
        }
      >
        {translate(`parts.add`)}
      </Button>
    </Create>
  )
}

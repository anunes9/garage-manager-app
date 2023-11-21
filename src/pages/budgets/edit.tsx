import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import {
  DateField,
  Edit,
  TextField,
  useForm,
  useSelect,
} from "@refinedev/mantine"
import {
  TextInput,
  NumberInput,
  Group,
  Select,
  Grid,
  Title,
  Badge,
  Table,
  Text,
  ActionIcon,
  Button,
} from "@mantine/core"
import { Container } from "postcss"
import { IconTrash } from "@tabler/icons"
import { Part, PartForm } from "../../utility/resources"
import { randomId } from "@mantine/hooks"

export const BudgetEdit: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const {
    errors,
    values,
    getInputProps,
    saveButtonProps,
    removeListItem,
    insertListItem,
    setFieldError,
    refineCore: { queryResult },
  } = useForm({
    initialValues: {
      date: "",
      part: [] as unknown as PartForm,
    },
    validate: {
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
        total,
        part: values.part.map((p: PartForm) => ({
          name: p.name,
          quantity: p.quantity,
          price: p.price,
        })),
      }
    },
  })

  const budgetsData = queryResult?.data?.data

  return (
    <Edit saveButtonProps={saveButtonProps}>
      <Grid align="center" gutter="xs">
        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.id")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <TextField value={budgetsData?.id} />
        </Grid.Col>

        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.date")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <DateField value={values?.date} />
        </Grid.Col>

        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.car")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <Group>
            <Badge variant="outline" color="blue" size="lg">
              <Text fw={500}>{budgetsData?.car.plate}</Text>
            </Badge>

            <Text
              fw={300}
            >{`${budgetsData?.car.brand} ${budgetsData?.car.model}`}</Text>
          </Group>
        </Grid.Col>
      </Grid>

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
    </Edit>
  )
}

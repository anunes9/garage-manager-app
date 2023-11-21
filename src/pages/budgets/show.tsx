import {
  IResourceComponentsProps,
  useShow,
  useTranslate,
} from "@refinedev/core"
import { Show, TextField, DateField } from "@refinedev/mantine"
import {
  Title,
  Group,
  Grid,
  Badge,
  Text,
  Table,
  Container,
} from "@mantine/core"
import { useNavigate } from "react-router-dom"
import { Part } from "../../utility/resources"

export const BudgetShow: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
  const translate = useTranslate()
  const { queryResult } = useShow()
  const { data, isLoading } = queryResult

  const record = data?.data

  return (
    <Show isLoading={isLoading}>
      <Grid align="center" gutter="xs">
        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.id")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <TextField value={record?.id} />
        </Grid.Col>

        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.date")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <DateField value={record?.date} />
        </Grid.Col>

        <Grid.Col span={1}>
          <Title my="xs" order={5}>
            {translate("budgets.fields.car")}
          </Title>
        </Grid.Col>
        <Grid.Col span={11}>
          <Group onClick={() => navigate(`/cars/show/${record?.car.id}`)}>
            <Badge variant="outline" color="blue" size="lg">
              <Text fw={500}>{record?.car.plate}</Text>
            </Badge>

            <Text fw={300}>{`${record?.car.brand} ${record?.car.model}`}</Text>
          </Group>
        </Grid.Col>
      </Grid>

      <Title my="md" order={5}>
        {translate("budgets.fields.part")}
      </Title>

      <Container size="md">
        <Table highlightOnHover>
          <thead>
            <tr>
              {["name", "quantity", "price"].map((h, index) => (
                <th key={index}>{translate(`parts.fields.${h}`)}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {record?.part?.map((p: Part, index: number) => (
              <tr key={index}>
                <td>{p.name}</td>
                <td>{p.quantity}</td>
                <td>{`${p.price} €`}</td>
              </tr>
            ))}

            <tr>
              <td colSpan={2}>
                <Text fw={500} size="md">
                  {translate("budgets.fields.total")}
                </Text>
              </td>
              <td>
                <Text fw={500} size="md">
                  {`${record?.total} €`}
                </Text>
              </td>
            </tr>
          </tbody>
        </Table>
      </Container>
    </Show>
  )
}

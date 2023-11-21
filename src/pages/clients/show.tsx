import {
  IResourceComponentsProps,
  useShow,
  useTranslate,
  useMany,
} from "@refinedev/core"
import { Show, TextField } from "@refinedev/mantine"
import { Title, Stack, Text, Badge, Group, Grid } from "@mantine/core"
import { Client } from "../../utility/resources"
import { useNavigate } from "react-router-dom"

export const ClientShow: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
  const translate = useTranslate()
  const { queryResult } = useShow()
  const { data, isLoading } = queryResult

  const record = data?.data

  const { data: carData, isLoading: carIsLoading } = useMany({
    resource: "cars",
    ids: record?.car.map((c: Client) => c["$id"]) || [],
    queryOptions: {
      enabled: !!record && !!record?.car?.length,
    },
  })

  return (
    <Show
      isLoading={isLoading}
      title={
        <Title order={3}>
          {isLoading ? translate("clients.titles.show") : record?.name}
        </Title>
      }
    >
      <Group>
        <Title my="xs" order={5}>
          {translate("clients.fields.id")}
        </Title>
        <TextField value={record?.id} />
      </Group>

      <Grid>
        <Grid.Col span={6}>
          <Title my="xs" order={5}>
            {translate("clients.fields.name")}
          </Title>
          <TextField value={record?.name} />
        </Grid.Col>
        <Grid.Col span={6}>
          <Title my="xs" order={5}>
            {translate("clients.fields.phone")}
          </Title>
          <TextField value={record?.phone ?? ""} />
        </Grid.Col>
      </Grid>

      <Title my="xs" order={5} pt="lg">
        {translate("clients.fields.car")}
      </Title>

      {carIsLoading && record?.car?.length ? (
        <>Loading...</>
      ) : (
        <Stack align="start">
          {carData?.data?.map((item: any, index: number) => (
            <Group
              onClick={() => navigate(`/cars/show/${item.id}`)}
              key={index}
            >
              <Badge variant="outline" color="blue" size="xl">
                <Text fw={500}>{item.plate}</Text>
              </Badge>

              <Text fw={300}>{`${item.brand} ${item.model}`}</Text>
            </Group>
          ))}

          {!carData?.data && <Text fw={500}>--</Text>}
        </Stack>
      )}
    </Show>
  )
}

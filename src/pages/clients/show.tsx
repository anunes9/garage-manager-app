import {
  IResourceComponentsProps,
  useShow,
  useTranslate,
  useMany,
} from "@refinedev/core"
import { Show, TextField, NumberField } from "@refinedev/mantine"
import { Title, Stack, Text } from "@mantine/core"
import { Client } from "../../utility/resources"

export const ClientShow: React.FC<IResourceComponentsProps> = () => {
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
    <Show isLoading={isLoading}>
      <Title my="xs" order={5}>
        {translate("clients.fields.id")}
      </Title>
      <TextField value={record?.id} />

      <Title my="xs" order={5}>
        {translate("clients.fields.name")}
      </Title>
      <TextField value={record?.name} />

      <Title my="xs" order={5}>
        {translate("clients.fields.phone")}
      </Title>
      <NumberField value={record?.phone ?? ""} />

      <Title my="xs" order={5}>
        {translate("clients.fields.car")}
      </Title>

      {carIsLoading && record?.car?.length ? (
        <>Loading...</>
      ) : (
        <Stack>
          {carData?.data?.map((item: any, index: number) => (
            <Text fw={500} key={index}>
              {item.plate}

              <Text
                fw={300}
                component="span"
              >{` - ${item.brand} ${item.model}`}</Text>
            </Text>
          ))}
        </Stack>
      )}
    </Show>
  )
}

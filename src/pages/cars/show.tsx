import {
  IResourceComponentsProps,
  useShow,
  useTranslate,
} from "@refinedev/core"
import { Show, TextField } from "@refinedev/mantine"
import { Title } from "@mantine/core"

export const CarShow: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const { queryResult } = useShow()
  const { data, isLoading } = queryResult

  const record = data?.data

  return (
    <Show isLoading={isLoading}>
      <Title my="xs" order={5}>
        {translate("cars.fields.id")}
      </Title>
      <TextField value={record?.id} />

      <Title my="xs" order={5}>
        {translate("cars.fields.brand")}
      </Title>
      <TextField value={record?.brand} />
      <Title my="xs" order={5}>
        {translate("cars.fields.model")}
      </Title>
      <TextField value={record?.model} />

      <Title my="xs" order={5}>
        {translate("cars.fields.plate")}
      </Title>
      <TextField value={record?.plate} />

      <Title my="xs" order={5}>
        {translate("cars.fields.client")}
      </Title>
      <TextField value={record?.client?.name} />
    </Show>
  )
}

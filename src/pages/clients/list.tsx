import React from "react"
import {
  IResourceComponentsProps,
  useTranslate,
  useMany,
} from "@refinedev/core"
import { useTable } from "@refinedev/react-table"
import { ColumnDef, flexRender } from "@tanstack/react-table"
import {
  ScrollArea,
  Table,
  Pagination,
  LoadingOverlay,
  Stack,
} from "@mantine/core"
import { List, TagField } from "@refinedev/mantine"
import { Car, Client } from "../../utility/resources"
import { useNavigate } from "react-router-dom"

export const ClientList: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
  const translate = useTranslate()
  const columns = React.useMemo<ColumnDef<Client>[]>(
    () => [
      {
        id: "name",
        accessorKey: "name",
        header: translate("clients.fields.name"),
      },
      {
        id: "phone",
        accessorKey: "phone",
        header: translate("clients.fields.phone"),
      },
      {
        id: "car",
        header: translate("clients.fields.car"),
        accessorKey: "car",
        cell: function render({ getValue }) {
          const cars = getValue() as Car[]

          return (
            <Stack align="start">
              {cars.map((item, index) => (
                <TagField key={index} value={item.plate} />
              ))}
            </Stack>
          )
        },
      },
      // {
      //   id: "actions",
      //   accessorKey: "id",
      //   header: translate("table.actions"),
      //   cell: function render({ getValue }) {
      //     return (
      //       <Group spacing="xs" noWrap>
      //         <ShowButton hideText recordItemId={getValue() as string} />
      //         <EditButton hideText recordItemId={getValue() as string} />
      //         <DeleteButton hideText recordItemId={getValue() as string} />
      //       </Group>
      //     )
      //   },
      // },
    ],
    [translate]
  )

  const {
    getHeaderGroups,
    getRowModel,
    setOptions,
    refineCore: {
      setCurrent,
      pageCount,
      current,
      tableQueryResult: { data: tableData, isLoading },
    },
  } = useTable({
    columns,
  })

  const { data: carData } = useMany({
    resource: "cars",
    ids: [].concat(
      ...(tableData?.data?.map((item: any) =>
        item?.car.map((c: Client) => c["$id"])
      ) ?? [])
    ),
    queryOptions: {
      enabled: !!tableData?.data,
    },
  })

  setOptions((prev) => ({
    ...prev,
    meta: {
      ...prev.meta,
      carData,
    },
  }))

  return (
    <List>
      <LoadingOverlay visible={isLoading} />

      <ScrollArea>
        <Table highlightOnHover>
          <thead>
            {getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th key={header.id}>
                    {!header.isPlaceholder &&
                      flexRender(
                        header.column.columnDef.header,
                        header.getContext()
                      )}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {getRowModel().rows.map((row) => (
              <tr key={row.id}>
                {row.getVisibleCells().map((cell) => (
                  <td
                    key={cell.id}
                    onClick={() => navigate(`show/${row.original.id}`)}
                  >
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </Table>
      </ScrollArea>

      <Pagination
        pt="lg"
        position="right"
        total={pageCount}
        page={current}
        onChange={setCurrent}
      />
    </List>
  )
}

import React from "react"
import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { useTable } from "@refinedev/react-table"
import { ColumnDef, flexRender } from "@tanstack/react-table"
import { ScrollArea, Table, Pagination, Group } from "@mantine/core"
import { List, EditButton, ShowButton, DeleteButton } from "@refinedev/mantine"
import { Client } from "../../utility/resources"

export const CarList: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate()
  const columns = React.useMemo<ColumnDef<Client>[]>(
    () => [
      {
        id: "id",
        accessorKey: "id",
        header: translate("cars.fields.id"),
      },
      {
        id: "brand",
        accessorKey: "brand",
        header: translate("cars.fields.brand"),
      },
      {
        id: "model",
        accessorKey: "model",
        header: translate("cars.fields.model"),
      },
      {
        id: "plate",
        accessorKey: "plate",
        header: translate("cars.fields.plate"),
      },
      {
        id: "client",
        header: translate("cars.fields.client"),
        accessorKey: "client.name",
      },
      {
        id: "actions",
        accessorKey: "id",
        header: translate("table.actions"),
        cell: function render({ getValue }) {
          return (
            <Group spacing="xs" noWrap>
              <ShowButton hideText recordItemId={getValue() as string} />
              <EditButton hideText recordItemId={getValue() as string} />
              <DeleteButton hideText recordItemId={getValue() as string} />
            </Group>
          )
        },
      },
    ],
    [translate]
  )

  const {
    getHeaderGroups,
    getRowModel,
    setOptions,
    refineCore: { setCurrent, pageCount, current },
  } = useTable({
    columns,
  })

  setOptions((prev) => ({
    ...prev,
    meta: {
      ...prev.meta,
    },
  }))

  return (
    <List>
      <ScrollArea>
        <Table highlightOnHover>
          <thead>
            {getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => {
                  return (
                    <th key={header.id}>
                      {!header.isPlaceholder &&
                        flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                    </th>
                  )
                })}
              </tr>
            ))}
          </thead>
          <tbody>
            {getRowModel().rows.map((row) => {
              return (
                <tr key={row.id}>
                  {row.getVisibleCells().map((cell) => {
                    return (
                      <td key={cell.id}>
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </td>
                    )
                  })}
                </tr>
              )
            })}
          </tbody>
        </Table>
      </ScrollArea>

      <br />

      <Pagination
        position="right"
        total={pageCount}
        page={current}
        onChange={setCurrent}
      />
    </List>
  )
}

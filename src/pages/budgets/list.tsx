import React from "react"
import { IResourceComponentsProps, useTranslate } from "@refinedev/core"
import { useTable } from "@refinedev/react-table"
import { ColumnDef, flexRender } from "@tanstack/react-table"
import {
  ScrollArea,
  Table,
  Pagination,
  LoadingOverlay,
  Text,
} from "@mantine/core"
import { List } from "@refinedev/mantine"
import { Client } from "../../utility/resources"
import { useNavigate } from "react-router-dom"

export const BudgetList: React.FC<IResourceComponentsProps> = () => {
  const navigate = useNavigate()
  const translate = useTranslate()
  const columns = React.useMemo<ColumnDef<Client>[]>(
    () => [
      {
        id: "car",
        accessorKey: "car.plate",
        header: translate("budgets.fields.car"),
      },
      {
        id: "date",
        header: translate("budgets.fields.date"),
        cell: function render({ getValue }) {
          return <Text>{new Date(getValue() as string).toDateString()}</Text>
        },
        accessorKey: "date",
      },
      {
        id: "km",
        header: translate("budgets.fields.km"),
        accessorKey: "km",
      },
      {
        id: "total",
        accessorKey: "total",
        header: translate("budgets.fields.total"),
        cell: function render({ getValue }) {
          return <Text>{`${getValue()} €`}</Text>
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
      tableQueryResult: { isLoading },
    },
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

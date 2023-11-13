import React from "react";
import {
  IResourceComponentsProps,
  useTranslate,
  GetManyResponse,
  useMany,
} from "@refinedev/core";
import { useTable } from "@refinedev/react-table";
import { ColumnDef, flexRender } from "@tanstack/react-table";
import { ScrollArea, Table, Pagination, Group } from "@mantine/core";
import {
  List,
  EditButton,
  ShowButton,
  DeleteButton,
  TagField,
} from "@refinedev/mantine";

export const ClientList: React.FC<IResourceComponentsProps> = () => {
  const translate = useTranslate();
  const columns = React.useMemo<ColumnDef<any>[]>(
    () => [
      {
        id: "id",
        accessorKey: "id",
        header: translate("clients.fields.id"),
      },
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
        cell: function render({ getValue, table }) {
          const meta = table.options.meta as {
            carData: GetManyResponse;
          };

          const car = getValue<any[]>()?.map((item) => {
            return meta.carData?.data?.find(
              (resourceItems) => resourceItems.id === item
            );
          });

          return (
            <Group spacing="xs">
              {car?.map((item, index) => (
                <TagField key={index} value={item} />
              ))}
            </Group>
          );
        },
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
          );
        },
      },
    ],
    [translate]
  );

  const {
    getHeaderGroups,
    getRowModel,
    setOptions,
    refineCore: {
      setCurrent,
      pageCount,
      current,
      tableQueryResult: { data: tableData },
    },
  } = useTable({
    columns,
  });

  const { data: carData } = useMany({
    resource: "cars",
    ids: [].concat(
      ...(tableData?.data?.map((item: any) =>
        item?.car.map((c: any) => c["$id"])
      ) ?? [])
    ),
    queryOptions: {
      enabled: !!tableData?.data,
    },
  });

  setOptions((prev) => ({
    ...prev,
    meta: {
      ...prev.meta,
      carData,
    },
  }));

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
                  );
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
                    );
                  })}
                </tr>
              );
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
  );
};

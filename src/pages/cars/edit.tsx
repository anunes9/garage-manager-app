import { IResourceComponentsProps } from "@refinedev/core";
import { MantineEditInferencer } from "@refinedev/inferencer/mantine";

export const CarEdit: React.FC<IResourceComponentsProps> = () => {
  return (
    <MantineEditInferencer
      fieldTransformer={(field) => {
        if (["$permissions", "$updatedAt", "$createdAt"].includes(field.key)) {
          return false;
        }
        return field;
      }}
    />
  );
};
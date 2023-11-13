import { IResourceComponentsProps } from "@refinedev/core";
import { MantineShowInferencer } from "@refinedev/inferencer/mantine";

export const CarShow: React.FC<IResourceComponentsProps> = () => {
  return (
    <MantineShowInferencer
      fieldTransformer={(field) => {
        if (["$permissions", "$updatedAt", "$createdAt"].includes(field.key)) {
          return false;
        }
        return field;
      }}
    />
  );
};
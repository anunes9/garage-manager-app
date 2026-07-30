ActiveAdmin.register Client do
  permit_params :name, :phone

  index do
    selectable_column
    id_column
    column :name
    column :phone
    column :created_at
    actions
  end

  filter :name
  filter :phone
  filter :created_at

  show do
    attributes_table do
      row :name
      row :phone
      row :created_at
      row :updated_at
    end

    panel "Cars" do
      table_for client.cars do
        column :brand
        column :model
        column :plate
        column :year
        column do |car|
          link_to "View", admin_car_path(car)
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :phone
    end
    f.actions
  end
end

ActiveAdmin.register Car do
  permit_params :brand, :model, :plate, :vin, :motor, :year, :month, :notes, :client_id

  index do
    selectable_column
    id_column
    column :brand
    column :model
    column :plate
    column :year
    column :client
    column :created_at
    actions
  end

  filter :brand
  filter :model
  filter :plate
  filter :vin
  filter :year
  filter :client

  show do
    attributes_table do
      row :brand
      row :model
      row :plate
      row :vin
      row :motor
      row :year
      row :month
      row :client
      row :notes
      row :created_at
      row :updated_at
    end

    panel "Repairs" do
      table_for car.repairs do
        column :date
        column :km
        column :total
        column do |repair|
          link_to "View", admin_repair_path(repair)
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :client
      f.input :brand
      f.input :model
      f.input :plate
      f.input :vin
      f.input :motor
      f.input :year
      f.input :month
      f.input :notes
    end
    f.actions
  end
end

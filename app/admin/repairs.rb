ActiveAdmin.register Repair do
  permit_params :car_id, :date, :km, :notes,
                parts_attributes: %i[id name quantity price _destroy]

  index do
    selectable_column
    id_column
    column :car
    column :date
    column :km
    column :total
    column :created_at
    actions
  end

  filter :car
  filter :date
  filter :km

  show do
    attributes_table do
      row :car
      row :date
      row :km
      row :total
      row :notes
      row :created_at
      row :updated_at
    end

    panel "Parts" do
      table_for repair.parts do
        column :name
        column :quantity
        column :price
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :car
      f.input :date
      f.input :km
      f.input :notes
    end

    f.inputs "Parts" do
      f.has_many :parts, allow_destroy: true, new_record: true do |p|
        p.input :name
        p.input :quantity
        p.input :price
      end
    end

    f.actions
  end
end

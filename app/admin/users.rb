ActiveAdmin.register User do
  permit_params :name, :email, :password, :password_confirmation, :role, :notes

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :role
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :role, as: :select, collection: User.roles.keys

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :role, as: :select, collection: User.roles.keys, include_blank: false
      f.input :notes
    end
    f.actions
  end

  controller do
    # Devise requires a password on update unless it's stripped from params entirely
    # (a blank password param is otherwise treated as "change the password to blank").
    def update_resource(object, attributes)
      if attributes.first[:password].blank?
        attributes[0] = attributes.first.except(:password, :password_confirmation)
      end
      super
    end
  end
end

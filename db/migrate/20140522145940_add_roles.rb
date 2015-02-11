class AddRoles < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.integer :parent_id # to build tree structure
      t.string  :name, :null => false

      t.string  :action # can :action, subject_class.constantize
      t.string  :subject_class # can :action, subject_class.constantize
      t.string  :subject_name # access to some subject, not model, can :action, subject_name.to_sym
      t.boolean :is_instance, :default => false, :null => false # can :action, subject_class.constantize { |instance| true/false }

      t.boolean :folder, :null => false, :default => false
      t.integer :position, :null => false, :default => 0
      t.integer :depends_on_id # to enable/disable subsections

      t.timestamps
    end

    create_table :roles do |t|
      t.string  :name
      t.string  :description

      t.timestamps
    end

    create_table :role_permissions do |t|
      t.references :role
      t.references :permission

      t.timestamps
    end

    create_table :group_roles do |t|
      t.references :group
      t.references :role

      t.timestamps
    end

    # :team_groups exists as :teams_groups
    # :team_apps exists as :development_teams
    # :user_groups exists
  end
end
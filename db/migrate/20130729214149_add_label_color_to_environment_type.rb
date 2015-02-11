class AddLabelColorToEnvironmentType < ActiveRecord::Migration
  def change
    add_column :environment_types, :label_color, :string, default: '#C7A465', null: false
  end
end

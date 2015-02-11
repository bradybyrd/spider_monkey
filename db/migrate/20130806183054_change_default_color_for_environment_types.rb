class ChangeDefaultColorForEnvironmentTypes < ActiveRecord::Migration
  def up
    change_column :environment_types, :label_color, :string, :null => false, :default => '#D3D3D3'
  end

  def down
    change_column :environment_types, :label_color, :string, :null => false, :default => '#C7A465'
  end
end

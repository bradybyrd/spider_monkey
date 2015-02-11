class AdjustNullPermissionsOnLifecycle < ActiveRecord::Migration
  def self.up
    change_table :lifecycles do |t|
      t.change :name, :string, :null => false
    end
  end

  def self.down
    change_table :lifecycles do |t|
      t.change :name, :string, :null => true
    end
  end
end

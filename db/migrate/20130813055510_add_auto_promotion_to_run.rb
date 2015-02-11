class AddAutoPromotionToRun < ActiveRecord::Migration
  def change
    add_column :runs, :auto_promote, :boolean, :default => false, :null => false
    add_index :runs, :auto_promote, :name => 'I_RUN_AUTO_PROMOTE'
  end
end

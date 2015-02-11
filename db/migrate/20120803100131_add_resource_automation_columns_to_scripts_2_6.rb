class AddResourceAutomationColumnsToScripts26 < ActiveRecord::Migration
  def change
  	add_column :scripts, :unique_identifier, :string
  	add_column :scripts, :render_as, :string
  	add_column :scripts, :maps_to, :string
  end
end

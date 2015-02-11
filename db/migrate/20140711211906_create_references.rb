class CreateReferences < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.string :name, limit: 255, null: false
      t.string :url, null: false
      t.references :package, null: false, index: true
      t.references :server, index: true

      t.timestamps
    end
  end
end

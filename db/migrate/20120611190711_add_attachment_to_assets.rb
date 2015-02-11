class AddAttachmentToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :attachment, :string
    add_index :assets, :attachment

    ActiveRecord::Base.connection.execute("update assets set attachment=filename")
  end
end

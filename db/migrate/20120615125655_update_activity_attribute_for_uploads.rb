class UpdateActivityAttributeForUploads < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists?('activity_attributes') == true
      ActiveRecord::Base.connection.execute("update activity_attributes set name = 'uploads', field = 'uploads' where name LIKE 'assets'")
      puts "Renamed assets to uploads in activity_attributes successfully."
    else
      puts "The table activity_attributes does not exist. Skipping..."
    end
  end

  def down    
    if ActiveRecord::Base.connection.table_exists?('activity_attributes') == true
      ActiveRecord::Base.connection.execute("update activity_attributes set name = 'assets', field = 'assets' where name LIKE 'uploads'")
      puts "Restored value of assets from uploads in activity_attributes successfully."
    else
      puts "The table activity_attributes does not exist. Skipping..."
    end
  end
end

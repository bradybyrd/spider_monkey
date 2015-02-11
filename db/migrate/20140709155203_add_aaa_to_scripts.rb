class AddAaaToScripts < ActiveRecord::Migration
  def self.up
    add_column :scripts, :archive_number, :string
    add_column :scripts, :archived_at, :datetime
    load 'script.rb'
    success_flag =true
    Script.all.each{|script|
      if !script.is_active
        script.archived_at = DateTime.now
        success_flag &= (success = script.save!)
        if success
          say "#{script.inspect} Saved successfully!"
        else
          say "ERROR: #{script.errors.inspect}"
        end
      end
    }
    raise "ERROR because of success_flag" unless success_flag
    remove_column :scripts, :is_active
    add_index :scripts, :archive_number
    add_index :scripts, :archived_at
  end

  def self.down
    remove_index :scripts, :archived_at
    remove_index :scripts, :archive_number
    add_column :scripts, :is_active, :boolean
    load 'script.rb'
    Script.all.each{|script|
      unless script.archived_at.nil?
        script.is_active = true
        script.save!
      end
    }
    remove_column :scripts, :archived_at
    remove_column :scripts, :archive_number
  end
end
class AddAaaToRequestTemplates < ActiveRecord::Migration
  def self.up
    add_column :request_templates, :archive_number, :string
    add_column :request_templates, :archived_at, :datetime
    load 'request_template.rb'
    success_flag =true
    RequestTemplate.all.each{|rt|
      if !rt.active
        rt.archived_at = DateTime.now
        success_flag &= (success = rt.save!)
        if success
          say "#{rt.inspect} Saved successfully!"
        else
          say "ERROR: #{rt.errors.inspect}"
        end
      end
    }
    raise "ERROR because of success_flag" unless success_flag
    remove_column :request_templates, :active
    add_index :request_templates, :archive_number
    add_index :request_templates, :archived_at
  end

  def self.down
    remove_index :request_templates, :archived_at
    remove_index :request_templates, :archive_number
    add_column :request_templates, :active, :boolean
    load 'request_template.rb'
    RequestTemplate.all.each{|rt|
      unless rt.archived_at.nil?
        rt.active = true
        rt.save!
      end
    }
    remove_column :request_templates, :archived_at
    remove_column :request_templates, :archive_number
  end
end
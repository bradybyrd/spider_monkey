class CreateNotificationTemplates < ActiveRecord::Migration
  def self.up
    create_table :notification_templates do |t|
      t.string :title, :null => false
      t.string :method, :null => false, :default => 'email_text'
      t.string :event, :null => false
      t.text :description
      t.text :body
      t.text :template
      t.boolean :active, :null => false, :default => false
      t.timestamps
    end
    
    add_index :notification_templates, :method, :name => :i_nt_method
    add_index :notification_templates, :title, :name => :i_nt_title
    add_index :notification_templates, :event, :name => :i_nt_event 
  end

  def self.down
    drop_table :notification_templates
  end
end

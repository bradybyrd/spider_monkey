class CreateTableLifecycleStagesRequestTemplates < ActiveRecord::Migration
  def self.up
    create_table :lc_stages_request_templates do |t|
      t.integer :lifecycle_stage_id
      t.integer :request_template_id
    end
  end

  def self.down
    drop_table :lc_stages_request_templates
  end
end

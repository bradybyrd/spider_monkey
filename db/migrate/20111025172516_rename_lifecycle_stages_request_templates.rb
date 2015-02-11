class RenameLifecycleStagesRequestTemplates < ActiveRecord::Migration
  def self.up
    if !OracleAdapter && ActiveRecord::Base.connection.tables.include?("lifecycle_stages_request_templates")
      rename_table("lifecycle_stages_request_templates", "lc_stages_request_templates") 
    end
  end

  def self.down
    rename_table("lc_stages_request_templates", "lifecycle_stages_request_templates") unless OracleAdapter
  end
end

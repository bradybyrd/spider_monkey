class AddCommitOnCompletionColumnToGlobalSetting < ActiveRecord::Migration
  def self.up
  	add_column :global_settings, :commit_on_completion, :boolean, :default => true
  	connection.execute("UPDATE global_settings SET commit_on_completion = #{RPMTRUE}")
  end

  def self.down
  	remove_column :global_settings, :commit_on_completion
  end
end

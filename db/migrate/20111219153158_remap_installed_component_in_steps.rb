class RemapInstalledComponentInSteps < ActiveRecord::Migration
  def self.up
    Rake::Task['app:set_installed_component'].invoke 
  end

  def self.down
  end
end

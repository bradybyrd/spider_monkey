class AddAaaToEnvironmentTypes < ActiveRecord::Migration
    def self.up
      add_column :environment_types, :archive_number, :string
      add_column :environment_types, :archived_at, :datetime
      add_index :environment_types, :archive_number, :name => 'I_ENV_TYP_ARCH_NUM'
      add_index :environment_types, :archived_at, :name => 'I_ENV_TYP_ARCH_AT'
    end

    def self.down
      remove_index :environment_types, :archive_number, :name => 'I_ENV_TYP_ARCH_NUM'
      remove_index :environment_types, :archived_at, :name => 'I_ENV_TYP_ARCH_AT'
      remove_column :environment_types, :archived_at
      remove_column :environment_types, :archive_number
    end
end

class UpdateAudits < ActiveRecord::Migration
  def self.up
    add_column      :audits, :associated_id, :integer
    add_column      :audits, :associated_type, :string
    add_column      :audits, :comment, :string
    add_column      :audits, :remote_address, :string
    rename_column   :audits, :changes, :audited_changes

    add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
  end

  def self.down
    rename_column   :audits, :audited_changes, :changes
    drop_column     :audits, :associated_id
    drop_column     :audits, :associated_type
    drop_column     :audits, :comment
    drop_column     :audits, :remote_address

    drop_index      :audits, 'associated_index'
  end
end

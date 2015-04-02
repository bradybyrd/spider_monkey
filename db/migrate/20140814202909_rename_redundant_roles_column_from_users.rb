class RenameRedundantRolesColumnFromUsers < ActiveRecord::Migration
  def up

    rename_column :users, :roles, :old_roles

    pm_attribute = ActivityAttribute.find_by_name('Project Manager')
    unless pm_attribute.nil? # it's nil during installation from scratch
      pm_attribute.attribute_values = ['User', 'all']
      pm_attribute.save
    end
  end

  def down

    rename_column :users, :old_roles, :roles

    pm_attribute = ActivityAttribute.find_by_name('Project Manager')
    unless pm_attribute.nil?
      pm_attribute.attribute_values = ['User', 'project_managers']
      pm_attribute.save
    end
  end

  private

  def handle_frozen_users_for_up(items, field)
    update_frozen_hash(items, field) do |hash|
      if hash.has_key?('roles')
        hash['old_roles'] = hash['roles']
        hash.delete('roles')
      end
    end
  end

  def handle_frozen_users_for_down(items, field)
    update_frozen_hash(items, field) do |hash|
      if hash.has_key?('old_roles')
        hash['roles'] = hash['old_roles']
        hash.delete('old_roles')
      end
    end
  end

  def update_frozen_hash(items, field, &block)
    items.find_each do |item|
      hash = Marshal.load(item.send("frozen_#{field}"))

      block.call(hash)

      if MsSQLAdapter
        item.send("frozen_#{field}=", Marshal.dump(hash))
        item.send(:update_lob_columns)
      else
        update_sql = <<-SQL
          UPDATE #{item.class.table_name} 
          SET 
            frozen_#{field} = ?
          WHERE id = ?
        SQL
        ActiveRecord::Base.connection.exec_update(
          update_sql,
          "SQL",
          [
            [item.class.columns_hash["frozen_#{field}"], Marshal.dump(hash)],
            [item.class.columns_hash['id'], item.id]
          ]
        )
      end
    end
  end

end

class FrozenUpdateFailed < StandardError; end

namespace :app do
  task update_step_frozen_owner: :environment do
    begin
      puts 'Updating steps...'
      update_step_frozen_owner(Step.where('FROZEN_OWNER IS NOT NULL'), :owner)
      puts 'Done.'
    rescue => e
      puts "Failed. #{e.backtrace}"
    end
  end

  def update_step_frozen_owner(items, field)
    update_frozen_hash(items, field) do |hash|
      if hash.has_key?('roles')
        hash['old_roles'] = hash['roles']
        hash.delete('roles')
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

    true
  end
end

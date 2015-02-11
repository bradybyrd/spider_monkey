require 'database_cleaner/active_record/deletion'

if OracleAdapter
  module DatabaseCleaner
    module ConnectionAdapters
      module GenericDeleteAdapter
        def delete_table(table_name)
          execute("DELETE FROM #{quote_table_name(table_name)}")
        end
      end
    end
  end
end
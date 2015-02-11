module ActiveRecord::Import::AbstractAdapter
  module InstanceMethods
    def insert_many( sql, values, *args ) # :nodoc:
      number_of_inserts = 1

      base_sql,post_sql = if sql.is_a?( String )
                            [ sql, '' ]
                          elsif sql.is_a?( Array )
                            [ sql.shift, sql.join( ' ' ) ]
                          end

      sql2insert = base_sql + values.join( ',' ) + post_sql

      if PostgreSQLAdapter
        execute( sql2insert, *args )
      else
        insert( sql2insert, *args )
      end

      number_of_inserts
    end

  end
end

class ActiveRecord::Base
  class << self
    private
    def values_sql_for_columns_and_attributes(columns, array_of_attributes)   # :nodoc:
      # connection gets called a *lot* in this high intensity loop.
      # Reuse the same one w/in the loop, otherwise it would keep being re-retreived (= lots of time for large imports)
      connection_memo = connection
      array_of_attributes.map do |arr|
        my_values = arr.each_with_index.map do |val,j|
          column = columns[j]

          # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
          if val.nil? && column.name == primary_key && !sequence_name.blank?
            connection_memo.next_value_for_sequence(sequence_name)
          else
            if serialized_attributes.include?(column.name)
              if OracleAdapter && column.sql_type == 'CLOB'
                "'#{connection_memo.quote_string(serialized_attributes[column.name].dump(val))}'"
              else
                connection_memo.quote(serialized_attributes[column.name].dump(val), column)
              end
            else
              # RT: OracleJDBC quote(for column.type == :text) always returns empty_clob()
              # Don't really know the reason; OracleDB is so frustrated
              # The right way http://stackoverflow.com/questions/5549450/java-how-to-insert-clob-into-oracle-database
              # This doesn't seem right, but since it works...
              if OracleAdapter && val.kind_of?(String) && column.sql_type == 'CLOB'
                "'#{connection_memo.quote_string(val)}'"
              else
                connection_memo.quote(val, column)
              end

            end
          end
        end
        "(#{my_values.join(',')})"
      end
    end

  end
end

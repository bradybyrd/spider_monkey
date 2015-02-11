module MappedParams
  module Order
    class << self
      # Converts order params:
      #   {
      #     "order" => { "0" => ["name", "ASC"], "1" => ["start", "DESC"] }
      #   }
      #   # =>
      #   {
      #     :order => ["name ASC", "start DESC"]
      #   }
      def call(storage, params, relation)
        @relation = relation

        param_name = :order
        params = MappedParams::Param.(storage, params, param_name)

        params[param_name] = if params[param_name].present?
          if params[param_name].is_a?(::Hash)
            params[param_name].reduce([]) { |ordering_strings, (_, attribute_value_pair)|
              ordering_strings << "#{@relation.table_name}.#{attribute_value_pair.join(' ')}" if valid_ordering_pair?(attribute_value_pair)
            }
          end
        end || [default_ordering]
        params
      end

      def valid_ordering_pair?(attribute_value_pair = [])
        valid_attribute?(attribute_value_pair.first) and valid_ordering_value?(attribute_value_pair.second)
      end

      def valid_attribute?(attribute = '')
        @relation.orderable_column_names.include? attribute.to_s
      end

      def valid_ordering_value?(value = '')
        %w(ASC DESC).include? value.upcase
      end

      def default_ordering
        @default_ordering = "#{@relation.table_name}.id ASC"
      end
    end
  end
end

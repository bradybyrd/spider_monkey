module MappedParams
  module Filter
    class << self
      # Converts filter params to the proper hash and/or arel array:
      #   {
      #     "filters" => { "recurrent" => ["1"],
      #                    "behavior" => ["allowing", "preventing"],
      #                    "frequency" => ["daily", "weekly", "monthly"],
      #                    "environment" => ["1"]
      #   }
      #   # =>
      #   {
      #     :filters => {
      #       :simple => { :behavior => ["allowing", "preventing"] },
      #       :complicated => [ #<Arel::Nodes::NotEqual,
      #                         #<Arel::Nodes::Equality,
      #                         { :id => [] }
      #                       ]
      #     }
      #   }
      def call(storage, params, relation)
        @relation = relation
        if params.has_key?(:filters) && !params[:page].present?
          params[:page] = 1
        end
        params[:filters] = simple_filters(storage, params.dup)
                             .merge complicated_filters(storage, params.dup)
        params
      end

      def simple_filters(storage, params, allowed_filtering_column_names = [:behavior])
        prev_params = {}
        param_name = :filters

        prev_params[param_name] = if storage.include?(:collection_manipulations)
          if storage[:collection_manipulations].include? param_name
            if storage[:collection_manipulations][param_name].is_a? ::Hash
              storage[:collection_manipulations][param_name]
                .select { |k, _| allowed_filtering_column_names.include? k }
            end
          end
        end || {}

        params[param_name] = if params.include? param_name
          res = params[param_name].select { |k, _| allowed_filtering_column_names.include? k } if params.include? param_name

          storage[:collection_manipulations] = {} unless storage.include?(:collection_manipulations)
          storage[:collection_manipulations][param_name] = {} unless storage[:collection_manipulations].include?(param_name)
          storage[:collection_manipulations][param_name] = params[param_name]

          res
        else
          prev_params[param_name]
        end || {}

        { simple: params[param_name] }
      end

      def complicated_filters(storage, params)
        options = simple_filters(storage, params, [:recurrent, :frequency, :environment, :start_at, :finish_at])[:simple]
        { complicated: complicated_options_to_arel(options, storage) }
      end

      #
      # Example of what should be done for DeploymentWindow::Series:
      #
      # {
      #   recurrent: ['0', '1'],
      #   frequency: ['daily', 'weekly']
      # }
      # # =>
      # [
      #   DeploymentWindow::Series.arel_table[:recurrence_id].not_eq(nil),
      #   DeploymentWindow::Series.arel_table[:recurrence_id].in(
      #     @relation.recurrence.frequency(['daily', 'weekly'])
      #   )
      # ]
      def complicated_options_to_arel(options, storage)
        options.map { |k, v| send("#{k}_options_to_arel", v, storage) if respond_to? "#{k}_options_to_arel" }
               .compact
      end

      def recurrent_options_to_arel(values, storage)
        if values.include?('0') and values.include?('1')
          # do nothing
          nil
        elsif values.include?('0')
          @relation.klass.arel_table[:recurrent].eq(false)
        elsif values.include?('1')
          @relation.klass.arel_table[:recurrent].eq(true)
        end
      end

      def environment_options_to_arel(values, storage)
        { id: @relation.joins(:environments)
                       .where(environments: { id: values })
                       .map(&:id)
                       .uniq }
      end

      def start_at_options_to_arel(values, storage)
        if values.present?
          value = DateTime.strptime values, GlobalSettings['default_date_format'].split(' ')[0]
          @relation.klass.arel_table[:start_at].gteq(value)
        else
          {}
        end
      rescue ArgumentError
        storage[:collection_manipulations][:filters] = {}
        {}
      end

      def finish_at_options_to_arel(values, storage)
        if values.present?
          value = DateTime.strptime values, GlobalSettings['default_date_format'].split(' ')[0]
          @relation.klass.arel_table[:finish_at].lteq(value)
        else
          {}
        end
      rescue ArgumentError
        storage[:collection_manipulations][:filters] = {}
        {}
      end
    end
  end
end

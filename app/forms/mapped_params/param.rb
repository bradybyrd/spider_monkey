module MappedParams
  module Param
    class << self
      # Simply merges search params with stored ones
      def call(storage, params, param_name)
        prev_params = {}

        prev_params[param_name] = if storage.include?(:collection_manipulations)
          if storage[:collection_manipulations].include? param_name
            storage[:collection_manipulations][param_name]
          end
        end || nil

        params[param_name] = if params.include? param_name
          params[param_name].presence
        else
          prev_params[param_name]
        end

        storage[:collection_manipulations] = {} unless storage.include?(:collection_manipulations)
        storage[:collection_manipulations][param_name] = params[param_name]

        params
      end
    end
  end
end
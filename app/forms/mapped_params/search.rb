module MappedParams
  module Search
    class << self
      # Simply merges search params with stored ones
      def call(storage, params, relation)
        prev_params = {}
        param_name = :q

        if params.has_key?(param_name) && !params[:page].present?
          params[:page] = 1
        end

        MappedParams::Param.(storage, params, param_name)

        # prev_params[param_name] = if storage.include?(:collection_manipulations)
        #   if storage[:collection_manipulations].include? param_name
        #     if storage[:collection_manipulations][param_name].is_a? String
        #       storage[:collection_manipulations][param_name]
        #     end
        #   end
        # end || nil

        # params[param_name] = if params.include? param_name
        #   params[param_name].presence
        # else
        #   prev_params[param_name]
        # end

        # storage[:collection_manipulations] = {} if not storage.include?(:collection_manipulations)
        # storage[:collection_manipulations][param_name] = params[param_name]

        # params
      end
    end
  end
end

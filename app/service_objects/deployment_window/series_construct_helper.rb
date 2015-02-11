module DeploymentWindow
  module SeriesConstructHelper
    class << self

      def prepare_params(params)
        params = params.dup.deep_symbolize_keys
        params = prepare_dates(params)
        params = prepare_environment_ids(params)
        params = prepare_schedule(params)
        params = prepare_recurrent(params)
        if params[:deployment_window_series][:recurrent]
          params = prepare_duration(params)
        end
        params
      end

      def prepare_recurrent(params)
        params[:deployment_window_series][:recurrent] = (params[:deployment_window_series][:recurrent] == 'true')
        params
      end

      def prepare_dates(params)
        params = ::MappedParams::Multiparameters.(params, DeploymentWindow::Series)
        params
      end

      def prepare_duration(params)
        params[:deployment_window_series][:duration_in_days] = params[:deployment_window_series][:duration_in_days].to_i
        params
      end

      def prepare_schedule(params)
        if params[:deployment_window_series][:frequency] == 'null'
          params[:deployment_window_series][:frequency] = nil
        end
        params
      end

      def prepare_environment_ids(params)
        if params[:deployment_window_series][:environment_ids]
          params[:deployment_window_series][:environment_ids] = params[:deployment_window_series][:environment_ids].gsub(/\[|\]/, '').split(',').map(&:to_i)
        end
        params
      end

    end
  end
end

################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module DeploymentWindow
  module SeriesConstructApiHelper
    include SeriesConstructHelper

    class << self
      def prepare_params(params)
        params = params.dup.deep_symbolize_keys
        params = prepare_start_at(params)
        params = prepare_finish_at(params)
        params = SeriesConstructHelper.prepare_schedule(params)
        if params[:deployment_window_series][:recurrent]
          params = SeriesConstructHelper.prepare_duration(params)
        end
        params
      end

      def prepare_start_at(params)
        if params[:deployment_window_series][:start_at].present?
          params[:deployment_window_series][:start_at] = Time.parse(params[:deployment_window_series][:start_at])
        end
        params
      end

      def prepare_finish_at(params)
        if params[:deployment_window_series][:finish_at].present?
          params[:deployment_window_series][:finish_at] = Time.parse(params[:deployment_window_series][:finish_at])
        end
        params
      end

    end
  end
end

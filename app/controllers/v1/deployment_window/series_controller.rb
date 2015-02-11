################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::DeploymentWindow::SeriesController < V1::AbstractRestController
  include ObjectStateController
  before_filter :find_resource, only: [:show, :update, :destroy]

  # Returns series that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 404 Not Found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/deployment_window/series?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/deployment_window/series?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X GET
  # -d '{ "filters": { "name":"Sample DWS" }}' http://[rails_host]/v1/deployment_window/series?token=[api_token]
  def index
    @deployment_window_series = DeploymentWindow::Series.filtered(params[:filters]) rescue []
    respond_to do |format|
      if @deployment_window_series.empty?
        format.xml { head :not_found }
        format.json { head :not_found }
      else
        format.xml { render xml: deployment_window_series_collection_presenter }
        format.json { render json: deployment_window_series_collection_presenter }
      end
    end
  end

  # Returns series by its id
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When record to show is not found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/deployment_window/series/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/deployment_window/series/[id]?token=[api_token]
  def show
    respond_to do |format|
      if @deployment_window_series.present?
        format.xml { render xml: deployment_window_series_item_presenter }
        format.json { render json: deployment_window_series_item_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates new series from a posted XML/JSON document
  #
  # ==== Attributes
  #
  # * +series[name]+ - string name of the request (required)
  # * +series[behavior]+ - string: `allow` or `prevent` (required)
  # * +series[start_at]+ - string: human like (3rd Jun 2020 17:00) or lang based (YYYY-MM-DD HH24:MM:SS) format (required)
  # * +series[finish_at]+ - string: human like (3rd Jun 2020 18:00) or lang based (YYYY-MM-DD HH24:MM::SS) format (required)
  # * +series[environments_id]+ - array of integer ids of the environments
  # * +series[recurrent]+ - boolean: `true` or `false`
  # * +series[duration_in_days]+ - integer: use for recurrent series to adjust occurrence duration (required)
  # * +series[frequency]+ - hash, e.g.: {"validations":{"day_of_month":[1,18,-1]},"rule_type":"IceCube::MonthlyRule","interval":1}
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  # * ERROR 500 Internal server error - When something went wrong...
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d "<deployment_window_series>
  # <name>Api DWS</name> <behavior>allow</behavior> <start_at>3rd Jun 2020 17:00</start_at>
  # <finish_at>3rd Jun 2020 18:00</finish_at> <environment_ids><environment_id>1</environment_id><environment_id>10</environment_id></environment_ids>
  # </deployment_window_series>" http://[rails_host]/v1/deployment_window/series?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d
  # '{ "deployment_window_series": { "name" : "API DWS", "behavior" : "allow", "start_at" : "1rd Jun 2020 17:00", "finish_at" : "3rd Jul 2020 19:00",
  #                                  "frequency": {"validations":{"day_of_month":[1,18,25]},"rule_type":"IceCube::MonthlyRule","interval":1},
  #                                  "duration_in_days": 1, "environment_ids": [1,10]}, "recurrent" : true'
  # http://[rails_host]/v1/deployment_window/series/?token=[api_token]
  def create
    prepared_params = ::DeploymentWindow::SeriesConstructApiHelper.prepare_params(params)
    respond_to do |format|
      begin
        construct                 = ::DeploymentWindow::SeriesConstruct.new(prepared_params)
        success                   = construct.create
        @deployment_window_series = construct.series
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end

      if success
        format.xml    { render xml: deployment_window_series_item_presenter, status: :created }
        format.json   { render json: deployment_window_series_item_presenter, status: :created }
      elsif @exception
        format.xml    { render xml: @exception, status: :internal_server_error }
        format.json   { render json: @exception, status: :internal_server_error }
      else
        format.xml    { render xml: @deployment_window_series.errors, status: :unprocessable_entity }
        format.json   { render json: @deployment_window_series.errors, status: :unprocessable_entity }
      end
    end
  end


  # Creates new series from a posted XML/JSON document
  #
  # ==== Attributes
  #
  # * +series[id]+ - integer id of the series to be updated (required)
  # * +series[name]+ - string name of the series
  # * +series[behavior]+ - string: `allow` or `prevent` (required)
  # * +series[start_at]+ - string: human like (3rd Jun 2020 17:00) or lang based (YYYY-MM-DD HH24:MM:SS) format
  # * +series[finish_at]+ - string: human like (3rd Jun 2020 18:00) or lang based (YYYY-MM-DD HH24:MM::SS) format
  # * +series[environments_id]+ - array of integer ids of the environments
  # * +series[recurrent]+ - boolean: `true` or `false`
  # * +series[duration_in_days]+ - integer: use for recurrent series to adjust occurrence duration (required)
  # * +series[frequency]+ - hash, e.g.: {"validations":{"day_of_month":[1,18,-1]},"rule_type":"IceCube::MonthlyRule","interval":1}
  # * +toggle_archive+ - boolean that will toggle the archive status of an object
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When record to update is not found.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  # * ERROR 500 Internal server error - When something went wrong...
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d
  # '{ "deployment_window_series": { "name" : "API DWS", "behavior" : "allow", "start_at" : "1rd Jun 2020 17:00", "finish_at" : "3rd Jul 2020 19:00",
  #                                  "frequency": {"validations":{"day_of_month":[1,18,25]},"rule_type":"IceCube::MonthlyRule","interval":1},
  #                                  "duration_in_days": 1, "environment_ids": [1,10]}, "recurrent" : true'
  # http://[rails_host]/v1/deployment_window/series/[id]/?token=[api_token]

  def update
    prepared_params = ::DeploymentWindow::SeriesConstructApiHelper.prepare_params(params)
    respond_to do |format|
      if @deployment_window_series.present?
        begin
          if param_present_and_true?(:toggle_archive)
            success = @deployment_window_series.toggle_archive
            @deployment_window_series.errors.add(:toggle_archive, I18n.t('deployment_window.archive_failed')) unless success
          elsif !@deployment_window_series.editable?
            @deployment_window_series.errors.add(:base, I18n.t('deployment_window.not_editable'))
          elsif params[:deployment_window_series].present?
            success = true
            if params[:deployment_window_series][:aasm_state].present?
              success = @deployment_window_series.update_attributes_with_state({ aasm_state: params[:deployment_window_series].delete(:aasm_state) })
            end
            if success && params[:deployment_window_series].any?
              construct = ::DeploymentWindow::SeriesConstruct.new(prepared_params, @deployment_window_series)
              success = construct.update
              @deployment_window_series = construct.series
            end
          end
        rescue Exception => e
          @exception = { message: e.message, backtrace: e.backtrace.inspect }
        end

        if success
          format.xml  { render xml: deployment_window_series_item_presenter, status: :accepted }
          format.json  { render json: deployment_window_series_item_presenter, status: :accepted }
        elsif @exception
          format.xml  { render xml: @exception, status: :internal_server_error }
          format.json  { render json: @exception, status: :internal_server_error }
        else
          format.xml  { render xml: @deployment_window_series.errors, status: :unprocessable_entity }
          format.json  { render json: @deployment_window_series.errors, status: :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes series if it's archived
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/deployment_window/series/[id].xml?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/deployment_window/series/[id].xml?token=[api_token]
  def destroy
    respond_to do |format|
      if @deployment_window_series
        if @deployment_window_series.destroy
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render xml: deployment_window_series_item_presenter, status: :precondition_failed }
          format.json { render json: deployment_window_series_item_presenter, status: :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def find_resource
    @deployment_window_series = ::DeploymentWindow::Series.find_by_id(params[:id])
  end

  def deployment_window_series_item_presenter
    @deployment_window_series_presenter ||= V1::DeploymentWindow::SeriesItemPresenter.new(@deployment_window_series)
  end

  def deployment_window_series_collection_presenter
    @deployment_window_series_presenter ||= V1::DeploymentWindow::SeriesCollectionPresenter.new(@deployment_window_series)
  end
end

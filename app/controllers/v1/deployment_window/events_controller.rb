################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::DeploymentWindow::EventsController < V1::AbstractRestController
  before_filter :find_resource
  before_filter :prepare_params, only: :update

  # Returns a deployment window event by id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/deployment_window/events/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/deployment_window/events/[id]?token=[api_token]
  def show
    respond_to do |format|
      if @deployment_window_event.present?
        format.xml { render xml: event_presenter }
        format.json { render json: event_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Updates an existing deployment window event with values from a PUT request
  #
  # ==== Attributes
  #
  # * +deployment_window_event[state]+ - string state of event, can be one of [suspended, resumed, moved]
  # * +deployment_window_event[reason]+ - string reason of state change
  # * +deployment_window_event[start_at]+ - string: human like (3rd Jun 2020 17:00) or lang based (YYYY-MM-DD HH24:MM:SS) format
  # * +deployment_window_event[finish_at]+ - string: human like (3rd Jun 2020 17:00) or lang based (YYYY-MM-DD HH24:MM:SS) format
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When record to update is not found.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  # Suspend examples
  #
  # curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d
  #   '{ "deployment_window_event": { "state" : "suspended", "reason" : "suspend reason"}}'
  #   http://[rails_host]/v1/deployment_window/events/[id]?token=[api_token]
  #
  # Resume examples
  #
  # curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d 
  #   '{ "deployment_window_event": { "state" : "resumed", "reason" : "resume reason"}}'
  #   http://[rails_host]/v1/deployment_window/events/[id]?token=[api_token]
  #
  # Move examples
  #
  # curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d 
  #   '{ "deployment_window_event": { "state" : "moved", "reason" : "move reason", 
  #                                   "start_at" : "14th Apr 2014 06:00", "finish_at" : "14th Apr 2014 06:30"}}'
  #   http://[rails_host]/v1/deployment_window/events/[id]?token=[api_token]
  #
  def update
    respond_to do |format|
      if @deployment_window_event.present?
        if @deployment_window_event.update_attributes @modified_params
          format.xml { render xml: event_presenter }
          format.json { render json: event_presenter }
        else
          format.xml  { render :xml => @deployment_window_event.errors, :status => :unprocessable_entity }
          format.json  { render :json => @deployment_window_event.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def find_resource
    @deployment_window_event = ::DeploymentWindow::Event.find_by_id params[:id]
  end

  def prepare_params
    @modified_params = params.dup.deep_symbolize_keys[:deployment_window_event]
    prepare_date(:start_at)
    prepare_date(:finish_at)
    prepare_reason
  end

  def prepare_date(field)
    if @modified_params[field].present? && @modified_params[field].is_a?(String)
      @modified_params[field] = Time.parse(@modified_params[field])
    end
  end

  def prepare_reason
    if @modified_params[:state].present? && !@modified_params.has_key?(:reason)
      @modified_params[:reason] = ''
    end
  end

  def event_presenter
    @event_presenter ||= V1::DeploymentWindow::EventPresenter.new(@deployment_window_event)
  end
end

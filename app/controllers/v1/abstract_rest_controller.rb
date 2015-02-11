################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::AbstractRestController < ApplicationController

  # turn off devise user based authentication
  skip_before_filter :authenticate_user!

  # validate against the api filter and redirect to an error xml document
  before_filter :validate_api_filter, :except => [:validation_error]

  # do not look for any view or layouts since we will be serving pure xml
  layout false

  # generates default actions for this and all child controllers so we
  # provide common error handling for unimplemented REST actions, although
  # we use the standard rails names for these which are matched up by rails
  # resources with :get, :post, :put, and :delete
  [:index, :show, :create, :update, :destroy].each do |rest_action|
    define_method(rest_action) {
      # redefine in child classes
      render text: 'Forbidden', status: '405 Not Allowed'
    }
  end

  protected

  def param_present_and_true?(param_name)
    false if params[param_name].blank?
    adapter_column = ActiveRecord::ConnectionAdapters::Column
    adapter_column.value_to_boolean(params[param_name])
  end

  private

  def set_include_except
    @include_except = params[:filters][:include_except] ? params[:filters][:include_except].split(%r{,\s*}) : []
  end

end

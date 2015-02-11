################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'automation_common'
class ComponentTemplatesController < ApplicationController

  before_filter :find_component_template, :only => [ :edit, :update, :component_properties ]

  def new
    @component_template = ComponentTemplate.new
    authorize! :add, @component_template

    @app = App.find(params[:app_id])
    @component_template.app_id = params[:app_id]
    render :layout => false
  end

  def create
    @component_template = ComponentTemplate.new(params[:component_template])
    authorize! :add, @component_template

    if @component_template.save
      update_component_template_table
    else
      show_validation_errors(:component_template, {:div => "component_template_error_messages"})
    end
  end

  def edit
    @app = @component_template.app
    render :layout => false
  end

  def update
    if @component_template.update_attributes(params[:component_template])
      update_component_template_table
    else
      show_validation_errors(:component_template, { :div => 'component_template_error_messages' })
    end
  end

  def sync
    authorize! :sync, ComponentTemplate.new

    if GlobalSettings.bladelogic_ready?
      output_params = ComponentTemplate.run_sync_command(params[:app_id])
      @output_file = output_params["SS_output_file"]
      result = output_params["result"]
      lpos = result.index("Traceback (most recent call last)")
      @error = true unless lpos.nil?
      @error = AutomationCommon::error_in?(result)
    end
  end

  def component_properties
    template_item = PackageTemplateItem.find(params[:package_template_item]) rescue nil
    render :partial => "package_templates/template_items/forms/component_instance_properties",
           :locals => { :application_component => @component_template.application_component,
                        :template_item_count => params[:template_item_count],
                        :identifier => params[:identifier],
                        :template_item => template_item
                      }
  end

  protected

  def find_component_template
    @component_template = ComponentTemplate.find(params[:id])
  end

  def update_component_template_table
    @app = @component_template.app
    respond_to do |format|
      format.js { render :template => 'component_templates/_update_component_templates_list', :handlers => [:erb], :content_type => 'application/javascript'}
    end
  end

end

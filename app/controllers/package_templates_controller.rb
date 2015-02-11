################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageTemplatesController < ApplicationController
  
  before_filter :find_app, :only => [ :create, :edit, :update, :destroy, :show, :delete_template_item ]
  before_filter :find_package_template, :only => [ :edit, :update, :show, :delete_template_item ]
  
  def create
    @package_template = @app.package_templates.build(params[:package_template])
    unless @package_template.save
      show_validation_errors(:package_template)
    else
      build_package_item
    end
  end
  
  def edit
    @app = @package_template.app
    if params[:simple_update].nil_or_empty?
      build_package_item
      render :template => 'package_templates/create.rjs' unless params[:item_id].present?
    else
      render :layout => false
    end
  end
  
  def update
    reorder_template_items and return unless params[:reorder].nil_or_empty?

    #
    # DEFECT: DE65816 - Add item does not work.
    # Rajesh: Workaround for Postgres Support
    # Not sure if this is the right way to do this.
    # The issue is that a blank "id" field is passed by the view code
    # (It's too complicated to figure out how the params fields are sent during POST
    # to avoid sending it that way from the browser)
    # Consquently, update_attributes method tries to load the package item with a blank id
    # that postgres does not like and throws error.
    #
    # What we are doing below is just eliminating the id field if it is a new item
    #
    params[:package_template].each_pair do |templ_attrib, templ_val|
      if (templ_attrib == "package_template_items_attributes")
        templ_val.each_pair do |key, value|
          if value["id"].blank?
            value.delete "id"
          end
        end
      end
    end

    unless @package_template.update_attributes(params[:package_template])
      show_validation_errors(:package_template, { :div => params[:simple_update].nil_or_empty? ? "error_messages#{@package_template.id}".to_sym : "package_template_error_messages" })
    else
      if params[:only_edit].blank?
        build_package_item
        render :template => 'package_templates/create.rjs'
      end
    end
  end
  
  def destroy
  end
  
  def delete_template_item
    @package_template.template_items.find(params[:item_id]).destroy
    build_package_item
    render :template => 'package_templates/create.rjs'
  end
  
  def reorder_template_items
    package_template_item = @package_template.template_items.find(params[:template_item_id])
    package_template_item.update_attributes({:insertion_point => params[:insertion_point]})
    render :template => "package_templates/reorder_template_item.rjs"
  end

  protected
  
  def find_app
    @app = App.find(params[:app_id])   
  end
  
  def find_package_template
    @package_template = @app.package_templates.find(params[:id])
  end
  
  def build_package_item
    1.times { @package_template.package_template_items.build }
  end
  
end

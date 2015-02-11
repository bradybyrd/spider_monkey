################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class RequestTemplatesController < ApplicationController

  include ArchivableController
  include ControllerSearch
  include AlphabeticalPaginator
  include ObjectStateController

  def index
    authorize! :list, RequestTemplate.new
    list
  end

  def choose
    authorize! :choose_template, Request.new
    list
  end

  def details
    @keyword = params[:key]
    @app_id = params[:request] && !params[:request][:app_ids].blank? ? params[:request][:app_ids] : nil
    @request_id =  params[:request][:id] if params[:request] && params[:request][:id]
    @per_page = params[:per_page].to_i
    @order = params[:order]
    params[:page] = nil if params[:page] && (params[:page].to_i == 1)
    params[:page_inactive] = nil if params[:page_inactive] && (params[:page_inactive].to_i == 1)
    index_query
    if params[:position] == 'unarchived'
      @request_templates = @active_request_templates
      @archived = false
    else
      @request_templates = @inactive_request_templates
      @archived = true
    end
    # Paginate
    if params[:numeric_pagination].present?
      @request_templates = paginate_records(@request_templates, params, @per_page)
    else
      @request_templates = alphabetical_paginator(@per_page, @request_templates, @archived)
    end
    if params['plan_id'].present?
      @plan_stage_id = params['plan_stage_id']
      @plan_id = params['plan_id']
    end
    @request = params[:request]
    partial = params[:partial] || 'details'
    render partial: "request_templates/#{partial}", layout: false, locals: {request_templates: @request_templates, archived: @archived}
  end


  def create
    @request = Request.find_by_number(params[:request_id])

    authorize! :create_template, @request

    @request_template             = RequestTemplate.initialize_from_request(@request, params[:request_template] || @variant)
    @request_template.created_by  = current_user.id if current_user

    unless params[:teams].nil?
      @request_template.team_id = params[:teams]
      @request_template.parent_id = @requests_template.id
    end

    if @request_template.save
      RequestTemplate.copy_from_request(@request, @request_template)
      flash[:success] = I18n.t(:'request_template.notices.created')
      unless params[:teams].nil?
        @request_template.request.update_attributes(request_template_id: @request_template.id, name: @request_template.name)
      end
      ajax_redirect(edit_request_path(@request)) if request.xhr?
    else
      if request.xhr?
        @validation_errors = @request_template.errors.full_messages.collect {|e| "<li>#{e}</li>"}.join.to_s.html_safe
        render template: 'request_templates/create', formats: [:js], handlers: [:erb]
      else
        flash[:error] = 'There was a problem creating the template.'
      end
    end
    redirect_to edit_request_path(@request) unless request.xhr?
  end

  def destroy
    @request_template = RequestTemplate.find(params[:id])
    authorize! :delete, @request_template
    @request_template.destroy

    redirect_to request_templates_path, notice: t('activerecord.notices.deleted', model: I18n.t('activerecord.models.request_template'))
  end

  def create_variant
    @request = Request.find_by_number(params[:request_id])
    authorize! :create_request_template_variant, @request
    @request_template = RequestTemplate.new
    authorize! :create, @request_template
    @teams = Team.all
    render layout: false
  end

  def save_variant
    @request = Request.find_by_number(params[:request_id])
    @requests_template = RequestTemplate.find(params[:request_template_id])
    authorize! :create, @request_template
    variant_name = params[:team_name] + ' - ' + @requests_template.name
    @variant = Hash['name', variant_name]
    create
  end

  def update
    @request_template = RequestTemplate.find(params[:id])
    authorize! :update_state, @request_template
    if @request_template.update_attributes(params[:request_template])
      flash[:notice] = t('activerecord.notices.updated', model: I18n.t('activerecord.models.request_template'))
      redirect_to @request_template.request
    else
      redirect_to @request_template.request
    end
  end

  def show
    @only_preview = params[:preview] == 'yes'
    @request = Request.find(params[:request_id])
    authorize! :edit, @request_template
  end

  def request_template_warning
    if params[:id] != '0'
      template = find_request_template
      @warning = template.warning_state if template.warning_state?
    end
    @type = 'request_template'
    render partial: 'object_state/state_usage_warning'
  end

  protected

  def index_query
    # Assumes these are all set
    #@keyword ,@app_id , @request_id, @per_page ,@order
    if params[:visible_only].present?
      @active_request_templates =  RequestTemplate.unarchived.templates_for(current_user,@app_id).visible('request_templates').name_order
    else
      @active_request_templates = RequestTemplate.unarchived.templates_for(current_user, @app_id).visible_in_index('request_templates').name_order
    end
    @inactive_request_templates = RequestTemplate.archived.templates_for(current_user, @app_id)

    if @keyword.present?
      @active_request_templates = @active_request_templates.where("request_templates.name like '%#{@keyword}%'")
      @inactive_request_templates = @inactive_request_templates.where("request_templates.name like '%#{@keyword}%'")
    end
    previous_sorting_with_request = nil
    if @order
      @order.each do |_,v|
        @inactive_request_templates = @inactive_request_templates.sorted_by(v[0].to_sym, "#{v[1]}", @app_id || previous_sorting_with_request)
        @active_request_templates = @active_request_templates.sorted_by(v[0].to_sym, "#{v[1]}", @app_id || previous_sorting_with_request)
        previous_sorting_with_request = true if [:app, :environment].include?(v[0].to_sym)
      end
    else
      @inactive_request_templates = @inactive_request_templates.sorted if @inactive_request_templates
      @active_request_templates = @active_request_templates.sorted if @active_request_templates
    end
    @total_records = @active_request_templates.nil? ? 0 : @active_request_templates.length
    @total_inactive_records = @inactive_request_templates.nil? ? 0 : @inactive_request_templates.length
  end

  def find_request_template
    @request_template = RequestTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Request Template you are trying to access either does not exist or has been deleted'
    redirect_to(request_templates_path) && return
  end

  def list
    @per_page = 15
    @keyword = params[:key]
    @app_id = params[:request] && !params[:request][:app_ids].blank? ? params[:request][:app_ids] : nil
    @request_id =  params[:request][:id] if params[:request] && params[:request][:id]

    @order = params[:order]

    @page = params[:page] || 1
    @page_inactive = params[:page_inactive] || 1
    index_query

    if @active_request_templates.blank? and @inactive_request_templates.blank?
      flash[:error] = 'No request template found.'
    end
    if params[:numeric_pagination].present?
      partial = 'list'
      @active_request_templates = paginate_records(@active_request_templates, params, @per_page)
    else
      partial = 'ajax_pagination_index'
      @active_request_templates = alphabetical_paginator(@per_page, @active_request_templates)
      @inactive_request_templates = alphabetical_paginator(@per_page, @inactive_request_templates, true)
    end

    @request_templates = @active_request_templates

    if request.xhr?
      @params = params
      @request = @params[:request]
      render partial: "request_templates/#{partial}", layout: false
    end
  end

end

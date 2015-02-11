################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'will_paginate/array'

class StepsController < ApplicationController
  include TicketsHelper
  require 'cgi'
  include ApplicationHelper

  before_filter :find_request, :except => [:currently_running, :update_components, :update_position, :server_properties,
    :properties_options, :runtime_phases_options, :get_alternate_servers, :destroy_step_in_procedure, :edit_step_in_procedure,
    :update_procedure_step, :step_component_options, :run_now, :update_uploads,:estimate_calculation, :render_output_step_view,
    :new_step_for_procedure, :create_procedure_step, :change_step_status, :can_delete_step]
  before_filter :find_step, :only => [:edit, :update, :show, :update_status, :add_category,
    :expand_procedure, :collapse_procedure, :update_procedure,
    :new_procedure_step, :toggle_execution,
    :edit_execution_condition, :update_execution_condition, :get_section,
    :update_should_execute, :script_callback,
    :update_runtime_phase, :update_completion_state, :versions_for_component, :get_type_inputs, :references_for_request]

  skip_before_filter :authenticate_user!, :only => [:script_callback]

  before_filter :get_recent_activities, :only => [:currently_running]

  rescue_from(AASM::InvalidTransition) do |exception|
    if request.xhr?
      set_step_permissions(@request)
      render 'requests/steps', request: @request
    else
      redirect_to edit_request_path(@request, unfolded_steps: (!params[:dont_expand_step] && (@step.in_process? || @step.problem?)) ? @step.id.to_s : '') + "#step_#{@step.id}_heading"
    end
  end

  def index(updated_steps=nil) # TODO - This code is not yet refactored. Just made more readable.
    @request_steps = @request.steps
    current_user.update_last_response_time # what for is it here?
    @request.should_finish?
    unless @request.complete?
      unfolded_steps = if params[:unfolded_steps].blank?
        []
      else
        @request_steps.where(:id => params[:unfolded_steps].split(",").reject{|s_id| s_id.blank?})
      end
      unfolded_steps_ids = unfolded_steps.map{|step| step.id.to_s}
      steps = updated_steps.blank? ? @request_steps.completed_in_last_n_seconds(Time.now.utc, 20) : updated_steps
      #steps.push(@step) if defined?(@step)
      # To collect all step IDs present on current Request Step view page.
      request_steps = @request_steps.top_level
      div_ids = []
      request_steps.each do |step|
        child_steps = @request_steps.select{ |child_step| child_step.parent_id == step.id }.compact.sort_by(&:position)

        if step.procedure?
          div_ids << "step_#{step.id}"
        else
          div_ids << "step_#{step.id}_#{step.position}"
        end
        unless child_steps.blank?
          child_steps.each do |s|
            div_ids << "step_#{s.id}_#{s.position}"
          end
        end
      end
    end

    if @request.complete?
      render template: "steps/request_complete", formats: [:js]
    elsif steps.size > 0
      set_step_permissions(@request)

      respond_to do |format|
        @steps = steps
        @request_steps = request_steps
        @unfolded_steps_ids = unfolded_steps_ids
        @unfolded_steps = unfolded_steps
        @current_user = current_user
        @div_ids = div_ids
        @updated_steps = updated_steps
        available_package_ids = @request.available_package_ids
        format.js { render template: 'steps/index', handlers: [:erb],
                           content_type: 'application/javascript',
                           locals: {
                              available_package_ids: available_package_ids,
                              steps_with_invalid_components: @request.steps_with_invalid_components,
                              request_view_step_headers: @request.request_view_step_headers
                           }
                  }

      end

    else
      render nothing: true
    end
  end

  def render_updated_steps(steps)
    @procedure_steps = @procedure.steps.top_level
    @steps = steps
    div_ids = []
    @procedure_steps.each do |step|
      child_steps = @procedure_steps.select{|child_step|
        child_step.parent_id == step.id}.compact.sort_by(&:position)

      if step.procedure?
        div_ids << "step_#{step.id}"
      else
        div_ids << "step_#{step.id}_#{step.position}"
      end
      unless child_steps.blank?
        child_steps.each do |s|
          div_ids << "step_#{s.id}_#{s.position}"
        end
      end
    end
    respond_to do |format|
      @unfolded_steps_ids = []
      @unfolded_steps = []
      @current_user = current_user
      @div_ids = div_ids
      @updated_steps = @steps
      format.js { render :template => 'steps/render_steps', :handlers => [:erb],
                         :content_type => 'application/javascript'}
    end
  end

  def add
    @is_procedure_step = params[:is_procedure_step] == 'true'
  end

  def get_section
    authorize! :inspect_steps, @request

    render :partial => 'steps/step_rows/step_show_form', :locals => { :request => @request, :step => @step, :unfolded => true, :invalid_component => nil }
  end

  def currently_running
    authorize! :view_currently_running_steps, Request.new

    @steps = Step.all_currently_running(current_user)
    @steps, @filters = perform_filtering(@steps, params)
    @total_records = @steps.count
    paginate_steps

    if request.xhr?
      render :partial => "dashboard/self_services/currently_running_steps.html.erb"
    else
      respond_to do |format|
        format.html do
          if params[:for_dashboard] && user_signed_in?
            dashboard_setup
            @page_path = currently_running_steps_url
            get_data(!user_signed_in?)
            my_applications
            render :template => "dashboard/self_services"
          else
            if params[:should_user_include_groups]
              @page_path = "/steps/currently_running?should_user_include_groups=true"
            else
              @page_path = dashboard_currently_running_url
            end
            @store_url = true
            render :template => "steps/currently_running"
          end
        end
      end
    end

  end

  def update_components
    steps = Step.find(params[:steps])
    application = steps.first.request.app

    if session[:components_to_be_destroyed]
      application.application_components.find_all_by_component_id(session[:components_to_be_destroyed]).map(&:destroy)
      session[:components_to_be_destroyed] = nil
    end

    steps.each do |step|
      if params[:components][step.id.to_s].blank?
        step.destroy
      else
        step.update_attribute(:component_id, params[:components][step.id.to_s])
      end
    end

    redirect_to params[:redirect_path]
  end

  def new
    authorize! :add_step, @request
    @users = @request.available_users_with_app
    @groups = @request.available_groups(@users.map(&:id))
    step = @request.steps.build(owner: current_user)
    step.different_level_from_previous = false if params[:parallel].present?
    available_package_ids = @request.available_package_ids

    render partial: 'steps/step_rows/step_form', locals: { request: @request, step: step, available_package_ids: available_package_ids }
  end

  def get_type_inputs
    related_object_type = params[:related_object_type]
    step = get_current_step
    render partial: 'steps/step_rows/type_content', locals: { related_object_type: related_object_type, step: step }
  end

  # caution: This method is to be used only in case package type is selected in Step dialog. Synchronize this function
  # with steps.js#updateContentTabForPackages
  def references_for_request
    step = get_current_step
    step.assign_attributes(params[:step])
    package_or_instance = params[:package_or_instance]
    render partial: "steps/step_rows/step_references", locals: { step: step, package_or_instance: package_or_instance,
                                                                 references: get_references_for_package_context(step, package_or_instance)}
  end

  def get_package_instances
    package_id = params[:package]
    package = Package.find_by_id(package_id)
    step = @request.steps.find_or_initialize_by_id(params[:step_id])
    render :partial => "steps/step_rows/package_instances", locals: { step: step, package: package}
  end

  def get_current_step
    @step ? @step : @request.steps.build(owner: current_user)
  end

  def load_tab_data
    authorize_tab
    @step = params[:id] ? Step.find(params[:id]) : @request.steps.build(owner: current_user)
    @display_only = (params[:display_only] == 'true')
    @current_user_id = current_user.id
    @related_object_type = params[:related_object_type]

    if params[:id]
      installed_component_servers = @step.installed_component.try(:server_associations) || []
      server_collection = (installed_component_servers + @step.targeted_servers).uniq
      @server_collection = (@step.complete? || @step.request.already_started?) ? @step.targeted_servers : server_collection
    end

    @step.uploads.build if params[:li_id].eql?('st_documents') && !@step.enabled_editing?(current_user)
  end

  def new_step_for_procedure
    authorize! :add_step, Request.new
    procedure = Procedure.find(params[:procedure_id])
    app_ids = App.where(:id => procedure.apps.map(&:id)).select([:id]) || 0
    @users = User.having_access_to_apps(app_ids).order('users.last_name, users.first_name')
    @groups = Group.where(:id => @users.collect{|u| u.group_ids}.flatten.uniq).active
    @grouped_users = @groups.map{|grp| [grp,grp.resources] }
    step = procedure.steps.new(:owner => current_user)
    step.uploads.build
    step.different_level_from_previous = false if params[:parallel].present?
    render partial: 'steps/step_rows/new_step_for_procedure_form', locals: { step: step, procedure: procedure }
  end

  def create
    unless can?(:add_step, @request) || can?(:add_serial_procedure_step, @request)
      authorize!(:unauthorized, @request)
    end
    params[:step].merge!({ :temp_component_id => params[:step][:component_id] }) # TODO - Add in before_filter
    step_params = reformat_dates_for_save(params[:step])

    if GlobalSettings.limit_versions?
      version_tag = nil
      if params[:step][:component_id].present? && !params[:step][:version].blank?
        version_tag = VersionTag.find(params[:step][:version].to_i) rescue nil
      end
      if version_tag
        step_params.update(:version_tag_id => version_tag.id)
        step_params.update(:component_version => version_tag.name)
      else
        step_params.update(:version_tag_id => nil)
        step_params.update(:component_version => nil)
      end
    else
      step_params.update(:component_version => params[:step][:version])
    end

    if step_params[:owner_id].blank?
      step_params[:owner_id] = @request.user_id
      step_params[:owner_type] = "User"
    end
    step_params[:different_level_from_previous] = true if @request.steps.empty?
    step_params = update_automation_params(step_params)

    step_params = update_server_params(step_params)
    step_params = update_step_references(step_params)

    @step = @request.steps.build(step_params)

    (params[:uploads] || []).each do |uploaded_data|
      @step.uploads.build(:uploaded_data => uploaded_data) unless uploaded_data.blank?
    end
    # convert tree argument values in object readable format
    params[:argument] ||= {}
    params.each do |k,v|
      if k.match('tree_renderer_')
        ar_id =  k.match(/[0-9 -()+]+$/)[0]
        params[:argument][ar_id] = v.split(',').map{|v| URI.unescape(v)}
      end
    end

    if params[:argument] && params[:automation_type] != "BladelogicScript"
      argument_file_hash = {}
      params[:argument].each do |k, v|
        if v.is_a?(Hash) && v.keys.include?("step_script_argument")
          argument_file_hash[k] = v[:step_script_argument]
        end
      end
      params[:argument] = params[:argument].delete_if {|key, value|
        script_argument = ScriptArgument.find(key)
        if script_argument.is_required?
          value.first.empty? || ( value.is_a?(Hash) && value.keys.include?("step_script_argument") )
        else
          value.is_a?(Hash) && value.keys.include?("step_script_argument")
        end

      }
      @step.selected_step_arguments = params[:argument].merge(argument_file_hash)
    end
    StepService::ParamsPerPermissionSanitizer.new(step_params, @request, current_user).clean_up_params!

    if @step.save
      @step.update_attributes :installed_component_id => @step.get_installed_component.try(:id)
      @step.update_script_arguments!({:argument => params[:argument]}) if params[:argument]
      @step.update_attribute(:own_version, false) if params[:step][:version].blank?
      @step.update_property_values!(params[:property_values])
      @step.notes.create(:user_id => current_user.id, :content => params[:step][:note]) unless params[:step][:note].blank?
      @step.upload_file_for_script_arguments(argument_file_hash)
      @step.set_owner_attributes
    else
      @validation_errors = true
    end

    if params[:ajax_request].present?
      unfolded_steps = if params[:unfolded_steps].blank?
        []
      else
        @request_steps = @request.steps
        @request_steps.id_equals(params[:unfolded_steps].split(",").reject{|s_id| s_id.blank?})
      end
      unfolded_steps_ids = unfolded_steps.map(&:id).map(&:to_s)
      if @validation_errors
        render template: 'misc/error_messages_for', layout: false, locals: {item: @step}
      else
         step_list_preferences_lists = current_user.step_list_preferences.active
         available_package_ids = @request.available_package_ids
         set_step_permissions(@request)

         respond_to do |format|
          format.html { render partial: 'steps/step_rows/ajax_file_submit',
                              locals: {
                                  request: @request,
                                  invalid_component: @request.steps_with_invalid_components.include?(@step),
                                  step: @step,
                                  unfolded: unfolded_steps_ids.include?("#{@step.id}"),
                                  step_header: @request.request_view_step_headers[@step.id.to_s] || {},
                                  step_preferences: step_list_preferences_lists,
                                  available_package_ids: available_package_ids
                              }
                       }
         end
      end
    else
      @users = @request.available_users
      @groups = Group.name_order
      @steps_with_invalid_components = @request.steps_with_invalid_components
      redirect_to edit_request_path(@request) + "#step_#{@step.id}_#{@step.position}_heading"
    end

    # Properties and script arguments may take long route to trace so not audited in model
    ActivityLog.log_event(@step, current_user, "property values #{@step.current_property_values.inspect} ")

  end

  def create_procedure_step
    authorize! :add_step, Request.new
    step_params = reformat_dates_for_save(params[:step])
    step_params = update_automation_params(step_params)
    if step_params[:owner_id].blank?
      step_params[:owner_id] = current_user.id
      step_params[:owner_type] = "User"
    end
    step = Step.new(step_params)
    if step.save
      if params[:ajax_request].present?
        step_list_preferences_lists = current_user.step_list_preferences.active
        respond_to do |format|
           format.html{ render :partial => 'steps/step_rows/ajax_file_submit',
                               :locals => { :procedure => step.floating_procedure,
                                            :step => step,
                                            :unfolded => false,
                                            :invalid_component => nil,
                                            :step_preferences => step_list_preferences_lists
                                          }}
         end
      end
    end
  end

  def show
    step_list_preferences_lists = current_user.step_list_preferences.active
    render :partial => 'steps/step_rows/step_header',
      :locals => { :request => @request,
      :invalid_component => @request.steps_with_invalid_components.include?(@step),
      :step => @step,
      :step_header => @request.request_view_step_headers[@step.id.to_s] || {},
      :step_preferences => step_list_preferences_lists  }
  end

  def edit
    authorize! :edit_step, @request

    @users = @request.available_users
    @groups = @request.available_groups(@users.map(&:id))

    # build an upload for the new record to show an upload form by default
    @step.uploads.build if @step.uploads.blank?
    render :partial => 'steps/step_rows/step_form', :locals => {:request => @request, :step => @step }
  end

  def edit_step_in_procedure
    procedure = Procedure.find(params[:procedure_id])
    app_ids = App.where(:id => procedure.apps.map(&:id)).select([:id]) || 0
    @users = User.having_access_to_apps(app_ids).order('users.last_name, users.first_name')
    @groups = Group.where(:id => @users.collect{|u| u.group_ids}.flatten.uniq).active
    @grouped_users = @groups.map{|grp| [grp,grp.resources] }
    step = Step.find(params[:id])
    authorize_archived_procedure_step!(step)
    step.uploads.build if step.uploads.blank?
    step.different_level_from_previous = false if params[:parallel].present?
    render :partial => 'steps/step_rows/procedure_step_form', :locals => {:step => step, :procedure => procedure}
  end

  def update_position
    @request = Request.find_by_number(params[:request_id])
    @step = @request.steps.find(params[:id])
    @step = @step.steps.find(params[:step_id]) if @step.procedure? && params[:step_id]
    begin
      @request.lock_steps if @request.hold?
    rescue
      [] # in case of step in progress
    end
    @step.should_not_time_stitch = true
    @step.update_attributes(params[:step] || params[:procedure_step])
    if @step.procedure?
      render :partial => 'steps/procedure_for_reorder', :locals => { :request => @request, :step => @step }
    else
      render :partial => 'steps/step_for_reorder', :locals => { :request => @procedure || @request, :step => @step }
    end
  end

  def update
    authorize! :edit_step, @request

    params[:step] ||= {}
    params[:step].merge!({ :temp_component_id => params[:step][:component_id] }) # TODO - Add in before_filter
    step_params = reformat_dates_for_save(params[:step])
    #version_id = params[:step][:version].to_i if GlobalSettings.limit_versions? && params[:step][:version].to_i > 0
    #version_name = version_id.nil? ? params[:step][:version] : Version.find(params[:step][:version].to_i).try(:name)

    params[:argument] ||= {}
    params.each do |k,v|
      if k.match('tree_renderer_')
        ar_id =  k.match(/[0-9 -()+]+$/)[0]
        params[:argument][ar_id] = v.split(',').map{|v| URI.unescape(v)}
      end
    end

    if params[:argument] && params[:automation_type] != "BladelogicScript"
      argument_file_hash = {}
      params[:argument].each do |k, v|
        if v.is_a?(Hash)
          if v.keys.include?("step_script_argument")
            argument_file_hash[k] = v[:step_script_argument]
            argument_file_hash[k][:uploads_attributes].merge!({"0" => v[:update_step_script_argument][:uploads_attributes]}) if v.keys.include?("update_step_script_argument")
          elsif v.keys.include?("update_step_script_argument")
            argument_file_hash[k] = v[:update_step_script_argument]
          end
        end
      end
      script_arguments = @step.script_arguments.all
      params[:argument] = params[:argument].delete_if {|key, value|
        script_argument = script_arguments.detect{ |script_argument| script_argument.id.to_s == key } || ScriptArgument.new
        if script_argument.is_required?
          value.first.empty? || ( value.is_a?(Hash) && ( value.keys.include?("step_script_argument") || value.keys.include?("update_step_script_argument") ) )
        else
          value.is_a?(Hash) && ( value.keys.include?("step_script_argument") || value.keys.include?("update_step_script_argument") )
        end
      }
      @step.selected_step_arguments = params[:argument].merge(argument_file_hash.reject {|_,v| v["uploads_attributes"]["_destroy"] == "1"})
    end

    if GlobalSettings.limit_versions?
      version_tag = nil
      if params[:step][:component_id].present? && !params[:step][:version].blank?
        version_tag = VersionTag.find(params[:step][:version].to_i) rescue nil
      end
      if version_tag
        step_params.update(:version_tag_id => version_tag.id)
        step_params.update(:component_version => version_tag.name)
      else
        step_params.update(:version_tag_id => nil)
        step_params.update(:component_version => nil)
      end
    else
      step_params.update(:component_version => params[:step][:version])
    end
    if params[:change_server_ids_flag]
      step_params.update(:server_ids => []) unless step_params[:server_ids]
      step_params.update(:server_aspect_ids => []) unless step_params[:server_aspect_ids]
    end
    step_params.update(:app_id => @request.app_ids[0]) if step_params[:app_id].nil? || !@request.app_ids.include?(step_params[:app_id])
    #step_params[:installed_component_id] = @step.get_installed_component({ "component_id" => params[:step][:component_id] }).try(:id)
    if step_params[:owner_id].blank?
      step_params[:owner_id] = @request.user_id
      step_params[:owner_type] = "User"
    end
    #logger.info "SS__ StepParams: #{step_params.inspect}"
    step_params = update_automation_params(step_params,true)
    step_params = update_server_params(step_params)
    logger.info("----------- STEP PARAMS: " + step_params.inspect )
    StepService::ParamsPerPermissionSanitizer.new(step_params, @request, current_user).clean_up_params!

    update_step_references(step_params)
    if @step.update_attributes(step_params)
      @step.update_consistency_check(params)
      @step.update_attribute(:own_version, false) if params[:step][:version].blank?
      @step.update_script_arguments!({:argument => params[:argument]}) if params[:argument]
      old_value = @step.current_property_values(true).inspect
      @step.update_property_values!(params[:property_values])
      @step.upload_file_for_script_arguments(argument_file_hash)
      # Properties and script arguments may take long route to trace so not audited in model
      ActivityLog.log_event(@step, current_user, "updated property values #{old_value} => #{@step.current_property_values(true).inspect} ") if params[:property_values]
      @step.notes.create(:user_id => current_user.id, :content => params[:step][:note]) unless params[:step][:note].blank?
      if request.xhr? || (request.put? && params[:internet_explorer_fix].present?)
         @steps_with_invalid_components = @request.steps_with_invalid_components
         respond_to do |format|
           format.html{render :partial => 'requests/steps',
                       :locals => { :request => @request,
                                    :steps_with_invalid_components => @steps_with_invalid_components,
                                    :update_steps => true
                                  }}
         end
      else
        redirect_to edit_request_path(@request) + "#step_#{@step.id}_#{@step.position}_heading"
      end
    else
      # RF: removed RJS calls to fix internet explorer issues
      render :template => 'misc/error_messages_for', :layout => false, :locals => {:item => @step}
    end
  # rescue => e
  #   render :template => 'misc/error_messages_for', :layout => false, :locals => {:item => @step}
  end


  def update_procedure_step
    authorize! :edit_step, Request.new

    @step = Step.find(params[:id])
    authorize_archived_procedure_step!(@step)
    procedure = @step.floating_procedure
    step_params = reformat_dates_for_save(params[:step])
    step_params = update_automation_params(step_params, true)
    if step_params[:component_id].blank?
      step_params.update(:script_id => nil)
      step_params[:script_type] = nil
      step_params[:manual] = "1"
    end
    if step_params[:owner_id].blank?
      step_params[:owner_id] =  current_user.id
      step_params[:owner_type] = "User"
    end

    if @step.update_attributes(step_params)
      if request.xhr? || (request.put? && params[:internet_explorer_fix].present?)
        respond_to do |format|
           format.html{ render :partial => 'procedures/steps',
                               :locals => { :procedure => procedure
                                          }}
         end
      end
    end
  end

  def update_uploads

    @step = Step.find_by_id(params[:id].to_i)
    @step.update_attributes(params[:step]) if params[:step]
    respond_to do |format|
      if params[:ajax_upload]
        format.html{ render :partial => 'ajax_documents_upload_form'}
      else
        format.html{redirect_to :back}
      end
    end
  end

  def update_script
    if params[:id] && !params[:id].blank?
      step = Step.find_by_id(params[:id]) || @request.steps.build
    else
      step = @request.steps.build
    end

    @old_installed_component_id = step.installed_component_id
    @component_id = params[:component_id]
    step.component_id = @component_id
    step.installed_component_id = step.get_installed_component.try(:id)
    @step_owner_type = params[:step_owner_type]
    @step_owner_id = params[:step_owner_id]
    step.owner = params[:step_owner_type].constantize.find_by_id(params[:step_owner_id]) unless params[:step_owner_type].blank?
    @script_type = params[:script_type]
    script_type = @script_type
    # script_type = Script::ScriptTypes.reject { |my_script_type|
    #   params["#{my_script_type}_id"].blank?
    # }[0]
    step.script_id = params["script_id"]
    step.script_type = script_type #script_type.classify
    # script = script_type.classify.constantize.find(params["#{script_type}_id"])
    if script_type == "BladelogicScript"
      script = script_type.classify.constantize.find(params["script_id"])
    else
      script = Script.find(params["script_id"])
    end
    argument_values = step.script_argument_values_display({:old_installed_component_id => @old_installed_component_id})
    #logger.info "SS__ UpdateScript - compchange: #{component_is_changed.to_s}, stype: #{params["#{script_type}_id"]}, new: #{step.installed_component_id.to_s}, old: #{old_installed_component_id.to_s}\nVals: #{argument_values.inspect}"
    if script_type == "BladelogicScript"
      render :partial => 'steps/bladelogic/step_script', :locals => { :script => script, :step => step, :installed_component => step.installed_component, :argument_values => argument_values }
    else
      render :partial => 'steps/step_script', :locals => { :script => script, :step => step, :installed_component => step.installed_component, :argument_values => argument_values, :old_installed_component_id => @old_installed_component_id }
    end
  end

  def update_automation_params(cur_params, on_update = false)
    if params[:automation_type].present? && params[:automation_type] != "manual" && params[:step][:script_id].present?
      cur_params[:script_type] = params[:automation_type]
      cur_params[:manual] = "0"
    else
      if on_update && @step && @step.script_id.present?
        if ( params[:automation_type].present? && params[:automation_type] == "manual" ) || params[:step][:component_id].blank?
          @step.step_script_arguments.map(&:destroy)
          cur_params.update(:script_id => nil)
          cur_params[:script_type] = nil
          cur_params[:manual] = "1"
        end
      else
        cur_params.update(:script_id => nil)
        cur_params[:script_type] = nil
        cur_params[:manual] = "1"
      end
    end
    cur_params
  end

  def update_server_params(cur_params)
    # remaps the server ids for server aspects
    if cur_params[:server_ids][0] && cur_params[:server_ids][0].include?("sa_")
      cur_params[:server_aspect_ids] = cur_params[:server_ids].map{ |ids| ids.gsub("sa_","") }
      cur_params.delete(:server_ids)
    end
    cur_params
  end

  def update_procedure
    authorize! :edit_procedure, @request
    @step.update_attributes(params[:step])
    step_list_preferences_lists = current_user.step_list_preferences.active
    step_headers                = @request.request_view_step_headers

    respond_to do |format|
      format.js {
        render 'procedures/update_procedure', locals: {
          step:              @step,
          request:           @request,
          step_headers:      step_headers,
          step_preferences:  step_list_preferences_lists,
          steps_with_invalid_components: []
        }
      }
    end
  end

  # TODO - Piyush - Refactor - Take all these methods into one method.
  # Userd when form is submitted using '.inline_submit' See applicaiton.js#146

  def update_should_execute
    authorize! :turn_on_off_steps, @request
    @step.update_attribute(:should_execute, params[:step][:should_execute])
    render :nothing => true
  end

  def change_step_status
    @step = Step.find(params[:id])
    authorize_archived_procedure_step!(@step)
    @step.update_attribute(:should_execute, params[:step][:should_execute])
    render :nothing => true
  end

  def update_runtime_phase
    @step.update_attribute(:runtime_phase_id, params[:runtime_phase_id])
    render :nothing => true
  end

  def update_completion_state
    @step.update_attribute(:completion_state, params[:step][:completion_state])
    render :nothing => true
  end

  def new_procedure_step
    authorize! :add_serial_procedure_step, @request
    @users = @request.available_users
    @groups = Group.name_order
    if request.xhr? && params[:procedure_add_new]
      render(partial: 'steps/step_rows/step_form',
             locals: {request: @request,
                      procedure: true,
                      step: @step.steps.build(request: @request,
                                              owner: current_user,
                                              different_level_from_previous: true)})
    end
  end

  def update_status
    @step.update_attributes(params[:step])
    @step.update_property_values!(params[:property_values])

    note = params[:note]
    if params['start.x']
      @step.state_changer = current_user
      @step.lets_start!
    elsif params['resolve.x']
      @step.state_changer = current_user
      @step.resolve!

    elsif params['problem.x']
      @step.state_changer = current_user
      @step.problem!

    elsif params['block.x']
      @step.state_changer = current_user
      @step.block!

    elsif params['unblock.x']
      @step.state_changer = current_user
      @step.unblock!

    elsif params['complete.x']
      @step.state_changer = current_user
      @step.all_done!

    elsif params['reset.x']
      authorize! :reset_steps, @request
      @step.state_changer = current_user
      @step.reset!
    end
    @step.notes.create(:user_id => current_user.id, :content => note) unless note.blank?
    unfolded_steps = params[:dont_expand_step].present? ? nil : (params[:unfolded_steps].present? ? params[:unfolded_steps] : nil)
    find_request
    if request.xhr?
      if params['reset.x']
        index
      else
        render :nothing => true
      end
    else
      # removed adding anchor part as DE80974: Bank Of America/ISS04111927/ISS04112097 - re-running step within a
      # request sometime causes an auto refresh which reposition targeted step to top of the screen
      redirect_to edit_request_path(@request, :unfolded_steps => unfolded_steps) #+ "#step_#{@step.id}_#{@step.position}_heading"
    end
  end

  def add_note
    note = params[:note]
    @step = @step ? @step : Step.find(params[:id])

    authorize! :view_step_notes_tab, @request

    if note.present?
      n = @step.notes.create(:user_id => current_user.id, :content => note)
      render :partial => "steps/step_notes_values", :locals => { :step => @step, :note => n, :step_status => params[:step_status] }
    else
      render :nothing => true
    end
  end

  def destroy(steps=nil)
    association_to_include = [:step_script_arguments, :notes, :steps, :temporary_property_values, :uploads,
                              :linked_items, :step_holders, :step_references, :job_runs,
                              :server_aspects, :server_groups, :servers]

    if steps
      steps.each {|step| StepService::StepDestroyer.new(step).destroy }
      ActivityLog.log_event steps[0].request, current_user, "deleted steps: #{steps.map(&:name)}"
    else
      @step = Step.includes(association_to_include).find_by_id(params[:id].to_i)

      authorize_destroy(@step)
      StepService::StepDestroyer.new(@step).destroy
      ActivityLog.log_event @step.request, current_user, "deleted step #{@step.name}"
    end

    step = @request.steps.top_level.select([:id, :position]).first

    # Step whose id and position will be used in URL
    url_suffix = step ? "#step_#{step.id}_#{step.position}_heading" : ''

    if request.env['HTTP_REFERER'] && (request.env['HTTP_REFERER'] =~ /reorder_steps/)
      redirect_to :back
    else
      redirect_to(edit_request_path(@request) + url_suffix) unless request.xhr?
    end
  end

  def authorize_destroy(step)
    authorize_action = step.procedure? ? :remove_procedure : :delete_steps
    authorize! authorize_action, @request
  end

  def destroy_step_in_procedure
    step = Step.find(params[:id])
    authorize_archived_procedure_step!(step)
    procedure = Procedure.find(step.floating_procedure.id)
    step.destroy
    redirect_to edit_procedure_path(procedure)
  end


  def add_category
    @categories = Category.unarchived.step.associated_event(params[:associated_event])
    @event = params[:associated_event]
    @unfolded_steps = params[:unfolded_steps]

    respond_to do |format|
      format.html { render :partial => 'steps/add_category' }
    end
  end

  def expand_procedure
    render :partial => 'steps/expanded_procedure_for_reorder', :locals => { :step => @step, :request => @request, :start_number => params[:start_number] }
  end

  def collapse_procedure
    render :partial => 'steps/procedure_for_reorder', :locals => { :step => @step, :request => @request }
  end

  def update_server_selects
    #BJB 10-10-10 I think this is never called
    @servers = @request.environment.servers_with_default_first
    @server_groups = @request.environment.server_groups_with_default_first

    @selected_server_group_ids = params[:step][:server_group_ids] || []
    @selected_server_group_ids.map! { |id| id.to_i }

    @selected_server_groups = ServerGroup.find(@selected_server_group_ids)

    @selected_server_ids = params[:step][:server_ids] || []
    @selected_server_ids = @selected_server_ids.map { |id| id.to_i } + @selected_server_groups.map { |server_group| server_group.server_ids }
    @selected_server_ids.flatten!
    @selected_server_ids.uniq!

    @selected_servers = Server.find(@selected_server_ids)
  end

  def toggle_execution
    @step.update_attributes params[:step]
    render :nothing => true
  end

  def server_properties
    server_level_id = params[:server_level_id].gsub(/\D+/, '')
    server_level = ServerLevel.find_by_id(server_level_id)
    @server_aspects = ServerAspect.find_all_by_id(params[:step][:server_aspect_ids])
    @properties = server_level ? server_level.properties : []
  end

  def edit_execution_condition
    authorize! :edit_procedure_execute_conditions, Request.new
    if @step.execution_condition
      @selected_referenced_step_id = @step.execution_condition.referenced_step_id
      @selected_property_id = @step.execution_condition.property_id
      @selected_value = @step.execution_condition.value
      @selected_runtime_phase_id = @step.execution_condition.runtime_phase_id
      @selected_environment_type_ids = @step.execution_condition.environment_types.map(&:id)
      @selected_environment_ids = @step.execution_condition.environments.map(&:id)
    end
    @condition_type = !@step.execution_condition ? 'property' : @step.execution_condition.condition_type
    render :layout => false
  end

  def update_execution_condition
    authorize! :edit_procedure_execute_conditions, @request
    @step.execution_condition.try(:destroy)
    @step.execution_condition = nil
    @step.create_execution_condition(params[:execution_condition]) unless params[:clear]
    redirect_to @request
  end

  # tests can be run manually from steps in a request
  def run_now
    logger.info 'Running a step now: ' + params.to_s

    begin
      @step = Step.find_by_id(params[:id])
      @request = @step.request
      @script = @step.script
      if @step.present? && @script.present?
        #@script.run!(@step)
        @script.queue_run!(@step)
      else
        logger.info 'No valid step or missing arguments.'
      end
    rescue => e
      logger.info e.message
      flash[:notice] = e.message
    end

    render nothing: true
  end


  def properties_options
    referenced_step = Step.find_by_id(params[:execution_condition][:referenced_step_id])
    if referenced_step
      properties = referenced_step.properties.present? ? referenced_step.properties.active : []
      render :text => ApplicationController.helpers.options_from_collection_for_select(properties, :id, :name)
    else
      render :nothing => true
    end
  end

  def runtime_phases_options
    if params[:execution_condition]
      referenced_step = Step.find_by_id(params[:execution_condition][:referenced_step_id])
      phase = referenced_step.try(:phase)
    else
      phase = Phase.find_by_id(params[:step][:phase_id]) unless (params[:step][:phase_id]).blank?
    end

    if phase
      render :text => ApplicationController.helpers.options_from_collection_for_select(phase.runtime_phases, :id, :name)
    else
      render :nothing => true
    end
  end

  def environment_types_options
    #referenced_step = Step.find_by_id(params[:execution_condition][:referenced_step_id])
    #if referenced_step
    #  app = referenced_step.request.apps[0]
    #  env_types = app.environments.map(&:environment_type).uniq.sort_by { |env_type| env_type.position }
    #  render :text => ApplicationController.helpers.options_from_collection_for_select(env_types, :id, :name)
    #else
    #  render :nothing => true
    #end
    render :text => ApplicationController.helpers.options_from_collection_for_select(EnvironmentType.all, :id, :name)
  end

  def environments_options
    referenced_step = Step.find_by_id(params[:execution_condition][:referenced_step_id])
    if referenced_step
      app = referenced_step.request.apps[0]
      render :text => ApplicationController.helpers.options_from_collection_for_select(app.environments, :id, :name)
    else
      render :nothing => true
    end
  end

  def get_alternate_servers
    application_component   = ApplicationComponent.find_by_app_id_and_component_id(params[:app_id], params[:component_id])
    application_environment = ApplicationEnvironment.find_by_app_id_and_environment_id(params[:app_id], params[:environment_id])

    step = Step.find_by_id(params[:step_id])

    if application_component && application_environment
      installed_component       = InstalledComponent.find_by_application_component_id_and_application_environment_id(application_component.id, application_environment.id)
      server_collection         = installed_component.try(:server_associations) || []

      # exclude servers that are already shown
      if step
        server_collection         -= step.installed_component.try(:server_associations).to_a + step.targeted_servers
      elsif !params[:installed_component_id].empty?
        step_installed_component  = InstalledComponent.find(params[:installed_component_id])
        server_collection         -= step_installed_component.try(:server_associations).to_a
      end

      step ||= Step.new
    end

    render :partial => 'alternate_server_property_values', :locals => { :installed_component => installed_component,
                                                              :step => step,
                                                              :server_collection => server_collection.try(:uniq)
                                                            }
  end

  def bulk_update
    if @request
      @step_ids = params[:step_ids].map(&:to_i)
      if params[:apply_action].present?
        step_association_to_include = [:servers, :server_aspects, :parent, request: :apps, server_groups: :servers]
        # step_association_to_include = [:parent, request: :apps]
        @steps = @request.steps.where(id: @step_ids).includes(step_association_to_include)
        case params[:apply_action]
        when 'delete'
          authorize! :delete_steps, @request
          destroy(@steps)
          Step.update_position_column(@request)
          ajax_redirect(edit_request_path(@request)) && return
        when 'modify_should_execute'
          authorize! :turn_on_off_steps, @request
          should_execute = params[:step][:should_execute] == 'true' ? true : false
          @steps.where(protected_step: false).update_all(should_execute: should_execute)
        else
          if params[:apply_action] == 'modify_assignment' && params[:step][:owner_id].blank?
            params[:step][:owner_id] = @request.user_id
            params[:step][:owner_type] = 'User'
          end
          @steps.each do |step|
            step[:installed_component_id] = step.get_installed_component({ 'component_id' => params[:step][:component_id]}).try(:id)
            step.attributes = params[:step]
            if params[:apply_action] == 'modify_app_component' && params[:step][:component_id] && params[:step][:component_id].empty?
              step.manual = true
              step.script = nil
              step.script_type = nil
              step.step_script_arguments.destroy_all
            end

            if step.installed_component.present? && !params[:step][:component_id].nil?
              step.server_ids = step.installed_component.server_association_ids
            end
            step.save(:validate => false)
          end
        end
        index(@steps)
      else
        @steps = @request.steps.where(:id => params[:step_ids]).includes(:parent)
        @operation = params[:operation]
        if @operation == 'modify_assignment'
          @steps = @steps.includes(:owner)
          @users = @request.available_users
          @groups = @request.available_groups
        elsif @operation == 'modify_app_component'
          @steps = @steps.includes(:component, :request)
        elsif @operation == 'modify_task_phase'
          @steps = @steps.includes(:phase, :work_task)
        end
        @steps = @steps.group_by(&:id)
        render :template => 'steps/bulk_update', :layout => false
      end
    else
      bulk_update_procedure_steps
    end
  end

  def step_component_options
    options = if params[:step][:app_id].present?
      request = Request.find params[:request_id]
      ApplicationController.helpers.options_from_collection_for_select(request.common_components_installed_on_env_of_app(params[:step][:app_id]), :id, :name)
    else
      "<option value=''>Select</option>"
    end
    render :text => options
  end

  def search
    steps = @request.steps.search(params[:query].strip)
    respond_to do |format|
      format.json do
        render :json => steps.map(&:id).map(&:to_s).to_json
      end
    end
  end

  def get_recent_activities
    @recent_activities = RecentActivity.order("recent_activities.id desc").limit(3)
  end

  def my_applications
    @my_applications = paginate_records(current_user.accessible_apps, params, 6, (request.xhr? ? params[:page] : 1))
    @page_no = params[:page] || 1
    render :partial => "dashboard/self_services#{params[:page].present? ? '/tables' : ''}/my_applications" if request.xhr?
  end

  def assign_tickets
    ticket_ids = params['ticket_ids']
    tickets = []
    if ticket_ids
      ticket_ids.each do  |t|
        tickets.push(Ticket.find(t.to_i))
      end
    end

    actions = ['disassociate']
    actions.push('refresh') if params[:step_id].present?

    render :partial => 'tickets/unpaged_tickets_table', :locals => {:tickets => tickets, :actions => actions}
  end

  def unassign_ticket
    @step = Step.find(params[:id])
    if params[:ticket_id].blank?
      flash[:error] = "Ticket not specified"
      render :nothing => true
    end
    @step.tickets.delete(@step.tickets.find(params[:ticket_id].to_i))
    @step.save!
    render :partial => 'tickets/unpaged_tickets_table', :locals => {:request => @step.request, :step => @step, :tickets => @step.tickets}
  end

  def can_delete_step
    step_exe_cond = StepExecutionCondition.find(:all, :conditions => {:referenced_step_id => params[:id]})
    if step_exe_cond.present?
      procedure_names = Step.find(:all, :conditions => {:id => step_exe_cond.map(&:step_id)}).map(&:name).join(",")
      render :text => "Step is used in procedure '#{procedure_names}' execution condition. Are you sure you want to delete the step?"
    else
      render :text => "Are you sure you want to delete the step?"#, :content_type => "html/text"
    end
  end

  def estimate_calculation
    if !params[:c_d].blank? && !params[:s_d].blank?
      start_date = Time.strptime(params[:s_d],GlobalSettings[:default_date_format])
      end_date = Time.strptime(params[:c_d],GlobalSettings[:default_date_format])
      start_time = start_date.to_time if start_date.respond_to?(:to_time)
      end_time = end_date.to_time if end_date.respond_to?(:to_time)
      distance_in_seconds = ((end_time - start_time).abs).round

      components = get_time_diff_components(%w(hour minute), distance_in_seconds)

      render :text => components.join(',')
    else
      render :nothing => true
    end
  end

  def render_output_step_view
    step = Step.find(params[:step_id])
    installed_component = InstalledComponent.find(params[:installed_component_id]) if params[:installed_component_id].present?
    script = Script.find(params[:script_id])
    argument_values = step.script_argument_values_display
    case params[:parameter_type]
    when "Input"
      render :partial => 'steps/step_script', :locals => { :script => script, :step => step, :installed_component => installed_component, :argument_values => argument_values, :hide_inline_form => "true" }
    when "Output"
      render :partial => 'steps/step_script', :locals => { :script => script, :step => step, :installed_component => installed_component, :argument_values => argument_values, :hide_inline_form => "true", :output_parameters => true }
    else
      render :nothing => true
    end
  end

  def update_step_references(step_params)
    if params[:step_references]
      step_params[:reference_ids] = params[:step_references].keys
    elsif params[:content_tab_viewed]
      step_params[:reference_ids] = []
    end
    step_params
  end

  protected

  def find_request
    if params[:request_id].to_i > GlobalSettings[:base_request_number]
      @request = Request.find_by_number params[:request_id]
    end
  end

  def find_step
    @step = @request.steps.find_by_id(params[:id].to_i)
    @step = @step.steps.find_by_id(params[:step_id].to_i) if @step && @step.procedure? && params[:step_id]
  end

  def paginate_steps
    @per_page = params[:per_page]
    per_page = @per_page.blank? ? 20 : @per_page.to_i
    args_hash = {:page => params[:page], :per_page => per_page}
    @steps = @steps.paginate(args_hash)
  end

  def set_step_dates(step, step_dates)
    step_dates.each { |key, val|
      step.update_attribute(key, val)
    }
  end

  def get_time_diff_components(intervals, distance_in_seconds)
    components = []
    intervals.each do |interval|
        component = (distance_in_seconds / 1.send(interval)).floor
        distance_in_seconds -= component.send(interval)
        components << component
    end
    components
  end

  def bulk_update_procedure_steps
    @step_ids = params[:step_ids].map(&:to_i)
    @steps = Step.where(:id => @step_ids)
    @procedure = @steps.first.floating_procedure
    authorize_archived_procedure!(@procedure)
    if params[:apply_action].present?
      case params[:apply_action]
      when "delete"
        @steps.destroy_all
        #Step.update_position_column(@request)
        ajax_redirect(edit_procedure_path(@procedure)) && return
      when "modify_should_execute"
        @steps.collect{|step| step.update_attribute(:should_execute, params[:step][:should_execute])}
      else
        if params[:apply_action] == 'modify_assignment' &&  params[:step][:owner_id].blank?
          params[:step][:owner_id] = current_user.id
          params[:step][:owner_type] = "User"
        end
        @steps.each do |step|
          #step[:installed_component_id] = step.get_installed_component({ "component_id" => params[:step][:component_id]}).try(:id)
          step.attributes = params[:step]
          step.save(:validate => false)
          if step.installed_component.present? && !params[:step][:component_id].nil?
            step.update_attribute(:server_ids, step.installed_component.server_association_ids)
            step.save(:validate => false)
          end
        end
      end
      render_updated_steps(@steps)
    else
      @steps = @steps.group_by(&:id)
      @operation = params[:operation]
      app_ids = App.where(:id => @procedure.apps.map(&:id)).select([:id]) || 0
      user_ids  = AssignedApp.where(:app_id => app_ids.map(&:id)).select([:user_id])
      if @operation == "modify_assignment"
        @users = User.where(:id => user_ids.map(&:user_id))
        @groups = Group.where(:id => @users.collect{|u| u.group_ids}.flatten.uniq).active
      end
      render :template => "steps/bulk_update", :layout => false
    end
  end

  private

  def perform_filtering(steps, parameters)
    session[session_filter_var] ||= HashWithIndifferentAccess.new
    session[session_filter_var] = parameters[:filters] if parameters[:filters].present?
    reset_filters_hash! if parameters[:clear_filter]
    filtered = steps.filtered(session[session_filter_var])
    [filtered, session[session_filter_var]]
  end

  def get_references_for_package_context(step, package_or_instance)
    if package_or_instance.eql?(:package_instance.to_s) && step.package_instance
      step.package_instance.instance_references
    elsif package_or_instance.eql?(:package.to_s) && step.package
      step.package.references
    end
  end

  def step_tab_permission
    ('view_step_%s_tab' % params[:li_id].gsub('st_', '')).to_sym
  end

  def authorize_tab
    return if params[:li_id] == 'st_content'
    authorize! step_tab_permission, Request.new
  end

  def authorize_archived_procedure_step!(step)
    raise CanCan::AccessDenied if step.archived_procedure?
  end

  def authorize_archived_procedure!(procedure)
    raise CanCan::AccessDenied if procedure.archived?
  end

  def set_step_permissions(request)
    @can_add_serial_procedure_step = can?(:add_serial_procedure_step, request)
    @can_remove_procedure = can?(:remove_procedure, request)
    @can_edit_procedure_execute_conditions = can?(:edit_procedure_execute_conditions, request)
    @can_run_step = can?(:run_step, request)
    @can_edit_step = can?(:edit_step, request)
    @can_reset_step = can?(:reset_steps, request)
    @can_delete_steps = can?(:delete_steps, request)
    @can_inspect_steps = can?(:inspect_steps, request)
    @can_turn_on_off_steps = can?(:turn_on_off_steps, request)
    @request_editable_by_user = request.editable_by?(current_user)
    @request_available_for_user = request.is_available_for?(current_user)
  end
end

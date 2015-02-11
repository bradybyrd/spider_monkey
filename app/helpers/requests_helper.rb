################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module RequestsHelper

  def request_row_class(has_view, request)
    css_class = []

    if request_row?(has_view, request)
      css_class << 'request_row'
    end
    if request_clickable?(request)
      css_class << 'clickable'
    end

    css_class.join(' ')
  end

  def request_clickable?(request)
    can?(:inspect, request)
  end

  def request_row?(has_view, request)
    !has_view && can?(:view_requests_list, request)
  end

  def request_release_td(req)
    request_sorted_td(req, :release, name_of(req.release))
  end

  def sortable_th(name, opts = {})
    column = opts.yank!(:column, name)
    classes = [opts[:class], 'sortable']
    filters = @request_dashboard[:request_filters] || @filters
    user_list_order = @request_dashboard[:user_list_order] || (defined?(current_user) && current_user.list_order)

    if filters.try(:[], :sort_scope) == column
      classes << filters.try(:[], :sort_direction)
    end

    opts[:class] = classes.join(' ')
    opts[:class] << user_list_order if name == 'Id' && !filters[:sort_scope].present?

    content_tag(:th, name, {'data-column' => column}.merge(opts))
  end

  def request_owner_td(req)
    request_sorted_td(req, :owner, name_of(req.owner))
  end

  def request_requestor_td(req)
    request_sorted_td(req, :owner, name_of(req.requestor))
  end

  def request_sorted_td(req, attribute, value)
    if "#{attribute}".eql? 'release'
      "<td #{request_sort_data_attr(req, attribute)} data-number=\"#{req.number}\", class='hideRelease'>#{ERB::Util.html_escape value}</td>".html_safe
    else
      "<td #{request_sort_data_attr(req, attribute)} data-number=\"#{req.number}\">#{ERB::Util.html_escape value}</td>".html_safe
    end
  end

  def request_sort_data_attr(req, attribute)
    "data-#{attribute}=\"#{ERB::Util.html_escape(name_of(req.send attribute))}\""
  end

  def stringify_filters(other_params = {})
    filter_params = {}
    other_params = other_params.merge(:display_format => params[:display_format])
    @filters.each { |k, v| filter_params["filters[#{k}]"] = v }
    all_params = filter_params.merge other_params
    return '' if all_params.empty?
    '?'+all_params.find_all { |_, v| !v.blank? }.collect { |k, v| "#{k}=#{v}" }.join('&')
  end

  def day_classes_for(day)
    classes = ['day']
    classes << 'today' if day.today?
    classes << 'inactive' unless @calendar.include?(day)
    classes << 'weekend' if day.weekend?
    classes << 'past' if day.past?
    classes.join(' ')
  end

  def ordered_requests_for_day(day)
    day.sort_by { |request| request.order_time }
  end

  def steps_container
    # pass in comma-separated parameters unfolded_steps to partial to declare the ids of steps that should be opened
    content_tag(:div,
                render('requests/steps', request: @request,
                                         steps_with_invalid_components: @steps_with_invalid_components),
                attributes_for_step_container(@request).merge(id: 'steps_container'))
  end

  def steps_container_pdf
    # pass in comma-separated parameters unfolded_steps to partial to declare the ids of steps that should be opened
    content_tag(:div,
                render(:partial => 'requests/steps_for_pdf.html.erb',
                       :locals => {:request => @request,
                                   :steps_with_invalid_components => @steps_with_invalid_components,
                                   :unfolded_steps => @unfolded_steps}),
                attributes_for_step_container(@request).merge(:id => 'steps_container'))
  end

  def attributes_for_step_container(request)
    class_name, update_with = '', ''
    if request.already_started? && params[:controller] == 'requests'
      class_name = 'auto_update'
      update_with = request_steps_path(request)
    end

    {:class => class_name, :update_with => update_with}
  end

  def component_options_for_select(request)
    components_to_be_destroyed = Component.find_all_by_id(session[:components_to_be_destroyed])
    valid_components = request.available_components - components_to_be_destroyed
    options_for_select([''].concat(valid_components.map { |comp| [comp.name, comp.id] }))
  end

  def display_hour(hour_digit)
    if hour_digit == 0
      '12:00AM'
    elsif hour_digit == 12
      '12:00PM'
    elsif hour_digit > 12
      "#{hour_digit % 12}:00PM"
    else
      "#{hour_digit}:00AM"
    end
  end

  def request_category_available_for?(event)
    !Category.unarchived.request.associated_event(event).empty?
  end

  def request_edit_page_title_for(request, activity_summary=nil)
    req = activity_summary.nil? ? 'Request ' : ''
    req + if request.template?
            "Template - #{request.request_template.name}"
          else
            request.name.present? ? "#{request.number} - #{truncate(request.name, :length => 30)}" : "#{request.number}"
          end
  end

  def lock_icon_for_requestor(request)
    # TODO: requestor_access here
    if can?(:lock_icon, request) && request.plan_member.try(:stage)
      return image_tag('icons/lock.png') + ' ' unless request.plan_member.stage.requestor_access
    end
    ' '
  end

  def request_edit_page_heading_for(request)
    if request.template?
      if request.request_template.parent_id
        parent_template = request.request_template.parent_template
        link_to "Request Template - #{parent_template.name}", request_path(parent_template.request), :style => 'color:#000000;'
      else
        "Request Template - #{ request.request_template.name }"
      end
    else
      "Request: <span class='requestNumber'>#{ request.number } &nbsp;-&nbsp;#{ request.name }</span>"
    end
  end

  def request_date(date)
    date ? date.default_date_format : ''
  end

  def request_duration(req)
    if req.complete?
      duration = hour_minute_estimate(req.total_duration)
    else
      duration = req.estimate.nil? ? '00:00' : hour_minute_estimate(req.estimate)
    end

    "#{duration} (hh:mm)"
  end

  def estimated_time_for_steps(req)
    hour_minute_estimate(req.total_duration_steps)
  end

  def total_time_for_steps(req)
    hour_minute_estimate(req.total_execution_time_of_all_steps)
  end


  def request_date_field(duration, style='display:none;')
    content_tag(:div, date_field_tag(duration, Request::TimeLap[duration], {}, 'float:left; padding-left:4px; width:16px; height:16px;'),
                :id => duration.gsub(/[^A-Za-z_]/, ''),
                :style => style << ' float:left;'
    )
  end

  def get_checked_environments(request_id, env_id)
    RequestsApplication.find_by_request_id_and_environment_id(request_id, env_id)
  end

  def show_rescheduled_field_for(request)
    'display:none;' unless request.rescheduled
  end

  def class_for_rescheduled_field(request)
    req_audits = request.audits.all(:conditions => {:action => 'update'})
    if request.new_record?
      'new_record'
    else
      req_audits.collect { |a| a[:changes].respond_to?('keys') ? a[:changes].keys : [a[:changes]] }.flatten.include?('scheduled_at') ? 'old_record' : 'new_record'
      #req_audits.collect {|a|a[:changes].keys}.flatten.include?('scheduled_at') ? "old_record" : "new_record"
    end
  end

  # Display 'Last Deploy' Date and Time irrespective of request, and respective to Application and Components - by SN
  def last_deployed_at(request, component_id)
    application_component = []
    application_environment = []
    request.apps.each do |app|
      application_component << ApplicationComponent.find_by_app_id_and_component_id(app.id, component_id)
      application_environment << ApplicationEnvironment.find_by_app_id_and_environment_id(app.id, request.environment_id)
    end
    #installed_component = InstalledComponent.find_by_application_component_id_and_application_environment_id(application_component.try(:id), application_environment.try(:id))
    application_component.compact!
    application_environment.compact!
    installed_component = InstalledComponent.find_by_application_component_id_and_application_environment_id(application_component, application_environment) rescue false
    if installed_component.present?
      installed_component.last_deploy || 'Never'
    else
      'Error'
    end
  end

  def get_current_installed_version(request, component_id)
    application_component = ApplicationComponent.find_by_app_id_and_component_id(request.apps.map(&:id), component_id)
    application_environment = ApplicationEnvironment.find_by_app_id_and_environment_id(request.apps.map(&:id), request.environment_id)
    installed_component = InstalledComponent.find_by_application_component_id_and_application_environment_id(application_component, application_environment)
    installed_component.try(:version)
  end

  def request_info_for_rss(request)
    li = content_tag(:li, "ID: #{request.number}")
    li += content_tag(:li, "Status: #{request.aasm_state.humanize}")
    li += content_tag(:li, "Owner: #{name_of(request.owner)}")
    li += content_tag(:li, "Process: #{request.business_process_name}")
    li += content_tag(:li, "Release: #{request.aasm_state.humanize}")
    li += content_tag(:li, "App: #{request.app_name.to_sentence}")
    li += content_tag(:li, "Environment: #{request.environment.try(:name)}")
    li += content_tag(:li, "Scheduled: #{request.scheduled_at.try(:default_format)}")
    li += content_tag(:li, "Actual Start: #{request.started_at.try(:default_format)}")
    li += content_tag(:li, "Actual Completion: #{request.completed_at.try(:default_format)}")
    li += content_tag(:li, "Duration: #{request_duration(request)}")
    li += content_tag(:li, "Due By: #{request.target_completion_at.try(:default_format)}")
    li += content_tag(:li, "Participants: #{request.participant_names.to_sentence}")
    li += content_tag(:li, "Steps: #{request.executable_steps.count}")
    content_tag(:ul, li)
  end

  def latest_requests(requests) # Pick up Top 3 requests ids
    links = []

    requests.first(3).each do |request|
      links << link_to_if(can?(:inspect, request), request.number, request_path(request.number)).html_safe
    end

    if links.empty?
      '-'.html_safe
    else
      (links.join(', ') + link_to('...', 'javascript:void(0);', :style => 'cursor:default;text-decoration:none;')).html_safe
    end
  end

  def format_to_sentence(request_numbers)
    request_numbers.to_sentence
  end

  def request_id_td(request, current_user_app_ids)
    path = request.is_visible?(current_user, current_user_app_ids) ? request : '#'

    content_tag(:td,
                link_to_if(can?(:inspect, request),
                content_tag(:div, h(request.aasm.current_state), class: "#{request.aasm.current_state}RequestStep state"), path),
                class: "status#{person_cell?(request)}",
                nowrap: '',
                style: 'width: 60px;',
                title: person_cell_title(request)
    )
  end

  def person_cell?(request)
    ' person_cell' if current_user.is_owner_or_requestor_of?(request)
  end

  def person_cell_title(request)
    'You are the Owner and/or Requestor' if current_user.is_owner_or_requestor_of?(request)
  end

  def request_number_td(request)
    content_tag(:td, request.number, {:class => 'request_number'}, false)
  end

  def request_name_td(request)
    content_tag(:td, "<strong>#{ ensure_space(h(truncate(request.name, :length => 25))) }</strong>",
                {:title => h(request.name)}, false)
  end

  def request_business_process_td(request)
    content_tag(:td, ensure_space(h(request.business_process_name)), {}, false)
  end

  def request_app_td(request)
    apps_title = ensure_space(request.app_name.to_sentence)
    app_names = ensure_space(h(truncate(request.app_name.to_sentence, :length => 25)))
    content_tag(:td, app_names, {:title => apps_title}, false)
  end

  def request_env_td(request)
    env_name = if request.environment # && !request.environment.default?
                 ensure_space(h(truncate(request.environment_label, :length => 25)))
               else
                 '&nbsp;'.html_safe
               end
    content_tag(:td, env_name, {:title => h(request.environment.try(:name))}, false)
  end

  def request_deployment_window_td(request)
    content_tag(:td, ensure_space(h(request.deployment_window_event_name)), {}, false)
  end

  def request_scheduled_td(request)
    content_tag(:td, request.scheduled_at.try(:default_format_date_time), {:class => 'date scheduled'}, false)
  end

  def request_run_td(request)
    content_tag(:td, ensure_space(request.run.try(:name)), {}, false)
  end

  def request_duration_td(request)
    content_tag(:td, ensure_space(display_time(request.completion_time_seconds)), {}, false)
  end

  def request_due_td(request)
    content_tag(:td, request.target_completion_at.try(:default_format_date_time), {:class => 'date'}, false)
  end

  def request_steps_td(request)
    content_tag(:td, request.executable_steps.size, {:style => 'text-align:center;'}, false)
  end

  def request_created_td(request)
    content_tag(:td, request.created_at.try(:default_format_date_time), {:class => 'request_created_on'}, false)
  end

  def request_participants_td(request)
    request_participants_names = request.participant_names.to_sentence
    request_participants_names = ERB::Util.html_escape request_participants_names
    participants_title=ensure_space(request_participants_names)
    participants_names=ensure_space(h(truncate(request_participants_names, :length => 25)))
    content_tag(:td, participants_names, {:title => participants_title}, false)
  end

  def request_project_td(request)
    if request.activity
      project_title = ensure_space(request.activity.name)
      project_name = ensure_space(h(truncate(request.activity.name, :length => 25)))
      content_tag(:td, project_name, {:title => project_title}, false)
    else
      content_tag(:td, '&nbsp;', '&nbsp;', false)
    end
  end

  def request_team_td(request)
    team_title = ensure_space(request.apps.map(&:team_names).to_sentence)
    team_name = ensure_space(h(truncate(request.apps.map(&:team_names).to_sentence, :length => 25)))
    content_tag(:td, team_name, {:title => team_title}, false)
  end

  def request_package_contents_td(request)
    package_contents_title = ensure_space(request.package_contents.map(&:name).join(', ')) #package_content_tags
    package_contents_name = ensure_space(h(truncate(request.package_contents.map(&:name).join(', '), :length => 25)))
    content_tag(:td, package_contents_name, {:title => package_contents_title}, false)
  end

  def request_started_at_td(request)
    content_tag(:td, request.started_at.try(:default_format_date_time), :class => 'request_started_at')
  end

  def choose_request_list_partial
    request_list_preferences.empty? ? 'list' : 'custom_list'
  end

  def display_time(total_seconds)
    total_seconds = total_seconds.to_i

    days = total_seconds / 86400
    hours = (total_seconds / 3600) - (days * 24)
    minutes = (total_seconds / 60) - (hours * 60) - (days * 1440)
    seconds = total_seconds % 60

    display = ''
    display_concat = ''
    if days > 0
      display = display + display_concat + "#{days}d"
      display_concat = ' '
    end
    if hours > 0 || display.length > 0
      display = display + display_concat + "#{hours}h"
      display_concat = ' '
    end
    if minutes > 0 || display.length > 0
      display = display + display_concat + "#{minutes}m"
      display_concat = ' '
    end
    display = display + display_concat + "#{seconds}s"
  end

  def wrap_text(txt, col = 80)
    txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\3\n")
  end

  def component_select_tag(step, disable_fields = false)
    # RF - I have removed following IE with fix because it breaks the GUI, if any defect will be raised for incomplete option content than we have to see a different solution.
    # :onmousedown=>"if($.browser.msie){this.style.position='absolute';this.style.width='auto'}", :onblur=>"this.style.position='';this.style.width=''"
    select_tag('step[component_id]',
               ((step.protect_automation? && step.auto? ? '' : "<option value=''>Select</options>") +
                   options_for_select(step_components_options(@request, step))).html_safe,
               disabled: disable_fields,
               onmousedown: "if($.browser.msie && $.browser.version != 9){this.style.position='absolute';this.style.width='auto'}",
               onblur: "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               onchange: "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               title: step.component.try(:name),
               data: step_data_attributes(step)
    ).html_safe
  end

  def related_object_type_select_tag(step, disable_fields = false)
    # RF - I have removed following IE with fix because it breaks the GUI, if any defect will be raised for incomplete option content than we have to see a different solution.
    # :onmousedown=>"if($.browser.msie){this.style.position='absolute';this.style.width='auto'}", :onblur=>"this.style.position='';this.style.width=''"
    select_tag('step[related_object_type]',
               options_for_select([['Select', '']] + Step::RELATED_OBJECT_TYPES.map{|type| [type.to_s.humanize, type]},
                                  selected: step.related_object_type,
                                  disabled: disable_object_type_options_for(step)
                                  ),
               :disabled => disable_fields,
               :onmousedown => "if($.browser.msie && $.browser.version != 9){this.style.position='absolute';this.style.width='auto'}",
               :onblur => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               :onchange => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               data: step_data_attributes(step)
    ).html_safe
  end

  def package_select_tag(step, disable_fields = false)
    # RF - I have removed following IE with fix because it breaks the GUI, if any defect will be raised for incomplete option content than we have to see a different solution.
    # :onmousedown=>"if($.browser.msie){this.style.position='absolute';this.style.width='auto'}", :onblur=>"this.style.position='';this.style.width=''"
    select_tag('step[package_id]',
               options_for_select([['Select', '']]) + options_for_select(step_packages_options(@request, step)).html_safe,
               :disabled => disable_fields,
               :onmousedown => "if($.browser.msie && $.browser.version != 9){this.style.position='absolute';this.style.width='auto'}",
               :onblur => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               :onchange => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               :title => step.package.try(:name),
               data: step_data_attributes(step)
    ).html_safe
  end

  def package_instances_select_tag(step, package, disable_fields = false)
    # RF - I have removed following IE with fix because it breaks the GUI, if any defect will be raised for incomplete option content than we have to see a different solution.
    # :onmousedown=>"if($.browser.msie){this.style.position='absolute';this.style.width='auto'}", :onblur=>"this.style.position='';this.style.width=''"
    select_tag('package[instance_id]',
               options_for_select([['Select', ''], ['Create New', 'create_new'], %w(Latest latest)],
                                  (step.create_new_package_instance ? 'create_new' : (step.latest_package_instance ? 'latest' : ''))) +
                   options_for_select(package_instance_options(step, package)).html_safe,
               :disabled => disable_fields,
               :onmousedown => "if($.browser.msie && $.browser.version != 9){this.style.position='absolute';this.style.width='auto'}",
               :onblur => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               :onchange => "if($.browser.msie && $.browser.version != 9){this.style.position='';this.style.width=''}",
               :title => package.name,
               data: step_data_attributes(step)
    ).html_safe
  end

  def step_components_options(request, step)
    apps                    = request.apps
    environment_id          = request.environment_id

    apps.each do |app|
      # TODO: `installed_components` should be fetched in the controller and sent as an argument
      installed_components    = app.installed_components_for_env(environment_id)

      next if installed_components.none?

      @app_components_options = "<optgroup label='#{app.name}' title='#{app.name}'>"
      step_component_id       = step.new_record? ? nil : step.component.try(:id)

      installed_components.each do |installed_component|
        component               = installed_component.component
        selected                = step_component_id == component.id

        @app_components_options += "<option #{"selected='selected'" if selected} value='#{component.id.to_s}'"
        @app_components_options += "title='#{component.name}' app_id='#{app.id}'"
        @app_components_options += "installed_component_id='#{installed_component.id}' >#{component.name}</option>"
      end

      @app_components_options += '</optgroup>'
    end

    check_package_templates
    @app_components_options || ''
  end

  def step_packages_options(request, step)
    request.apps.each do |app|
      packages    = app.packages

      next if packages.none?

      @app_packages_options = "<optgroup label='#{app.name}' title='#{app.name}'>"
      step_package_id       = step.new_record? ? nil : step.package.try(:id)

      packages.each do |package|
        selected                = step_package_id == package.id

        @app_packages_options += "<option #{"selected='selected'" if selected} value='#{package.id.to_s}'"
        @app_packages_options += "title='#{package.name}' app_id='#{app.id}'"
        @app_packages_options += "package_id='#{package.id}' >#{package.name}</option>"
      end

      @app_packages_options += '</optgroup>'
    end

    @app_packages_options || ''
  end

  def package_instance_options(step, package)
    @app_packages_instances_options = "<optgroup label='#{package.name}' title='#{package.name}'>"
    step_package_id       = step.new_record? ? nil : step.package_instance.try(:id)

    package.package_instances.each do |package_instance|
      selected                = step_package_id == package_instance.id

      @app_packages_instances_options += "<option #{"selected='selected'" if selected} value='#{package_instance.id.to_s}'"
      @app_packages_instances_options += "title='#{package_instance.name}' package_id='#{package.id}'"
      @app_packages_instances_options += "package_instance_id='#{package_instance.id}' >#{package_instance.name}</option>"
    end

    @app_packages_instances_options += '</optgroup>'
    @app_packages_instances_options || ''
  end

  def check_installed_components(app, request, comp)
    app_component, installed_component = nil, nil

    app_component       = app.application_components.select { |app_comp| app_comp.component_id == comp.id }.first if app and comp
    installed_component = request.environment.installed_components.select { |ic| ic.application_component_id == app_component.id } if app_component

    true if installed_component
  end

  def check_package_templates
    if @request.has_no_available_package_templates?
      @app_components_options
    else
      @app_components_options += "<optgroup label='Package Templates'>" +
          options_for_select(@request.available_package_templates.flatten.collect { |c| [c.name, "package_template_#{c.id}"] },
                             "package_template_#{@step.try(:selected_package_template_id)}")
      @app_components_options += '</optgroup>'
    end
  end

  def request_apps_environments(request)
    envs = []
    request.apps.each do |app|
      envs << app.environments
    end
    envs.flatten!
  end

  def app_ids_for(request, env)
    app_ids = []
    env_app_ids = env.apps.map(&:id)
    request.apps.map(&:id).collect { |app_id| app_ids << app_id if env_app_ids.include?(app_id) }
    app_ids.join('_')
  end

  def disable_all_request_form_fields(request)
    !enable_all_request_form_fields(request)
  end

  #INFO: why this method is in view helpers?
  def enable_all_request_form_fields(request)
    request.new_record? || request.owner == current_user || request.requestor == current_user || current_user.root?
  end

  def app_name_links(request, show_version = false)
    app_names = []
    request.apps.each_with_index do |app, _|
      app_name = "#{app.name} #{(show_version && app.app_version.present?) ? "#{app.app_version}" : '' }"
      app_names << link_to_if((can? :update, app), h(app_name), edit_app_path(app))
    end
    app_names.join(', ')
  end

  def params_for_currently_running_steps
    return @user_group_id_params if @user_group_id_params
    @user_group_id_params = {}
    @user_group_id_params[:user_id] = @selected_user.id unless @selected_user.nil?
    @user_group_id_params[:group_id] = @selected_group.id unless @selected_group.nil?
    @user_group_id_params[:should_user_include_groups] = true unless @should_user_include_groups.nil?
    @user_group_id_params
  end

  def version_select(step, tag_id = 'step[version]')
    return '' unless step.installed_component
    version_options = options_from_collection_for_select(step.available_versions, 'id', 'name', step.version_tag_id)
    #version_options = "<option></option>" + version_options
    select_tag(tag_id, raw(version_options), :prompt => 'choose version', :id => 'step_version_tag_id', :class => 'use_remote_options get_mapped_values', :disabled => disabled_step_editing?(step))
  end

  def step_colspan(columns=0)
    colspan = {:cols1 => 0, :cols2 => 0}
    if columns == 0 || columns == 6
      colspan = {:cols1 => 3, :cols2 => 4}
    elsif columns == 5
      colspan = {:cols1 => 3, :cols2 => 3}
    elsif columns == 4
      colspan = {:cols1 => 2, :cols2 => 3}
    elsif columns == 3
      colspan = {:cols1 => 2, :cols2 => 2}
    elsif columns == 2
      colspan = {:cols1 => 1, :cols2 => 2}
    elsif columns == 1
      colspan = {:cols1 => 1, :cols2 => 1}
    end

    colspan
  end

  def time_for_completion(req)
    completed_at = req.completed_at
    started_at = req.started_at
    if completed_at.nil? || started_at.nil?
      '--:--'
    else
      time_diff_in_seconds = (completed_at - started_at).round
      convert_seconds_to_hhmm(time_diff_in_seconds)
    end
  end

  def total_activity_time(req)
    due_by = req.target_completion_at
    planned_at = req.scheduled_at
    if due_by.nil? || planned_at.nil?
      '--:--'
    else
      time_diff_in_seconds = (due_by - planned_at).round
      convert_seconds_to_hhmm(time_diff_in_seconds)
    end
  end

  def total_duration_for_request(req)
    step_estimate_blank_exists = (req.steps.should_execute.count(:conditions => {:estimate => nil}) > 0)
    step_estimate_blank_exists ? ">#{total_time_for_steps(req)}" : total_time_for_steps(req)
  end

  def stomp_js_path
    endpoint = if defined?(TorqueBox) && TorqueBox.fetch('stomp-endpoint')
                 if request.protocol =~ /https/
                   TorqueBox.fetch('stomp-endpoint-secure')
                 else
                   TorqueBox.fetch('stomp-endpoint')
                 end
               else
                 OpenStruct.new(host: 'localhost', port: 8435)
               end
    "#{request.protocol}#{endpoint.host}:#{endpoint.port}/stomp.js"
  end

  private

  def disable_object_type_options_for(step)
    types_array = Step::RELATED_OBJECT_TYPES.select do |type|
      type.to_s if cannot?(:"select_step_#{type}", step.request)
    end
    types_array << '' if types_array.size == Step::RELATED_OBJECT_TYPES.size
    types_array
  end

  def step_data_attributes(step)
    {
        protected: step.protected?,
        protect_automation: step.protect_automation?,
        :'step-editable' => step.editable?
    }
  end

  def requests_tab_path(show_all)
    show_all ? request_dashboard_path : root_path
  end
end

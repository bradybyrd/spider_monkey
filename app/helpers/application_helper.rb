################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'context_root'
require 'fusion_charts/fusion_charts_helper'
require 'multiple_picker'
require 'fusion_charts/xml_helper'
require 'fusion_charts/fc_parameters'

module ApplicationHelper
  include XmlHelper
  include FusionChartsHelper
  include MultiplePicker::Helper
  include ObjectStateHelper

  NUMBER_OF_COMPONENT_COLORS = 20

  IPv4_PART = /\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/ # 0-255
  URL_REGEXP = %r{
    \A
    ([^\s:@]+:[^\s:@]*@)?                                        # optional username:pw@
    ( (([^\W_]+\.)*xn--)?[^\W_]+([-.][^\W_]+)*\.[a-z]{2,6}\.? |  # domain (including Punycode/IDN)...
        #{IPv4_PART}(\.#{IPv4_PART}){3} )                        # or IPv4
    (:\d{1,5})?                                                  # optional port
    ([/?]\S*)?                                                   # optional /whatever or ?whatever
    \Z
  }iux

  def draw_tabs(opts = {}, &block)
    @selected_sub_tab = opts[:selected]

    concat(content_tag(:ul, capture(&block), :class => opts[:class]))
  end

  def pipe_separator
    raw "&nbsp;|&nbsp;"
  end

  def link_to_if_with_custom_text(condition, link_text, plain_text, path)
    link_to_if condition, link_text, path do
      content_tag :span do
        condition ? link_text : plain_text
      end
    end
  end

  def tab_actions(actions_prefix)
    if actions_prefix.nil?
      ensure_space @content_for_tab_actions
    else
      ensure_space instance_variable_get("@content_for_#{actions_prefix}_tab_actions")
    end
  end

  def main_tab(name, options = {})
    path = options.has_key?(:path) ? options[:path] : send("#{name.underscore}_path")
    drop_down_list = eval("drop_down_for_#{options[:drop_down]}") if options[:drop_down].present?
    drop_down_menu = content_tag(:div, "#{drop_down_list}", {class: "drop_down #{options[:drop_down]}"}, false)
    css_class = options[:right] ? 'right ' : ''
    css_class = css_class+'current' if main_tab_current? name, options
    content_tag(:li, link_to( truncate(name, length: 40), path ) +
                     (options[:drop_down].present? ? drop_down_menu : ''),
                     {class: css_class},
                     false)
  end

  def drop_down_for_plans
    render(
        :partial => "plans/top_tabs",
        :locals => {:only_ul => true, :selected => "plans", :ul_class => "drop_down plans"}
    )
  end

  def drop_down_for_environments
    render(
        :partial => "account/environment_tabs",
        :locals => {:only_ul => true, :selected => "environments", :ul_class => "drop_down environments"}
    )
  end

  def drop_down_for_users
    render(
        :partial => "users/tabs",
        :locals => {:only_ul => true, :selected => "users", :ul_class => "drop_down users"}
    )
  end

  def drop_down_for_reports
    render(
        :partial => "reports/tabs",
        :locals => {:only_ul => true, :selected => "reports", :ul_class => "drop_down reports"}
    )
  end

  def drop_down_for_settings
    render(
        :partial => "account/tabs",
        :locals => {:only_ul => true, :selected => "settings", :ul_class => "drop_down settings"}
    )
  end

  def drop_down_for_requests
    li = ''
    li += content_tag(:li, link_to('Calendar', my_all_calendar_path)) if can? :view_calendar, Request.new
    li += content_tag(:li, link_to('Currently Running Steps',
                           currently_running_steps_path(params_for_currently_running_steps))) if can? :view_currently_running_steps, Request.new
    "<ul>#{li}</ul>"
  end

  def main_tab_current?(name, options)
    return options[:if] if options.has_key? :if
    params[:controller] == options.get(:controller, name.underscore) && options.get(:and, true) || options.get(:or, false)
  end

  alias :current_link? :main_tab_current?

  def sub_tab(name_or_model, options={})
    if ActiveRecord::Base === name_or_model
      sub_tab_with_model(name_or_model, options)
    else
      sub_tab_with_name(name_or_model, options)
    end
  end

  def next_level_sub_tab(name, options={})
    level_path = options[:path] || ''
    sub_content = render(
        :partial => "account/tabs",
        :locals => {:only_ul => true, :selected => "settings", :ul_class => "drop_down settings"}
    )
    content_tag(:li,
                link_to(content_tag(:div, h(truncate(name, :length => 40)), {:class => "nextLevelSubMenu"}, false), level_path) + sub_content, {}, false
    )
  end

  def sub_tab_with_model(model, options)
    Rails.logger.info "SubTab: #{@selected_sub_tab.inspect}, Model: #{model.inspect}, url: #{url_for(model)}\nOptions #{options.inspect}"
    options[:selected] = true #(model == @selected_sub_tab)
    Rails.logger.info "SubTab2"
    options[:path] ||= url_for(model)
    Rails.logger.info "SubTab3"
    name = model.name.pluralize
    sub_tab_html(name, options)
  end

  def sub_tab_with_name(name, options)
    options[:selected] = @selected_sub_tab == (options[:tab].nil? ? name.underscore : options[:tab])
    options[:path] ||= send("#{name.gsub(/\s+/, '_').underscore}_path")
    sub_tab_html(name, options)
  end

  def sub_tab_html(name, options)
    css_class= options[:class].nil? ? '' : options[:class]
    css_class=options[:selected] ? 'selected '+ css_class : css_class
    content_tag(:li,
                link_to(h(truncate(name, :length => 40)), options[:path]), :class => css_class)
  end

  def plan_sub_tabs(name, path, drop_down, tab=nil)
    selected = @selected_sub_tab == (tab.nil? ? name.underscore : tab)
    path ||= send("#{name.gsub(/\s+/, '_').underscore}_path")
    plan_sub_tab_html(name, path, selected, tab, drop_down)
  end

  def plan_sub_tab_html(name, path, selected, template_type, drop_down)
    content_tag(:li, link_to(h(truncate(name, length: 40)), path),
                class: selected ? 'selected' : '')

  end

  def plugin_tabs
    result = ''
    if defined?(PLUGINS_REGISTERED)
      PLUGINS_REGISTERED.reject { |k, _| k.start_with?('__') }.each do |_, tab_info|
        pair = tab_info.split('|')
        if pair.size == 2
          result = sub_tab(pair[0], path: "#{ContextRoot::context_root}#{pair[1]}")
        end
      end
    end
    result
  end

  def page_settings(settings = {})
    @page_title = settings[:title] || nil
    @page_heading = settings[:heading] || nil
    @page_content_class = settings[:content_class] || nil
    @full_screen = settings[:full_screen] || false
    @store_url = settings.has_key?(:store_url) ? settings[:store_url] : true
    @custom_heading = settings[:custom_heading] || nil
  end

  def flash_div(*keys)
    return '' if keys.nil? or keys.empty?

    flash_info = keys.collect { |key|
      content_tag(:div, content_tag(:span, flash[key], ''), {:id => "flash_#{key}"}, false) if flash[key]
    }.join

    content_tag(:div, flash_info.html_safe, {class: 'flash_messages'}, false)
  end

  def class_for_component_color(model, start_number = 0)
    return 'component_color_4' unless model.should_execute
    return 'component_color_11' if model.component_id.blank?

    @component_color_counter ||= start_number.to_i
    @component_color_associations ||= {}

    component_color_suffix = @component_color_counter % NUMBER_OF_COMPONENT_COLORS
    component_color_suffix = 1 if component_color_suffix <= 0

    unless @component_color_associations.keys.include? model.component_id || model.name
      component_color_suffix +=1 if component_color_suffix == 4 or component_color_suffix == 11
      @component_color_counter += 3
      @component_color_associations.merge!({model.component_id || model.name => "component_color_#{component_color_suffix}"})
    end
    @component_color_associations[model.component_id || model.name]
  end

  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end

  def name_of(model)
    model && model.name || ''
  end

  def ensure_space(str = nil)
    ensure_string(str, "&nbsp;").html_safe
  end

  def ensure_string(*ensured_strings)
    ensured_strings.find { |s| !s.blank? }.to_s
  end

  def note_span(string)
    raw("<span class=\"note\">#{string}</span>")
  end

  def name_list_sentence(list, truncate_to = nil)
    sentence = h list.map { |obj| name_of(obj) }.uniq.to_sentence
    sentence = truncate sentence, :length => truncate_to if truncate_to

    sentence
  end

  def current_deployed_version
    File.read(Rails.root + '/VERSION') + "<br />" + GITHEAD_COMMIT
    # File.read(RAILS_ROOT + '/VERSION') + "<br />" + github_commit_url
  end

  def application_name
    app = "smart_release"
    app.gsub("_", "|")
  end

  def application_name_for_view
    if application_name == "smart|release"
      result = APPLICATION_NAME
    else
      split_name = application_name.split('|')
      result = ""
      split_name.each_with_index do |portion, idx|
        result += (idx == 0 ? "<b>#{portion}</b>" : "|#{portion}")
      end
    end
    result
  end

  def navigation_tab(title, url, is_selected)
    content_tag :li, link_to(title, url), :class => (is_selected ? 'selected' : '')
  end

  def default_format_date(date)
    date.blank? ? nil : date.strftime(GlobalSettings[:default_date_format]).split(' ')[0]
  end

  def load_swfobject_js
    return if controller.controller_name == 'chats'
    if @display_report
      static_javascript_include_tag('amcharts/swfobject')
    else
      static_javascript_include_tag('swfobject')
    end
  end

  def include_additional_javascripts
    cur_controller = params[:controller]
    case cur_controller
      when "requests", "plans", "tickets"
        static_javascript_include_tag 'requests', 'shared_resource_automation'
      when "activities"
        static_javascript_include_tag 'activities', 'unsaved_changes_warning', 'validate'
      when "resources"
        static_javascript_include_tag 'resources'
      when "properties", "apps"
        static_javascript_include_tag 'drag_and_drop/draggable_object', 'drag_and_drop/component_drop_zone', 'apps'
      when "environment", "account"
        static_javascript_include_tag 'parameter_mappings', 'unsaved_changes_warning'
      else
    end
  end

  def static_javascript_include_tag(*sources)
    content = []
    sources.each do |source|
      # clean out any js extensions
      source = source.gsub('.js', '')
      # check if it is a relative or absolute link
      if source[0] != '/'
        content << "<script src=\"#{ContextRoot::context_root}/assets/#{source}.js\"></script>"
      else
        content << "<script src=\"#{ContextRoot::context_root}#{source}.js\"></script>"
      end
    end
    raw content.join("\n    ")
  end

  def absolute_url
    request.port ? request.host_with_port : request.host
  end

  def stylesheet_link_tag(*sources)
    ActionController::Base.asset_host = absolute_url
    super
  end

  def label_as_per_use_case
    'Project'
  end

  def activity_or_project?(transform ='singularize')
    label_as_per_use_case.send(transform)
  end

  def activity_or_project_image?
    if activity_or_project? == 'Activity'
      image_tag('btn-create-activity.png', :alt => 'Create Activity')
    else
      image_tag('btn-create-project.png', :alt => 'Create Project')
    end
  end

  def is_web(descriptions)
    return if descriptions.blank?

    content = []
    descriptions.split.each do |text|
      text = text.gsub('http://', '') if text[0..6] == 'http://'
      text = text.gsub('https://', '') if text[0..7] == 'https://'

      #        /^((http|https):\/\/)*[a-z0-9_-]{1,}\.*[a-z0-9_-]{1,}\.[a-z]{2,4}\/*$/i - # Old Regex used

      if text =~ URL_REGEXP
        text = "<a href='http://#{text}/' style='color:#0869D6' target='_blank'>#{text}</a>"
      end

      content << text
    end
    content.join(' ')
  end

  def ordinalize(number)
    if (11..13).include?(number.to_i % 100)
      "#{number}th"
    else
      case number.to_i % 10
        when 1;
          "#{number}st"
        when 2;
          "#{number}nd"
        when 3;
          "#{number}rd"
        else
          "#{number}th"
      end
    end
  end

  def mask_value(val)
    '&lt;private&gt;'
  end

  def to_sentence(collection)
    collection.to_sentence
  end

  def environment_link(environment)
    "<a href ='environment/environments/#{environment.id}/edit'>#{environment.try(:name)}</a>"
  end

  def index_title(title)
    "<strong>#{h(title)}</strong>".html_safe
  end

  def server_link(server)
    "<a href = 'environment/servers/#{server.id}/edit'>#{server.name}</a>"
  end

  def paginate_range(model_name, in_collection, in_tot_count)
    endnumber = in_collection.offset + in_collection.per_page > in_tot_count ? in_tot_count : in_collection.offset + in_collection.per_page
    incrementer = 1
    if in_tot_count == 0
      "Found no matching plans."
    else
      "Displaying #{in_collection.offset + incrementer}-#{endnumber} of #{pluralize(in_tot_count, model_name.downcase)}."
    end
  end

  def complete_image_tag(path, options = {})
    image_tag(path, options)
  end

  def default_logo
    logo = GlobalSettings[:default_logo]
    image_tag(logo && File.exist?("#{Rails.root}/public/images/#{logo}") ? logo : "bmc_logo.jpg")
  end

  def pagination_servers_search_letter(model_name, search_param)
    model_name.name_like("#{search_param}%").order('name asc').group_by {
        |group| group.send(:name)[0].chr.upcase }.keys
  end

  def search_box(path=nil)
    render :partial => "shared/search_box", :locals => {:path => path || params[:controller]}
  end

  def generate_link_to_or_not(name, url, can_manage)
    if can_manage
      link_to name, url
    else
      name
    end
  end

  def boolean_to_label(value = false)
    value ? 'Yes' : 'No'
  end

  def context_root
    ContextRoot::context_root
  end

  def get_version_from_file
    get_full_version.gsub(/\([Bb]\d+\)/, '')
  end

  def get_version_and_build_from_file
    get_full_version.gsub(/\\n/, '')
  end

  # generic helper to add nested child fields as per
  # http://railscasts.com/episodes/196-nested-model-form-revised?view=asciicast
  def link_to_add_fields(name, form, association, view_folder = '', owner = nil, partial = false, is_managable = nil)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render(File.join(view_folder, (partial || association.to_s.singularize) + "_fields"), builder: builder, owner: owner, is_managable: is_managable)
    end
    link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", " ")})
  end

  def eval_script(script)
    eval(script)
  end

  def execute_automation_internal(step, external_script, argument_hash, parent_id = "nil", offset = 0, per_page = 0)
    # get the expected Step params for automation by using the passed step
    script_params = external_script.queue_run!(step, "false", execute_in_background=false)

    params_to_be_appended = Hash[script_params]

    # write those to the input file
    arg_file_name = script_params["SS_input_file"]
    input_file = FileInUTF.open("#{arg_file_name}", "w")

    # load up the params to be appended with form variables
    # CHKME: This logic is copied from the method below, but the hash in question
    # will be identical to argument hash, so what are we doing here and why are
    # we modifying the params array -- maybe the helper accesses it directly?
    argument_hash.each do |key, value|
      params_to_be_appended[key] = value
      params[key] = value
    end

    # finish up the combined input file
    input_content = Hash[params_to_be_appended.sort].to_yaml
    input_file.write(input_content)
    input_file.flush
    input_file.close

    # pull the file back in from the file system
    automation_script_header = File.open("#{script_params["SS_script_file"]}").read
    # eval the script in memo
    # CHKME: protection against out of memory, time outs, and unauthorized object access.
    if parent_id.blank?
      parent_id = "nil"
    else
      parent_id = "\"#{parent_id}\""
    end
    external_script_output = eval_script("#{automation_script_header};execute(script_params, #{parent_id}, #{offset}, #{per_page});")
  end

  def convert_seconds_to_hhmm(total_seconds)
    return "--:--" if total_seconds.nil?
    completed_hours = (total_seconds / 3600).round.to_s.rjust(2, '0')
    completed_minutes = ((total_seconds % 3600) / 60).round.to_s.rjust(2, '0')
    "#{completed_hours}:#{completed_minutes}"
  end

  def truncate_middle(str, options={})
    if str
      max = options[:max] || 40
      delimiter = options[:delimiter] || "..."
      position = options[:position] || 0.8
      return str if str.size <= max
      remainder = max - delimiter.size
      offset_left = remainder * position
      offset_right = remainder * (1 - position)
      (str[0, offset_left + (remainder.odd? ? 1 : 0)].to_s + delimiter + str[-offset_right, offset_right].to_s)[0, max].to_s
    end
  end

  def state_indicator_row(aasm_obj)
    info = aasm_obj.state_info
    type = aasm_obj.class.to_s.underscore.pluralize.gsub('/','_')
    info["next_state_path"] = send("update_state_#{type}_path", aasm_obj, "update_object_state", info["next_state_transition"]) if info.has_key?("next_state_transition")
    info["previous_state_path"] = send("update_state_#{type}_path", aasm_obj, "update_object_state", info["previous_state_transition"]) if info.has_key?("previous_state_transition")
    html = ''
    info["states"].keys.each_with_index do |key,idx|
      val = info["states"][key]
      display_key = key.to_s.humanize
      if key.to_s == 'archived_state'
        display_key = 'Archived'
      end
      if key.to_s == aasm_obj.aasm_state && aasm_obj.can_change_aasm_state?
        first = (idx == 0)
        last = (idx == (info["states"].size - 1))
        html += state_link(info, 'previous', index_path(type, aasm_obj)) if !first && can_update_state?(aasm_obj)
        html += content_tag(:li, display_key, class: "active#{ last ? ' last' : ''}", title: val)
        html += state_link(info, 'next') if !last && can_update_state?(aasm_obj)
      else
        html += content_tag(:li, display_key, class: "inactive#{ last ? ' last' : ''}", title: val)
      end
    end
    content_tag(:ul, html.html_safe)
  end

  def state_list_row(aasm_obj)
    info = aasm_obj.state_info
    type = aasm_obj.class.to_s.underscore.pluralize.gsub('/','_')
    info['next_state_path'] = self.send("update_state_#{type}_path", aasm_obj, 'update_object_state_list', info['next_state_transition']) if info.has_key?('next_state_transition')
    info['previous_state_path'] = self.send("update_state_#{type}_path", aasm_obj, 'update_object_state_list', info['previous_state_transition']) if info.has_key?('previous_state_transition')
    html = ''
    info['states'].keys.each_with_index do |key,idx|
      if key.to_s == aasm_obj.aasm_state && aasm_obj.can_change_aasm_state?
        first = (idx == 0)
        last = (idx == (info['states'].size - 1))
        unless first
          html += content_tag(:li, '|')
          html += state_list_link(info, 'previous', aasm_obj)
        end
        unless last
          html += content_tag(:li, '|')
          html += state_list_link(info, 'next', aasm_obj)
        end
      end
    end
    content_tag(:ul, html.html_safe)
  end

def creation_string(passed_obj)
  by = create_time = "-unknown-"
  create_time = passed_obj.updated_at.try(:default_format_date_time) if passed_obj.respond_to?(:created_at)
  if passed_obj.respond_to?(:created_by) && !passed_obj.created_by.nil?
    user = User.find_by_id(passed_obj.created_by)
    by = user.first_name + " " + user.last_name
  end
  "Created: #{create_time} by #{by}"
end
  def help_question_mark_with_text(html_text)
    content_tag :div, class: 'help-wrapper' do
      result = []

      result << content_tag(:sup, class: 'help') do
        link_to '?', '#', tabindex: '-1'
      end
      result << content_tag(:div, class: 'help_box') do
        content_tag(:p) { html_text.html_safe }
      end

      result.join.html_safe
    end
  end

  def get_custom_head_style(record, place)
    return nil if record.errors[:name].empty?
    case place
      when :form
        'visible'
      when :show_span
        "style='display:none;'"
      when :link
        'display:none;'
      else
        nil
    end
  end

  def ajax_error_message_body(options = {})
    errors = Array(options.fetch(:errors))
    title  = options.fetch(:title) { I18n.t(:'activerecord.notices.prohibited_from_being_saved', number: errors.count) }

    content_tag(:div, id: 'errorExplanation', class: 'errorExplanation') do
      [
          content_tag(:h2, class: 'err_h2') { title },
          content_tag(:ul) { errors.map { |error| content_tag(:li) { error } }.join.html_safe }
      ].join.html_safe
    end
  end

  def password_field_tag(name = "password", value = nil, options = {})
    value = GibberishHelper.encrypt_value(value)
    options[:autocomplete] = "off"

    super
  end

  def password_field(object_name, method, options = {})
    if options.has_key? :value
      options[:value] = GibberishHelper.encrypt_value(options[:value])
    end
    options[:autocomplete] = "off"

    super
  end

  private

  def state_link(info, direction, list_path = '')
    state_link_vars(info, direction)
    a_tag = link_to(@link, '#', onclick: onclick="updateStateTransition(\"#{@path}\",\"#{@state}\",\"#{list_path}\");return false;", class: @transition_class)
    content_tag(:li, a_tag, class: 'state_transition', title: @title_text)
  end

  def state_list_link(info, direction, aasm_object)
    state_link_vars(info, direction)
    @link += @state if direction == 'previous'
    @link = @state + @link if direction == 'next'
    current_state = aasm_object.aasm_state.humanize if aasm_object.is_a?(RequestTemplate)
    a_tag = link_to(@link, '#',
                    onclick: onclick="updateStateColumnTransition(\"#{@path}\",\"#{aasm_object.id}\",\"#{@state}\",\"#{current_state}\");return false;",
                    class: @transition_class)
    content_tag(:li, a_tag, class: 'state_transition', title: @title_text)
  end

  def state_link_vars(info, direction)
    @path = info["#{direction}_state_path"]
    @title_text = info["#{direction}_state_transition"].humanize
    @state = info["#{direction}_state"].humanize
    if direction == 'previous'
      @link = '<<'
      @transition_class = 'state_transition_left'
    end
    if direction == 'next'
      @link = '>>'
      @transition_class = 'state_transition_right'
    end
  end

  def index_path(type, aasm_obj)
    if aasm_obj.can_view_draft?
      ''
    else
      type == 'deployment_window_series' ? send("#{type}_index_path") : send("#{type}_path")
    end
  end

  def get_full_version
    file = File.new("#{Rails.root}/VERSION", 'r')
    while line=file.gets
      next if line.start_with?('#')
      return line.split('=')[1].strip if line.include?('$VERSION')
    end
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

end

################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module StepsHelper

  def treeview_element_render(params = nil)
    content_tag(:div,'&nbsp;'.html_safe, :id => "tree_renderer").concat(
    javascript_tag '
      $(function(){
        $("#tree_renderer").dynatree({
            checkbox: true,
            selectMode: 3,
            initAjax: {
              type: "GET",
              url: "/environment/scripts/get_tree_elements.json",
              data: {mode: "drill", topLevel:true }
            },
            onLazyRead: function(node){
               node.appendAjax({
               type: "GET",
               url: "/environment/scripts/get_tree_elements.json",
               data: {mode: "drill",key: node.data.key}
              });
            }
        });
    });'
   )
  end

  def template_item_command_value(step, template_item, property_type)
    if step.nil? or step.package_template_id.nil?
      template_item["commands"][property_type]
    else
      return unless step[:package_template_properties][template_item.id.to_s]
      step[:package_template_properties][template_item.id.to_s][property_type]
    end
  end

  def template_item_property_value(step, template_item, pv)
    if step.nil? or step.package_template_id.nil?
      template_item["properties"][pv.property.name]
    else
      return unless step[:package_template_properties][template_item.id.to_s]
      step[:package_template_properties][template_item.id.to_s][pv.try(:name)]
    end
  end

  def hour_minute_estimate(estimate)
    estimate.nil? ? "0:00" : "#{estimate / 60}:#{(estimate % 60).to_s.rjust(2, '0')}"
  end

  def user_owner_chosen_for(step)
    step.new_record? || step.owner_type == "User"
  end

  def procedure_attr_for_edit(step, attr)
    text = step.send(attr)
    text = "[edit]" if text.blank?

    h text
  end

  def script_argument_value_output_display(step, argument)
    step_arguments = step.script_argument_value(argument).is_a?(Array) ?
                     step.script_argument_value(argument).flatten.first : step.script_argument_value(argument)
    return step_arguments if argument.class.to_s == "BladelogicScriptArgument"
    return text_field_tag "argument[#{argument.id}][]", "Value Not Set", :id => dom_id(argument), :class => "step_script_argument", :disabled => true if step_arguments.blank?
    case argument.argument_type
    when "out-text"
      step_arguments
    when "out-email"
      mail_to(step_arguments, name = nil, html_options = {})
    when "out-url"
      link_to(step_arguments, step_arguments, :target => "_blank")
    when "out-file"
      key_phrase = "/automation_results"
      results_path = step_arguments.include?(key_phrase) ? step_arguments[step_arguments.index(key_phrase)+key_phrase.length..255] : ''
      link_to(step_arguments.split("/").try(:last), download_files_scripts_path(:path => results_path))
    when "out-date"
      begin
        default_format_date = GlobalSettings[:default_date_format].split(' ')
        step_arguments_date = step_arguments.to_date.strftime(default_format_date[0])
      rescue Exception => e
        step_arguments_date = "Invalid Date."
      end
      text_field_tag "argument[#{argument.id}]", step_arguments_date, :id => dom_id(argument), :class => "date", :disabled => true
    when "out-time"
      text_field_tag "argument[#{argument.id}]", step_arguments, :id => dom_id(argument), :class => "argument_in_time", :disabled => true
    when "out-list"
      # Accept an array as a part of pack_response response parameter
        select_tag("argument[#{argument.id}][]",
          options_for_select(eval(step_arguments.to_s)),
          :id => dom_id(argument), :class => "step_script_argument", :multiple => true, :disabled => true)
    when "out-table"
      # external_script = Script.find_by_unique_identifier(argument.external_resource) if argument.external_resource.present?
      # table_type_argument(argument,step_arguments, nil, step, external_script)
      table_type_argument_body(argument.id,step_arguments,nil,step)
    when "out-user-single"
      # Based on the id of the BRPM user returned by the pack response reponse parameter user will be selected
        select_tag("argument[#{argument.id}][]",
        options_for_select(User.active.all.map {|e| ["#{e.last_name}, #{e.first_name}", e.login]}, step_arguments),
         :id => dom_id(argument), :class => "step_script_argument", :disabled => true)
    when "out-user-multi"
      # Based on the id of the BRPM user returned by the pack response reponse parameter multiple users names will be selected
      select_tag("argument[#{argument.id}]",
        options_for_select(User.active.all.map {|e| ["#{e.last_name}, #{e.first_name}", e.login]}, eval([step_arguments].flatten.first.to_s)),
        :multiple => true, :id=> dom_id(argument), :class => "step_script_argument", :disabled => true)
    when "out-server-single"
      select_tag("argument[#{argument.id}][]",
        options_for_select(Server.find(EnvironmentServer.all.map(&:server_id).uniq).map {|s| [s.name] }, [step_arguments].flatten),
        :id => dom_id(argument), :class => "step_script_argument", :disabled => true)
    when "out-server-multi"
      select_tag("argument[#{argument.id}]",
        options_for_select(Server.find(EnvironmentServer.all.map(&:server_id).uniq).map {|s| [s.name] }, eval([step_arguments].flatten.first.to_s)),
        :multiple => true, :id => dom_id(argument), :class => "step_script_argument", :disabled => true)
    when "out-external-single"
      select_tag("argument[#{argument.id}][]",
        options_for_select(step_arguments.html_safe),
        :id => dom_id(argument), :class => "step_script_argument", :disabled => true)
    when "out-external-multi"
      select_tag("argument[#{argument.id}][]",
        options_for_select(step_arguments.html_safe),
        :id => dom_id(argument), :class => "step_script_argument", :multiple => true, :disabled => true)
    else
      step_arguments
    end

  end

  def script_argument_value_input_display(step, argument, installed_component, value = nil, execute_resource_automation = false)
    step ||= Step.new
    input_div = '<div >'
    case argument.argument_type
    when "in-text"
      input_div << script_argument_value_input_tag(step, argument, installed_component, value)
    when "in-list-single", "in-list-multi"
      if argument.list_pairs.present?
        input_div << script_argument_value_in_list_tag(step, argument, installed_component, value)
      end
    when "in-user-single-select", "in-user-multi-select"
      input_div << script_argument_value_in_user_tag(step, argument, installed_component, value)
    when "in-server-single-select", "in-server-multi-select"
      input_div << script_argument_value_in_server_tag(step, argument, installed_component, value)
    when "in-date"
      input_div << script_argument_value_in_date_tag(step, argument, installed_component, value)
    when "in-time", "in-datetime"
      input_div << script_argument_value_in_time_tag(step, argument, installed_component, value)
    when "in-file"
      input_div << script_argument_value_in_file_tag(step, argument, installed_component, value)
    when "in-external-single-select"
      external_script = Script.find_by_unique_identifier(argument.external_resource) if argument.external_resource.present?
      if external_script.present? && ( external_script.render_as == "Table" || external_script.render_as == "Tree" )
        input_div << render_table_or_tree_view(step, argument, installed_component, value, external_script)
      else
        if execute_resource_automation && external_script.present? && external_script.arguments.blank?#&& argument.external_resource.present?
          input_div << script_argument_value_single_select_tag(step, argument, installed_component, value)
        else
          if argument.external_resource.present?
            value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
            value ||= script_argument_value_input_tag_value(step, argument, installed_component)
            # external_script = Script.find_by_unique_identifier(argument.external_resource)
            if external_script.present? && external_script.arguments.present?
              dependent_argument_array = []
              current_script_external_resource = argument.script.arguments.map(&:external_resource)
              current_script_external_resource.each do |external_resource|
                external_script_new = Script.find_by_unique_identifier(external_resource)
                dependent_argument_array << external_script_new.arguments.map(&:argument)
              end

            value = value.blank? ? "null" : value
            external_script_argument_names = external_script.arguments.map(&:argument)
            current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
            input_div << select_tag("argument[#{argument.id}][]", "",
              :id => dom_id(argument), :class => "step_script_argument",
              :depends_on => current_script_arguments.map(&:id).join(","),
              :arg_val => value, :onchange => "executeResourceAutomation($(this), null);" )
           end
          end
        end
      end
    when "in-external-multi-select"
      external_script = Script.find_by_unique_identifier(argument.external_resource) if argument.external_resource.present?
      if external_script.render_as == "Table" || external_script.render_as == "Tree"
        input_div << render_table_or_tree_view(step, argument, installed_component, value, external_script)
      else
        if execute_resource_automation && external_script.arguments.blank?#&& argument.external_resource.present?
          input_div << script_argument_value_multi_select_tag(step, argument, installed_component, value)
        else
          if argument.external_resource.present?
            value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
            value ||= script_argument_value_input_tag_value(step, argument, installed_component)
            # external_script = Script.find_by_unique_identifier(argument.external_resource)
            unless external_script.arguments.blank?
              dependent_argument_array = []
              current_script_external_resource = argument.script.arguments.map(&:external_resource)
              current_script_external_resource.each do |external_resource|
                external_script_new = Script.find_by_unique_identifier(external_resource)
                dependent_argument_array << external_script_new.arguments.map(&:argument)
              end

            value = value.blank? ? "null" : value
            external_script_argument_names = external_script.arguments.map(&:argument)
            current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
            input_div << select_tag("argument[#{argument.id}]", "",
              :id => dom_id(argument), :class => "step_script_argument",
              :depends_on => current_script_arguments.map(&:id).join(","), :multiple => true,
              :arg_val => value, :onchange => "executeResourceAutomation($(this), null);" )
           end
          end
        end
      end
    else
      input_div << script_argument_value_input_tag(step, argument, installed_component, value)
    end
    if argument.argument_type == "in-text" && should_include_select_tag?(argument, installed_component) && argument.script.automation_category != "Hudson/Jenkins" #&& !argument.is_a?(ScriptArgument)
      dependent_argument_array = []
      current_script_external_resource = argument.script.arguments.map(&:external_resource)
      current_script_external_resource.each do |external_resource|
        external_script_new = Script.find_by_unique_identifier(external_resource)
        dependent_argument_array << external_script_new.arguments.map(&:argument)
      end
      input_div = '<div >'
      values = argument.values_from_properties(installed_component)
      value = value.blank? ? "null" : value
      input_div << select_tag("argument[#{argument.id}][]", options_for_select(values, [value].flatten),
                              include_blank: 'Select',
                              disabled: cannot?(:edit_step, step.request),
                              class: 'step_script_argument',
                              id: dom_id(argument),
                              parent_argument: dependent_argument_array.flatten.include?(argument.argument),
                              arg_val: "#{value}",
                              onchange: "executeResourceAutomation($(this), $(this).attr('target_arguments_to_load').split(','));")
    end
    input_div << "</div>"
    input_div.html_safe
  end

  def script_argument_value_select_tag(step, argument, installed_component, value = nil)
    disable_field = cannot? :edit, step.request
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    select_tag("argument[#{argument.id}][]",
      options_for_select(argument.choices, value),
      :id => dom_id(argument), :class => "step_script_argument", :include_blank => "Select", :disabled => disable_field)
  end

  def render_table_or_tree_view(step, argument, installed_component, value = nil, external_script = nil)
    return unless external_script
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    if external_script.arguments.blank?
      begin
        script_params = external_script.queue_run!(step || Step.new, "false", execute_in_background=false)
        automation_script_header = File.open("#{script_params["SS_script_file"]}").read
        # Metod signature for execute method
        # execute(parent_id, offset, max_records)
        external_script_output = eval_script("#{automation_script_header};execute(script_params,nil,0,0);")
        # external_script_output.slice!(0) # This will remove first tupple from the array of hashes
      rescue Exception => err
        log_automation_errors(step, err, external_script_output)
      end

      if external_script.render_as == "Table"
        table_type_argument(argument,external_script_output,value,step, external_script,installed_component )
        # mapped_table_type_argument(argument.id, external_script_output)
      elsif external_script.render_as == "Tree"
        tree_type_argument(argument,external_script_output,value,step, external_script)
      end

    else
      external_script_argument_names = external_script.arguments.map(&:argument)
      current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
      text_field_tag "argument[#{argument.id}][]", value, :id => dom_id(argument),
      :class => "step_script_argument", :depends_on => current_script_arguments.map(&:id).join(","), :disabled => 'disabled'
    end

  end
  # render the table body for each page
  # Example:-  aofa = {:perPage => 5, :totalItems => 100, :data => [[h1, h2, h3], [r1, r2, r3], ..]}
  def table_type_argument_body(argument_id, hashData, val = nil, step = nil, page = 0)
    argument = ScriptArgument.find_by_id(argument_id)
    hashData = JSON.parse(hashData).try(:symbolize_keys) unless hashData.is_a?(Hash)
    per_page = hashData[:perPage].to_i
    offset = page * per_page
    total_records = hashData[:totalItems]
    aofa = hashData[:data]
    #      aofa.delete_at(0)
    thead = content_tag :thead do
       headers = aofa[0]
       headers.delete_at(0)
       content_tag :tr do
         headers.collect {|column|  concat content_tag(:th,truncate(column, :length => 20),:title => column, :class => 'tdc_col')}.push( concat content_tag(:th,'&nbsp;'.html_safe,:class => 'sel_action_column')).join().html_safe
      end
    end

    aofa.delete_at(0)
    tbody = content_tag :tbody do
      aofa[offset, per_page].collect { |elem|
        item_id = elem[0]
        elem.delete_at(0)
        content_tag :tr do
          elem.collect { |column|
                concat content_tag(:td, column, title: column, class: 'tdc_col truncated')
            }.push(concat content_tag(:td,check_box_tag("argument[#{argument_id}][]", item_id, [val].flatten.include?(item_id.to_s),:id => "selectArgumentItem_#{argument_id}_#{item_id}", :argument_name => argument.try(:argument)),:class => 'sel_action_column')).to_s.html_safe
        end
      }.join().html_safe
    end

    (content_tag :table, thead.concat(tbody).html_safe,:class => "formatted_table",:id=> "table_arg_#{argument_id}", :style => "table-layout: fixed !important;width: 100%; !important", :argument_value => val ? val.to_json : '',:per_page => "#{per_page}")
  end
  # helper accepts array of array as input argument and renders tabular layout
  # TODO: adding checkboxes for selection, might be after further discussion
  # Example:-  aofa = {:perPage => 5, :totalItems => 100, :data => [[h1, h2, h3], [r1, r2, r3], ..]}
  def table_type_argument(argument,hashData,val=nil,step=nil, external_script=nil, selected_argument_hash=nil, installed_component = nil, use_selected_values = true)
    if use_selected_values
      val ||= script_argument_value_input_tag_value(step, argument, installed_component)
    else
      val = nil
    end
    external_script_argument_names = external_script.arguments.map(&:argument)
    current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
    per_page = hashData[:perPage]
    total_records = hashData[:totalItems]
    tbody = ''
    thead = ''
    existing_items = ''
    existing_items = [val].flatten.collect{|e_elem| hidden_field_tag("argument[#{argument.id}][]",e_elem, :id => "argument_#{argument.id}_#{e_elem}")}.join().html_safe if val

    (content_tag :div, (content_tag :table, thead.concat(tbody),:class => "formatted_table",:id=> "table_arg_#{argument.id}", :style => "table-layout: fixed !important;width: 100%; !important", :argument_value => val ? val.to_json : '',:per_page => "#{per_page}").concat(
                 content_tag(:div,'', :id=> "argument_table_pagination_#{argument.id}", :class =>"arg_table_pagination", :argument_name => argument.try(:argument), :style=> "margin-top:15px;")).concat(
                     javascript_tag "
                      $(function(){
                        var opt = {callback: tableArgumentPageSelectCallback,num_edge_entries: 2, num_display_entries:5, items_per_page:#{per_page}};
                        $('#argument_table_pagination_' + '#{argument.id}').pagination(#{total_records}, opt);
                      });
                    "), :id => "table_argument_with_pagination_container_#{argument.id}", :class => 'step_script_argument',
                        :depends_on => current_script_arguments.map(&:id).join(","),
                        :selected_arguments => selected_argument_hash.to_json, :style => "display:none;").concat(
          content_tag(:span,'',:id => "arg_in_data_list_for_table_#{argument.id}", :class => "#{argument.id}")).html_safe
  end

  # Mapped data version of the original table_type_argument function that has a smaller dependency on script arguments and
  # steps for its functioning.  Ideally these would be refactored to share a generic core, but time is short.
  # Example:-  aofa = {:perPage => 5, :totalItems => 100, :data => [[h1, h2, h3], [r1, r2, r3], ..]}
  # move this to tickets once all the refactoring is done
  def mapped_table_type_argument(argument_id, hashData)
      # the pagination code needs these from the hashData array returned by the service
      per_page = hashData[:perPage] || hashData[:data].length
      total_records = hashData[:totalItems] || per_page
      tbody = ''
      thead = ''
      existing_items = ''
      # prepare a look up of hidden inputs with the full object in json
      cached_data = []
      cached_data << "<span id='cached_row_data_#{argument_id}' class='#{argument_id}'>"
      hashData[:data].each do |row_data|
        # create a span and assign this to the data attribute with the unique key as the id
        cached_data << content_tag(:input, nil, :type => 'hidden', :value => row_data.to_json, :name => "cached_data[#{argument_id}][]", :id => "cached_data_#{argument_id}_#{row_data[0]}")
      end
      cached_data << "</span>"
      (content_tag :div,
                  (content_tag :table, thead.concat(tbody), :class => "formatted_table",
                                                            :id=> "table_arg_#{argument_id}",
                                                            :style => "table-layout: fixed !important;width: 100%; !important",
                                                            :per_page => "#{per_page}").concat(
                   content_tag(:div,'',  :id=> "argument_table_pagination_#{argument_id}",
                                            :class =>"arg_table_pagination",
                                            :style=> "margin-top:15px;")).concat(
                       javascript_tag "
                        $(function(){
                              var opt = {callback: tableArgumentPageSelectCallback,num_edge_entries: 2, num_display_entries:5, items_per_page:#{per_page}};
                              $('#argument_table_pagination_' + '#{argument_id}').pagination(#{total_records}, opt);

                          });
                      "), :id => "table_argument_with_pagination_container_#{argument_id}", :class => 'step_script_argument',
                          :style => "display:none;").concat(
                          content_tag(:span,'',:id => "arg_in_data_list_for_table_#{argument_id}", :class => "#{argument_id}")).concat(raw(cached_data.join(' '))).html_safe
  end

  def tree_type_argument(argument,aofa,val=nil, step=nil, external_script=nil, selected_argument_hash=nil)
    external_script_argument_names = external_script.arguments.map(&:argument)
    current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)

    # Code for generating tree Data structure
    content_tag(:div,'&nbsp;'.html_safe, :id => "tree_renderer_#{argument.id}", :selected_arguments => selected_argument_hash.try(:to_json), :class => "tree_renderer step_script_argument",:style=> "width:100%;",
      :argument_id => argument.id, :arg_val => val, :depends_on => current_script_arguments.map(&:id).join(",")).concat(
    javascript_tag "

      $(function(){

        $('#tree_renderer_'+ '#{argument.id}').dynatree({
            checkbox: true,
            selectMode: #{tree_node_selection_mode(argument.argument_type)},
            initAjax: {
              type: 'POST',
              url: '#{ContextRoot::context_root}/environment/scripts/get_tree_elements.json',
              data: {mode: 'drill', topLevel:true, argument_id:$('#tree_renderer_'+ '#{argument.id}').attr('argument_id'),
              source_argument_value:$('#tree_renderer_'+ '#{argument.id}').attr('selected_arguments') ,step_obj:$('#argument_grid').data('step_obj'),
              value:$('#tree_renderer_'+ '#{argument.id}').attr('arg_val')}
            },
            onLazyRead: function(node){
               node.appendAjax({
               type: 'POST',
               url: '#{ContextRoot::context_root}/environment/scripts/get_tree_elements.json',
               data: {mode: 'drill',key: node.data.key, argument_id:$('#tree_renderer_'+ '#{argument.id}').attr('argument_id'),
               source_argument_value: $('#tree_renderer_'+ '#{argument.id}').attr('selected_arguments'), step_obj:$('#argument_grid').data('step_obj'),
               value:$('#tree_renderer_'+ '#{argument.id}').attr('arg_val')}
              });
            }
        });
    });"
   )
  end


  def script_argument_value_single_select_tag(step, argument, installed_component, value = nil)
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    # Execute resource automation associated with argument
    if argument.external_resource.present? #&& !step.step_script_arguments.map(&:script_argument_id).include?(argument.id)
      begin
        external_script = Script.find_by_unique_identifier(argument.external_resource)
        script_params = external_script.queue_run!(step || Step.new , "false", execute_in_background=false)
        automation_script_header = File.open("#{script_params["SS_script_file"]}").read
        # Metod signature for execute method
        # execute(parent_id, offset, max_records)
        external_script_output = eval_script("#{automation_script_header};execute(script_params,nil,0,0);")
        # external_script_output.slice!(0) # This will remove first tupple from the array of hashes
      rescue Exception => err
        log_automation_errors(step, err, external_script_output)
      end
    end

    dependent_argument_array = []
    current_script_external_resource = argument.script.arguments.map(&:external_resource)
    current_script_external_resource.each do |external_resource|
      external_script_new = Script.find_by_unique_identifier(external_resource)
      dependent_argument_array << external_script_new.arguments.map(&:argument)
    end

    if external_script.arguments.present?
      external_script_argument_names = external_script.arguments.map(&:argument)
      current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
    end

    value = value.blank? ? "null" : value
    default_field = script_argument_value_input_tag(step, argument, installed_component, "N.A")
    if (external_script_output.nil? || !external_script_output.is_a?(Array))
      default_field
    else
      if current_script_arguments.present?
        select_tag("argument[#{argument.id}][]",
          options_for_select(external_script_output.try(:flatten_hashes), [value].flatten),
          :id => dom_id(argument), :class => "step_script_argument",
          :parent_argument => dependent_argument_array.flatten.include?(argument.argument), :arg_val => "#{value}" ,
          :depends_on => current_script_arguments.map(&:id).join(','), :onchange => "executeResourceAutomation($(this), null)")
      else
        select_tag("argument[#{argument.id}][]",
          options_for_select(external_script_output.try(:flatten_hashes), [value].flatten),
          :id => dom_id(argument), :class => "step_script_argument",
          :parent_argument => dependent_argument_array.flatten.include?(argument.argument), :arg_val => "#{value}" ,
          :onchange => "executeResourceAutomation($(this), null)")
      end
    end
  end

  def script_argument_value_multi_select_tag(step, argument, installed_component, value = nil)
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    # Execute resource automation associated with argument
    if argument.external_resource.present? #&& !step.step_script_arguments.map(&:script_argument_id).include?(argument.id)
      begin
        external_script = Script.find_by_unique_identifier(argument.external_resource)
        script_params = external_script.queue_run!(step || Step.new, "false", execute_in_background=false)
        automation_script_header = File.open("#{script_params["SS_script_file"]}").read
        # Metod signature for execute method
        # execute(parent_id, offset, max_records)
        external_script_output = eval_script("#{automation_script_header};execute(script_params,nil,0,0);")
        # external_script_output.slice!(0) # This will remove first tupple form the Array of hashes
      rescue Exception => err
        log_automation_errors(step, err, external_script_output)
      end
    end

    dependent_argument_array = []
    current_script_external_resource = argument.script.arguments.map(&:external_resource)
    current_script_external_resource.each do |external_resource|
      external_script_new = Script.find_by_unique_identifier(external_resource)
      dependent_argument_array << external_script_new.arguments.map(&:argument)
    end

    if external_script.arguments.present?
      external_script_argument_names = external_script.arguments.map(&:argument)
      current_script_arguments = argument.script.arguments.where(:argument => external_script_argument_names)
    end

    value = value.blank? ? "null" : value
    default_field = script_argument_value_input_tag(step, argument, installed_component, "N.A")
    if (external_script_output.nil? || !external_script_output.is_a?(Array))
      default_field
    else
      if current_script_arguments.present?
        select_tag("argument[#{argument.id}]",
          options_for_select(external_script_output.try(:flatten_hashes), [value].flatten),
          :id => dom_id(argument), :class => "step_script_argument", :multiple => true,
          :parent_argument => dependent_argument_array.flatten.include?(argument.argument), :arg_val => "#{value}" ,
          :depends_on => current_script_arguments.map(&:id).join(','), :onclick => "executeResourceAutomation($(this), null)")
      else
        select_tag("argument[#{argument.id}]",
          options_for_select(external_script_output.try(:flatten_hashes), [value].flatten),
          :id => dom_id(argument), :class => "step_script_argument", :multiple => true,
          :parent_argument => dependent_argument_array.flatten.include?(argument.argument), :arg_val => "#{value}" ,
          :onclick => "executeResourceAutomation($(this), null)")
      end
    end
  end

  def script_argument_value_in_list_tag(step, argument, installed_component, value = nil)
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    if argument.list_pairs.present?
      if argument.argument_type == "in-list-single"
        list_data = argument.list_pairs.scan(/[a-z0-9]+,([^|,]+)(?:\||$)/i)
        select_tag("argument[#{argument.id}][]",
          options_for_select(list_data.map(&:reverse), [value].flatten),
          :id => dom_id(argument), :class => "step_script_argument", :onchange => "executeResourceAutomation($(this), null);")
      elsif argument.argument_type == "in-list-multi"
        list_data = argument.list_pairs.scan(/[a-z0-9]+,([^|,]+)(?:\||$)/i)
        select_tag("argument[#{argument.id}]",
          options_for_select(list_data.map(&:reverse), [value].flatten),
          :multiple => true, :id => dom_id(argument), :class => "step_script_argument", :onchange => "executeResourceAutomation($(this), null);")
      end
    end
  end

  def script_argument_value_in_user_tag(step, argument, installed_component, value = nil)
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    if argument.argument_type == "in-user-single-select"
      select_tag("argument[#{argument.id}][]",
        options_for_select(User.active.all.map {|e| "#{e.last_name}, #{e.first_name}"}, [value].flatten),
        :id => dom_id(argument), :class => "step_script_argument", :include_blank => "Select")
    elsif argument.argument_type == "in-user-multi-select"
      select_tag("argument[#{argument.id}]",
        options_for_select(User.active.all.map {|e| "#{e.last_name}, #{e.first_name}"}, [value].flatten),
        :multiple => true, :id => dom_id(argument), :class => "step_script_argument")
    end
  end

  def script_argument_value_in_file_tag(step, argument, installed_component, value = nil)
    step_script_argument = StepScriptArgument.find_by_step_id_and_script_argument_id(step, argument)
    step_script_argument_obj = step_script_argument.blank? ? argument.step_script_arguments.new : step_script_argument
    f = instantiate_builder(step_script_argument_obj, step, {})
    render :partial => "uploads/add_argument_uploads_form", :locals => {:step => step, :f => f, :argument_id => argument.id}
  end

  def script_argument_value_in_server_tag(step, argument, installed_component, value = nil)
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    if argument.argument_type == "in-server-single-select"
      select_tag("argument[#{argument.id}][]",
        options_for_select(Server.find(EnvironmentServer.all.map(&:server_id).uniq).map {|s| [s.name, s.id] }, [value].flatten),
        :id => dom_id(argument), :class => "step_script_argument", :include_blank => "Select")
    elsif argument.argument_type == "in-server-multi-select"
      select_tag("argument[#{argument.id}]",
        options_for_select(Server.find(EnvironmentServer.all.map(&:server_id).uniq).map {|s| [s.name, s.id] }, [value].flatten),
        :multiple => true, :id => dom_id(argument), :class => "step_script_argument")
    end
  end

  def script_argument_value_in_date_tag(step, argument, installed_component, value = nil)
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    value = [value].flatten.first
    old_value = value
    begin
      default_format_date = GlobalSettings[:default_date_format].split(' ')
      if default_format_date.eql?(["%d/%m/%Y", "%I:%M", "%p"]) && value.to_s.include?('/')
        field_value_components = value.split('/')
        value = field_value_components[1]+'/'+field_value_components[0]+'/'+field_value_components[2]
      end
      value = value.to_date.strftime(default_format_date[0])
    rescue Exception => e
      value = old_value
    end
    text_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "date", :readonly => true
  end

  def script_argument_value_in_time_tag(step, argument, installed_component, value = nil)
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
    if argument.argument_type == "in-time"
      text_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "argument_in_time", :readonly => true
    elsif argument.argument_type == "in-datetime"
      value = [value].flatten.first
      old_value = value
      begin
        default_format_date = GlobalSettings[:default_date_format].split(' ')
        if default_format_date.eql?(["%d/%m/%Y", "%I:%M", "%p"]) && value.to_s.include?('/')
          field_value_components = value.split('/')
          value = field_value_components[1]+'/'+field_value_components[0]+'/'+field_value_components[2]
        end
        value = value.to_datetime.strftime("#{default_format_date[0]} %H:%M") rescue nil
        value = value.nil? ? old_value.to_datetime.strftime("#{default_format_date[0]} %H:%M") : value
      rescue Exception => e
        value = old_value
      end
      text_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "argument_in_datetime", :readonly => true
    else
      text_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "argument_in_datetime", :readonly => true
    end
  end

  def should_include_select_tag?(argument, installed_component)
    argument.values_from_properties(installed_component).size >= 2
  end

  def script_argument_value_input_tag(step, argument, installed_component, value = nil)
    disable_field = step ? disabled_step_editing?(step) : false
    value = value.is_a?(Array) ? ( value.first.empty? ? nil : value ) : value
    value ||= script_argument_value_input_tag_value(step, argument, installed_component)
      dependent_argument_array = []
      current_script_external_resource = argument.script.arguments.map(&:external_resource).try(:compact)
      current_script_external_resource.each do |external_resource|
        external_script_new = Script.find_by_unique_identifier(external_resource)
        if external_script_new.present? && external_script_new.arguments.present?
          dependent_argument_array << external_script_new.arguments.map(&:argument)
        end
      end
    if argument.is_private
      password_field_tag "argument[#{argument.id}][]", value, :id => dom_id(argument), :class => "step_script_argument", :disabled => disable_field, :parent_argument => dependent_argument_array.present? ? dependent_argument_array.flatten.include?(argument.argument) : false
    else
      text_field_tag "argument[#{argument.id}][]", value, :id => dom_id(argument), :class => "step_script_argument", :disabled => disable_field, :parent_argument => dependent_argument_array.present? ? dependent_argument_array.flatten.include?(argument.argument) : false
    end
  end

  def script_argument_value_input_tag_value(step, argument, installed_component, options = {})
    if step
      step_value = step.script_argument_property_value(argument, options)
      return step_value unless step_value.is_a?(Array) ? step_value.first.empty? : step_value.blank?
    end
    values_from_properties = argument.values_from_properties(installed_component)
    if ["in-external-multi-select", "in-user-multi-select", "in-server-multi-select"].include?(argument.argument_type)
      values_from_properties
    elsif ["in-external-single-select", "in-user-single-select", "in-server-single-select"].include?(argument.argument_type)
      values_from_properties.first
    else
      values_from_properties.first
    end
    # return values_from_properties.first if values_from_properties.size == 1
  end

  def orig_script_argument_value_input_tag_value(step, argument, installed_component)
    if step
      step_value = step.script_argument_value(argument.id)
      return step_value unless step_value.blank?
    end
    values_from_properties = argument.values_from_properties(installed_component)
    return values_from_properties.first if values_from_properties.size == 1
  end

  def step_category_available_for?(step, event)
    Category.unarchived.step.associated_event(event).any?
  end

  def step_error_package(step, available_packages=[])
    if step.package_is_not_in_list(available_packages)
      'invalid'
    else
      ''
    end
  end

  def step_error_class(step)
    if step.has_invalid_package?
      'invalid'
    end
  end

  def step_has_valid_package?(step)
    step.has_package? && !step.has_invalid_package?
  end

  def procedure_row_class(step)
    result = ["procedure"]
    result << "protected" if step.protected?
    result.join(" ")
  end

  def step_row_class(step, unfolded, invalid_component, request = nil, step_permissions = {})
    tr_class = step.archived_procedure? ? '' : 'step'
    step_editable = step_permissions.fetch(:step_editable) { step.editable_by?(current_user, request) }
    can_run_step = step_permissions.fetch(:can_run_step) { can?(:run_step, request) }

    if !request.nil? && step_editable
      tr_class << ' listable'
    else
      tr_class << ' '
    end
    tr_class << ' different_level_from_previous' if step.different_level_from_previous?
    tr_class << ' incomplete_step' unless step.complete?

    if step.parent_id
      tr_class << ' procedure_step'
      tr_class << " parent_#{step.parent_id}"

      if @last_proc_step
        last_step = (@last_proc_step == step)
      else
        last_step = step.last?
      end

      tr_class << (unfolded ? ' was_last' : ' last') if last_step
    end

    tr_class << ' unfolded' if unfolded
    tr_class << ' invalid' if invalid_component

    tr_class << ' protected' if step.protected?
    tr_class << ' protect_automation' if step.protect_automation?
    tr_class << ' step_off' unless step.should_execute?

    if (step.owned_by?(current_user) || step.auto?) && (request.present? && can_run_step)
      tr_class << ' has_access'
    else
      tr_class << ' no_access'
    end

    tr_class
  end

  def step_section_row_class(step, unfolded, invalid_component,is_last_step = nil)
    tr_class = 'container delete_with_parent'
    tr_class << ' procedure_step' if step.parent_id
    tr_class << ' invalid' if invalid_component
    tr_class << ' last' if unfolded && (is_last_step || step.last?)

    tr_class
  end

  def step_type_class(step)
    step.parent_id ? "procedure_step" : "step"
  end

  def completion_class(step)
    step.complete? || step.in_process? ? "completed_step" : ''
  end

  def abstract_request_step_path(request, step, extra_params = {})
    if step.parent_id
      request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      request_step_path(request, step.id, extra_params)
    end
  end

  def abstract_edit_request_step_path(request, step, extra_params = {})
    if step.parent_id
      edit_request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      edit_request_step_path(request, step.id, extra_params)
    end
  end

  def abstract_update_status_request_step_path(request, step, extra_params = {})
    if step.parent_id
      update_status_request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      update_status_request_step_path(request, step.id, extra_params)
    end
  end

  def abstract_add_category_request_step_path(request, step, extra_params = {})
    if step.parent_id
      add_category_request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      add_category_request_step_path(request, step.id, extra_params)
    end
  end

  def abstract_update_position_request_step_path(request, step, extra_params = {})
    if step.parent_id
      update_position_request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      update_position_request_step_path(request, step.id, extra_params)
    end
  end

  def abstract_toggle_execution_request_step_path(request, step, extra_params = {})
    if step.parent_id
      toggle_execution_request_step_path(request, step.parent_id, extra_params.merge(:step_id => step.id))
    else
      toggle_execution_request_step_path(request, step.id, extra_params)
    end
  end

  def step_form_header(step)
    if step.new_record?
      header = "New Step "
      if step.parent
        header << "#{step.parent.number}.#{step.parent.steps.count + 1} "
      else
        header = "New Step #{(step.request.position_of_last_step || 0) + 1} "
      end
    else
      header = "&nbsp;&nbsp; Edit Step "
      header << "#{step.number} "
    end

    header
  end

  def procedure_step_form_header(step, procedure)
    if step.new_record?
      header = "New Step #{(procedure.steps.count || 0) + 1} "
    else
      header = "&nbsp;&nbsp; Edit Step "
      header << "#{step.number} "
    end
    header
  end

  def step_reorder_title(step)
    title = 'Estimate: '
    title << (step.estimate ? hour_minute_estimate(step.estimate) : 'none')
    title << ', Complete by: '
    title << (step.complete_by ? step.complete_by.to_s(:simple_with_time) : 'N/A')
    title << ', Version: '
    title << (step.version_name.blank? ? 'none' : step.version_name)
    title << ', Servers: '
    title << (step.servers.empty? ? 'none' : name_list_sentence(step.servers))

    title
  end

  def refresh_steps_list(request)
    "$('#steps_container').html(\"#{escape_javascript(render(:partial => 'requests/steps', :locals => { :request => request, :update_steps => true }))}\");".html_safe
  end

  def procedure_edit_in_place(request, step, attribute)
    if can?(:edit_procedure, request) && step.editable_by?(current_user, request)
      render :partial => 'steps/step_rows/edit_procedure', :locals => { :step => step, :request => request, :attribute => attribute }
    else
      ensure_space h(step.send(attribute))
    end
  end

  def procedurein_place(request, user, step, attribute)
      ensure_space h(step.send(attribute))
  end

  def link_to_request_with_open_step(request, step, display_text=false)
    display_text ||= (step ? "#{step.number}" : '')
    link_to_if can?(:inspect, request), display_text, {:controller => :requests, :action => :show, :id => request.number, :unfolded_steps => step.id }
  end

  def step_attribute_value(step_attr)
    step_attr ? ensure_space(h(step_attr)) : raw("<span class=\"no_value\">unspecified</span>")
  end

  def version_change_message(installed_component_version)
    "Newest version of this installed component is #{installed_component_version}"
  end

  def results_hyperlink(cur_note)
    # From test link, this will be a string, from step a note object
    hyperlink_path = ""
    results = cur_note.is_a?(String) ? cur_note : cur_note.content
    if cur_note.is_a?(String) || cur_note.holder_type.nil?
      unless results.nil?
          lpos = results.index("[Script output written to:")
          unless lpos.nil?
            key_phrase = "automation_results/"
            ipos = results.index(key_phrase, lpos)
            unless ipos.nil?
              ipos2 = results.slice(ipos..(ipos + 400)).index("]\n")
              if ipos2.nil?
                hyperlink_path = "Couldn't locate output file link"
              else
                hyperlink_path = "/automation_results/#{results.slice((ipos+key_phrase.length)..(ipos + ipos2 - 1))}"
              end
            end
        end
      end
    else
      jr = cur_note.holder
      hyperlink_path = jr.results_hyperlink_path unless jr.nil?
    end
    result = hyperlink_path
    result = link_to("Automation run full results", "#{ContextRoot::context_root}#{hyperlink_path}", :onclick => "open_script_result_window(this.href);return false;") if hyperlink_path.include?("/automation_results/")
    result.html_safe
  end

  def common_owner_type_of(steps)
    owner_types = steps.values.flatten.map(&:owner_type).uniq
    if owner_types.length == 1
      @owner_type_of_selected_steps = owner_types.first
      true
    else
      false
    end

  end

  def common_attribute_id_of(steps,  type_id)
    @step.send(type_id) if steps.values.flatten.map(&(type_id.to_sym)).uniq.length == 1
  end

  def common_app_id_of(steps)
    @steps.first.request.apps.first.id rescue nil
    #@app_id_of_selected_steps = steps.values.flatten.map(&:app_id).uniq.length == 1 ? @step.app_id  : nil
  end

  def common_component_id_of(steps)
    @component_id_of_selected_steps = @step.component_id if steps.values.flatten.map(&:component_id).uniq.length == 1
  end

  # Returns option_for_select displaying installed components of common app of selected steps
  def ics_of_selected_steps(steps)
    @app_id_of_selected_steps = @step.request.apps.first.id rescue nil
    #@component_id_of_selected_steps = @step.request.environment.installed_components rescue []
    @app_id_of_selected_steps ? @step.request.common_components_installed_on_env_of_app(@app_id_of_selected_steps)  : []
  end

  def display_note(note)
    result = "<p class='note'>\n"
    result += "<span class='user_date'>#{note.user.name}, #{note.updated_at.default_format}: </span>\n<br>"
    #result += "<span class='note_text'>#{note.content.gsub("\n", "<br>")}</span>\n"
    result += "<pre class='text_wrap_break_line'>#{note_content(note)}</pre>\n<br>"
    result += "<span class='output_link'>#{results_hyperlink(note)}</span>\n</p>"  if note.object.auto?
    result.html_safe
  end

  def link_to_step_of_request(step, title, request)
    link_to title, edit_request_path(request) + "#step_#{step.id}_#{step.position}_heading", :target => "_blank"
  end

  def link_to_on_off_step(step, link_disabled = false)
    step_status = step.should_execute? ? "ON" : "OFF"
    link_disabled ||
        step.protected? ? step_status : link_to_function(step_status,
                                                         "change_step_status($(this))",
                                                         id: "#{dom_id(step)}_should_execute",
                                                         class: step_status)
   end

  # Bulk Update Views Helpers

  def bulk_update_page_title
    case @operation
      when "modify_task_phase"
        @instruction = "Change the task and/or phase for a number of steps at the same time"
        "Modify Step Task/Phase"
      when "modify_app_component"
        @instruction = "Change the component for a number of steps at the same time"
        "Modify Step Application and Component"
      when "modify_assignment"
        @instruction = "Change the user/group for a number of steps at the same time"
        "Modify Step Assignment"
      when "modify_should_execute"
        @instruction = 'Turn ON/OFF number of steps at the same time. '
        @instruction += 'Steps that are "off" will be skipped when request is started.'
        "Turn ON/OFF Steps"
    end
  end

  def count_of_steps_selected_for_bulk_edit
    %Q{<div id='versions_by_app_map'>
        <div class='fl'>Current</div>
        <div class='fr'>#{pluralize(@steps.count, 'step')} selected</div>
      </div>
    }.html_safe
  end

  def app_name_for_components(step)
    App.find(step.app_id).name if step.app_id.present? and step.app_id > 0
  end

  def find_step_from_hash(step_id)
    @step = @steps[step_id].first
  end

  def switch_class_hold_step(request)
    request.hold? ? "hold_column_width" : "state_column_width"
  end

  def server_is_selected?(cur_server, server_ids, server_aspect_ids)
    res = false
    if server_aspect_ids.empty? && server_ids.empty? # Just set component
      res = true
    elsif !server_aspect_ids.empty?
      res = server_aspect_ids.include?(cur_server.id)
    elsif !server_ids.empty?
      res = server_ids.include?(cur_server.id)
    end
    res
  end

  def note_content(note)
    line_size = 100
    word_wrap(auto_link(note.content,:urls, :target => "_blank"), :line_width => line_size)
  end

  def disable_all_form_fields(step)
    # TODO: requestor_access here
    return false if step.new_record?
    return true if step.request.nil?
    if step.request.plan_member.present? && step.request.plan_member.stage.present?
      if step.request.plan_member.stage.requestor_access
        return !step.belongs_to?(current_user)
      else
        return true
      end
    end
    !step.belongs_to?(current_user)
  end

  #MAY BE REMOVED NOT USING NOW
  def options_for_users_groups_from_collection_for_select(users, groups, step)
    options = "<optgroup label='Groups' owner_type='Group'>"
    options +=  options_from_collection_for_select(groups, :id, :name, (step.owner_type == 'User') ? nil : step.owner_id)
    options += "</optgroup>"
    options += "<optgroup label='Users' owner_type='User'>"
    options +=  options_from_collection_for_select(users, :id, :name, (step.owner_type == 'User') ? step.owner_id : nil)
    options += "</optgroup>"
    options.html_safe
  end

  def find_scripts(step)
    if step.script_type == "BladelogicScript" && GlobalSettings[:bladelogic_enabled] == true
      BladelogicScript.sorted
    elsif GlobalSettings.automation_available?
      Script.unarchived.visible.where("automation_category = ? AND scripts.automation_type != ?", step.script_type, 'ResourceAutomation').sorted
    else
      []
    end
  end

  def link_to_add_argument_fields(name, f, association, view_folder = '', argument_id)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(File.join(view_folder, association.to_s.singularize + "_argument_fields"), builder: builder, argument_id: argument_id)
    end
    link_to(name, '#', class: "add_argument_fields", id: "add_file_#{argument_id}", data: {id: id, fields: fields.gsub("\n", " ")})
  end

  def tree_node_selection_mode(arg_type)
    arg_type.eql?("in-external-single-select") ? 1 : 2 # "in-external-multi-select"
  end

  def step_has_invalid_component?(procedure, step)
    apps_id = procedure.apps.map(&:id)
    components = Component.components_for_apps(apps_id).map(&:id)
    step.component ? !components.include?(step.component.try(:id)) : false
  end

  def can_show_design_tab?(step)
    step.request_created? && step.locked? && can_view_step_design_tab?(step.request)
  end

  def can_view_step_design_tab?(request)
    can?(:view_step_design_tab, request) || current_user.id == request.owner_id || current_user.id == request.requestor_id
  end

  def can_manage_step?(step)
    if step.new_record?
      can?(:add_step, association_or_new_instance(step, :request))
    else
      can?(:edit_step, association_or_new_instance(step, :request))
    end
  end

  def step_allowed_tabs(step)
    tabs = (Step::STEP_TABS + ['design']).select do |tab|
      can? "view_step_#{tab}_tab".to_sym, association_or_new_instance(step, :request)
    end
    tabs << 'tickets' if can? :list, Ticket.new
    tabs << 'content' if can? :select_step_package, association_or_new_instance(step, :request)
    tabs
  end

  def default_tab(step)
    available_tabs = step_allowed_tabs(step)
    available_tabs.delete('notes') if step.new_record?
    return '' if available_tabs.blank?

    default_tab = (step.new_record? || step.default_tab.nil?) ? "general" : step.default_tab
    available_tabs.include?(default_tab) ? default_tab : available_tabs[0]
  end


  def default_tab_visibility(step, tab)
    result = " style='display:none;'"
    result = "" if tab == default_tab(step)
    result
  end

  def step_tab_li(step, tab)
    return '' if tab == "tickets" && (step.request.plan.nil? || step.request.plan.tickets.blank?)
    return '' unless step_allowed_tabs(step).include?(tab)

    selected = default_tab(step) == tab ? 'selected' : ''
    result = "<li class='#{selected}' id='st_#{tab}'"
    result += " style='visibility:hidden'" if tab == "content" && !("package" == step.related_object_type)
    result += ">  <a href='#'>#{tab.humanize}</a>"
    result += "</li>"
    result.html_safe
  end

  def render_step_tab(step, tab, form)
    result = ""
    if default_tab(step) == tab || tab == "general"
      result = render :partial => "steps/step_form_tabs/#{tab}", :locals => { :f => form, :request => @request, :step => step, :disable_fields => @disable_fields }
    end
    result.html_safe
  end

  def disabled_step_editing?(step)
    !( can?(:edit_step, association_or_new_instance(step, :request)) || step.enabled_editing?(current_user) )
  end

  def disable_automation_tasks?(step)
    !step.enabled_editing?(current_user)
  end

  def association_or_new_instance(entity, association_class)
    entity && entity.public_send(association_class.to_sym) || association_class.to_s.camelize.constantize.new
  end

  def disabled_step_per_permission_editing?(step, permission)
    cannot?(permission, association_or_new_instance(step, :request)) || !step.enabled_editing?(current_user)
  end

  def all_references_included_in_step?(reference_ids, step_reference_ids)
    (reference_ids & step_reference_ids) == reference_ids
  end

  def url_for_tab_loading(request, step, procedure)
    if request.present? && request.id.present?
      step.new_record? ? load_tab_data_request_steps_path(request) :
                         load_tab_data_request_steps_path(request, id: step.id)
    else
      step.new_record? ? load_tab_data_procedure_path(procedure) :
                         load_tab_data_procedure_path(procedure, step_id: step.id)
    end
  end

  def task_column_value(step, step_header)
    step.manual? ? step_header['work_task'] : step.view_object.script_name
  end

  def task_column_title(step, task_val)
    arr = []
    arr << h(task_val.html_safe) if task_val.present?
    arr << 'This step have protected automation' if step.protect_automation?
    arr.join("\n")
  end

  def package_component_type(step)
    if step.has_package?
      I18n.t('step.package')
    else
      I18n.t('step.component')
    end
  end

  def package_instances_selection(step)
    if step.package_instance.blank?
      if step.create_new_package_instance
        I18n.t('step.create_new')
      else
        if step.latest_package_instance
          I18n.t('step.latest')
        else
          I18n.t('select')
        end
      end
    else
      step.package_instance.name
    end
  end

end

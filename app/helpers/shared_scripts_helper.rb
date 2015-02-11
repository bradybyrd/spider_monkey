################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module SharedScriptsHelper

  def app_mapping_property_names(argument, installed_component)
    return unless installed_component

    argument.properties.for(installed_component).map { |p| h p.name }.to_sentence
  end

  def infrastructure_mapping_property_names(argument, installed_component)
    return unless installed_component

    installed_component.server_associations.map do |assoc|
      argument.properties.for(assoc).map { |p| h p.name }
    end.flatten.uniq.to_sentence
  end

  def shared_script_index_path(page = nil, key = nil)
    if bladelogic?
      bladelogic_path(:page => params[:page], :key => params[:key])
    elsif capistrano?
      capistrano_path(:page => params[:page], :key => params[:key])
    else
      hudson_path(:page => params[:page], :key => params[:key])
    end
  end

  def method_missing(method, *args, &block)
    if method.to_s =~ /(\w*)shared_script(s?_path)/
      if bladelogic?
        send("#{$1}bladelogic_script#{$2}", *args, &block)
      elsif capistrano?
        send("#{$1}capistrano_script#{$2}", *args, &block)
      else
        send("#{$1}hudson_script#{$2}", *args, &block)
      end
    else
      super
    end
  end

  def test_results_hyperlink(cur_note)
    results = cur_note.is_a?(String) ? cur_note : cur_note.content
    unless results.nil?
      lpos = results.index("[Script output written to:")
      unless lpos.nil?
        key_phrase = "automation_results/"
        ipos = results.index(key_phrase, lpos)
        if ipos.nil?
          result = "No output file specified"
        else
          ipos2 = results.slice(ipos..(ipos + 400)).index("]\n")
          fil = results.slice((ipos+key_phrase.length)..(ipos + ipos2 - 1))
          result = link_to("Output results file", "#{context_root}/automation_results/#{fil}", :onclick => "open_preview_script_window(this.href);return false;")
        end
      else
        result = "Couldn't locate output file link"
      end
    else
      result = "No results returned"
    end
    result
  end

  def prepared_to_test?(script)
    if bladelogic?
      GlobalSettings.bladelogic_ready? || script.step_authentication?
    else
      true
    end
  end

  def script_type
    # BJB-FIX need to adapt for multiple script types
    bladelogic? ? "BladeLogic" : capistrano? ? "Capistrano" : "Hudson"
  end

  def capistrano?
    @is_capistrano ||= (params[:controller] =~ /capistrano/i || (params[:action] =~ /capistrano/i).to_bool)
  end

  def hudson?
    @is_hudson ||= (params[:controller] =~ /hudson/i || (params[:action] =~ /hudson/i).to_bool)
  end

  def bladelogic?
    @is_bladelogic ||= (params[:controller] =~ /bladelogic/i || (params[:action] =~ /bladelogic/i).to_bool)
  end

  # Not used now, this function can be removed
  def select_automation_sub_tab
    if params[:script].class == String
      params[:script]
    else
      case @script.type
      when "HudsonScript"
        "hudson"
      when "BladelogicScript"
        "bmc blade_logic"
      when "CapistranoScript"
        "ssh"
      end
    end
  end

  def disable_resource_id?(script)
    return false if script.new_record? || script.unique_identifier.blank?
    if ScriptArgument.find_all_by_external_resource(script.unique_identifier).length > 0
      return true
    end
  end
end

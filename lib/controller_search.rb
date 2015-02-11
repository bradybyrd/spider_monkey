################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ControllerSearch
  
  def search 
    unless params[:key].blank?
      if params[:blad].nil? and self.class.method_defined?("capistrano")
        instance_variable_set "@scripts", 
        CapistranoScript.name_begins_with(first_letter_search(params[:key], CapistranoScript))
        render :action => 'capistrano'
      elsif params[:cap].nil? and self.class.method_defined?("bladelogic")
        instance_variable_set "@scripts", 
        BladelogicScript.name_begins_with(first_letter_search(params[:key], BladelogicScript))
        render :action => 'bladelogic'
      else
        model_name = get_model_name.camelize.constantize
        instance_variable_set "@active_#{get_variable_name}", 
        get_model_name.camelize.constantize.active.name_begins_with(first_letter_search(params[:key],model_name))
        instance_variable_set "@inactive_#{get_variable_name}", 
        get_model_name.camelize.constantize.inactive.name_begins_with(first_letter_search(params[:key],model_name))
        instance_variable_set "@current_page",params[:key]
        render :action => 'index'
      end
    else
      redirect_path = params[:redirect_path]
      redirect_to redirect_path
    end
  end  
  
  def get_model_name
    self.class.to_s.gsub(/Controller$/, '').singularize.underscore
  end
  
  def get_variable_name
    self.class.to_s.gsub(/Controller$/, '').underscore
  end
  
  def first_letter_search(key,model_name)
    first_instance = model_name.name_like("#{key}").order('name asc').group_by {
      |group| group.send(:name)[0].chr.upcase}.keys.first
    return 'A' if first_instance.nil?
    return first_instance
  end
end

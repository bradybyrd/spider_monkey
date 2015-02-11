################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityAttribute < ActiveRecord::Base

  InputTypes = %w(select multi_select text_field currency text_area radio checkbox date health)

  has_many :activity_tab_attributes, :dependent => :destroy
  has_many :activity_tabs, :through => :activity_tab_attributes

  has_many :activity_creation_attributes, :dependent => :destroy

  has_many :activity_attribute_values

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}
          
  scope :distinct_activity_category, lambda { |category| joins("inner join activity_tab_attributes on activity_attributes.id = activity_tab_attributes.activity_attribute_id").
                joins("inner join activity_tabs on activity_tabs.id = activity_tab_attributes.activity_tab_id").
                where("activity_tabs.activity_category_id = ?", category) }
  
#  There were some issues with Oracle so values is changed to attribute_values
  serialize :attribute_values, Array

  attr_accessible :field, :required, :input_type, :attribute_values, :from_system

  def values
    attribute_values
  end
  
  class << self
    
    def on_activity_category(category)
      # :select => "distinct activity.attributes.*" doesn't work with Oracle. 
      # selected all activity_attributes and applied uniq! to eliminate repeated entries
      # TODO for Piyush - Still check if this can be improved
      distinct_activity_category(category)
    end


    ### RVJ: 17 Apr 2012 : RAILS_3_UPGRADE: TODO: Reserved word conflict... Cannot use the reserved word field
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'field_changed?'
      super
    end
   
  end
  
  def default_values_for activity_category
    return values unless from_system?
    using(activity_category) { value_source.all } rescue empty_value
  end

  def value_for activity
    using(activity) do
      multi_select? ? typed_values : typed_values.first
    end
  end

  def pretty_value_for activity
    using(activity) do
      string_value
    end
  end

  def default_value_for activity_category
    default_values_for(activity_category).first
  end
  
  def disabled_on? activity_tab
    join_object_for(activity_tab).disabled?
  end

  def disable_on activity_tab
    join_object_for(activity_tab).update_attributes(:disabled => true)
  end

  def enable_on activity_tab
    join_object_for(activity_tab).update_attributes(:disabled => false)
  end

  def multi_select?
    input_type == 'multi_select'
  end

  def value_type
    return unless from_system?
    value_source_type
  end

  def currency?
    input_type == 'currency'
  end

  def date?
    input_type == 'date'
  end

  def widget? 
    false
  end

  def static?
    false
  end

  protected

  def empty_value
    multi_select? ? [] : nil
  end

  def value_source_type
    unless values.blank? || values_scoped_to_template?
      return values.first 
    else
      my_association = values_template_association
      return ActivityCategory.reflect_on_association(my_association).try(:class_name) unless my_association.blank?
    end
  end

  def current_activity
    raise "Current activity is not set!" unless @current_activity
    @current_activity
  end

  def current_activity_category
    template = @current_activity_category || @current_activity.try(:activity_category)
    raise "Neither current activity nor current activity template is set!" unless template
    template
  end

  def typed_values
    if date?
      raw_values.map { |v| Time.zone.parse v.to_s } rescue []
    elsif from_system?
      value_source.find_all_by_id(raw_values) rescue []
    else
      raw_values
    end
  end

  def string_value
    values = if date?
      typed_values.map { |v| v.try(:to_s, :simple) }
    elsif from_system?
      typed_values.map(&:name)
    else
      typed_values
    end
    values.join(', ')
  end

  def using activity_or_template
    return empty_value unless activity_or_template
    varname = "@current_#{activity_or_template.class.to_s.underscore}"
    instance_variable_set varname, activity_or_template
    rval = yield
    instance_variable_set varname, nil
    rval
  end

  def values_scoped_to_template?
    values.first.try(:starts_with?, 'template:') || false
  end

  def values_template_association
    values.first.try(:split, ':').try(:last).try(:to_sym) unless values.blank?
  end

  def value_scopes
    values[1..-1]
  end

  def value_source
    source = values_scoped_to_template? ? current_activity_category.send(values_template_association) : value_source_type.try(:constantize)
    if value_scopes && source 
      value_scopes.each do |scope|
        source = source.send(scope)
      end
    end
    source
  end

  def join_object_for activity_tab
    activity_tab_attributes.find_by_activity_tab_id(activity_tab)
  end
end

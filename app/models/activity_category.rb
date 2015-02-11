################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityCategory < ActiveRecord::Base
  include HasDefault
  include ActivityHealthImage

  has_many :activity_tabs, :order => "#{ActivityTab.quoted_table_name}.position", :dependent => :destroy
  has_many :activity_phases, :order => "#{ActivityPhase.quoted_table_name}.position", :dependent => :destroy
  has_many :index_columns, :class_name => "ActivityIndexColumn", :order => "#{ActivityIndexColumn.quoted_table_name}.position"
  has_many :creation_attributes, :class_name => "ActivityCreationAttribute", :order => "#{ActivityCreationAttribute.quoted_table_name}.position"
  has_many :activities, :dependent => :destroy

  attr_accessible :request_compatible

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}

  scope :request_compatible, where(:request_compatible => true)
  scope :name_order, order('name')

  def service?
    name == "Service"
  end

  def activity_attributes
    ActivityAttribute.on_activity_category(self)
  end

  def activity_static_attributes
    ActivityStaticAttribute.on_activity_category(self)
  end

  def static_columns
    if activity_static_attributes.present?
      (activity_static_attributes.all(:select => "field").map(&:field)) & ActivityIndexColumn.available_attributes
    end
  end

  def unused_static_columns
    if static_columns.present?
      static_columns - index_columns.map(&:activity_attribute_column)
    end
  end

  def filter_options_for_association assoc, *columns # PP - Allerin
    columns.compact!
    columns << 'name' if columns.empty?
    assoc = Activity.reflect_on_association(assoc.to_sym)

    named_columns = columns.map {|c| "#{assoc.table_name}.#{c} as #{assoc.name}_#{c}" }.join(',')
    columns = columns.map {|c| "#{assoc.table_name}.#{c}"}.join(" || ' ' || ")
    Activity.all(:select => "distinct #{assoc.table_name}.id as value, #{named_columns}," +
      "#{columns} as human_value",
      :joins => assoc.name,
      :conditions => "activities.activity_category_id=#{self.id}", #" and #{columns} <> ''")
      :order => (assoc.table_name == 'users' ? :last_name : :human_value))
  end

  def filter_options_for_column column
    column = column.to_s
    if column =~ /_ids?$/
      column = column.sub(/_id(s)?$/, '\1')
      filter_options_for_association(column, *Activity::DefaultAssociationColumns[column])
    elsif column == 'health'
      health_options
    elsif Activity.column_type(column) == :boolean || column == 'cio_list'
      boolean_column_options(column)
    else
      standard_column_options column
    end
  end

  private

  FilterOption = Struct.new(:value, :human_value)

  def unserialize_options filter_options
    list = []
    filter_options.each do |f|
      YAML.load(f.value).each do |item|
        list << item unless item.blank?
      end
    end
    list.uniq.map { |item| FilterOption.new(item, item) }
  end

  def health_options
    Activity::Healths.map do |h|
      option = health_option h
      FilterOption.new(h, option)
    end
  end

  def health_option health
    opt = ApplicationController.helpers.image_tag(activity_health_icon(health), :alt => health)
    # BJB What a mangle - FIX this
    srvtxt = opt.slice((opt.rindex("src=") + 5)..(opt.rindex("/images")-1))
    opt.gsub!(srvtxt, '')
  end

  def boolean_column_options column
    options = Activity.all(:select => "distinct #{column} as human_value, #{column} as value",
      :conditions => "activities.activity_category_id=#{self.id} and activities.#{column} is not null")

    options.map do |item|
      FilterOption.new item.value, item.value == '1' || item.value == 1 ? "Yes" : "No"
    end
  end

  def standard_column_options column
    column_name = OracleAdapter ? "to_char(#{column})" : column
    filter_options = Activity.all(:select => "distinct(#{column_name}) as human_value, #{column_name} as value",:conditions => "activities.activity_category_id=#{self.id} and activities.#{column} is not null", :order => :human_value)
    #filter_options = Activity.all(:select => "distinct #{column} as human_value, #{column} as value",:conditions => "activities.activity_category_id=#{self.id} and activities.#{column} is not null and activities.#{column} <> ''")
    temp = []
    filter_options.each do |filter|
      temp << filter unless filter.value.blank?
    end
    filter_options = temp
    filter_options = unserialize_options(filter_options) if Activity.serialized_attributes[column] == Array
    filter_options
  end
end

################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityIndexColumn < ActiveRecord::Base
  AvailableAttributes = { 'name'                => "Name",
                          'status'              => "Status",
                          'problem_opportunity' => "Problem/Opportunity",
                          'service_description' => "Service Description",
                          'budget_category'     => "Budget Category",
                          'manager_id'          => "Manager",
                          'parent_ids'          => "Parents", 
                          'goal'                => "Goal",  
                          'health'              => "Health", 
                          'projected_finish_at' => "Projected Finish",
                          'current_update'      => "Current Update",
                          'cio_list'            => "CIO List",
                          'budget'              => "Total Ballpark Budget",
                          'theme'               => "Portfolio Tag",
                          'estimated_start_for_spend' => 'Estimated Start for Spend',
                          'blockers'            => "Blocker(s)"}

  attr_accessor :activity
    
  attr_accessible :insertion_point

  belongs_to :activity_category

  validates :activity_attribute_column,
            :presence => true
  validates :activity_category_id,
            :presence => true
  acts_as_list :scope => :activity_category_id

  after_save :set_position

  scope :duplicates, {
    :select => "aic1.*",
    :from   => "activity_index_columns aic1",
    :joins  => "
          inner join activity_index_columns aic2
          on aic1.activity_category_id = aic2.activity_category_id
          and aic1.activity_attribute_column = aic2.activity_attribute_column",
    :conditions => "aic1.id <> aic2.id"
  }

  def self.available_attributes
    AvailableAttributes.keys
  end

  def name
    AvailableAttributes[activity_attribute_column]
  end

  def date?
    activity_attribute_column.ends_with? '_at'
  end

  def duplicate?
    ActivityIndexColumn.duplicates.first(:conditions => ["aic1.id=?", self]).to_bool
  end

  def filterable? # BJB Added theme and blockers
    ! %w(problem_opportunity current_update service_description theme blockers goal).include? activity_attribute_column
  end

  def using activity
    self.activity = activity
    yield self if block_given?
    self
  end

  def insertion_point= point
    @insertion_point = point
    @insertion_point_set = true
  end
  
  def health?
    activity_attribute_column == 'health'
  end

  def parent?
    activity_attribute_column == 'parent_ids'
  end

  def currency?
    activity_attribute_column == 'budget'
  end

  def activity_attribute_method
    activity_attribute_column.gsub(/_id(s)?$/, '_name\1')
  end

  def boolean?
    Activity.column_type(activity_attribute_column) == :boolean
  end

  private

  def set_position
    if @insertion_point_set
      @insertion_point_set = false
      insert_at @insertion_point
    end
  end
end

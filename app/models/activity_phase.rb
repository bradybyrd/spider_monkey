################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityPhase < ActiveRecord::Base
    
  attr_accessible :insertion_point
  
  belongs_to :activity_category

  has_many :deliverables, :class_name => "ActivityDeliverable", :dependent => :destroy

  validates :name,
            :presence => true,
            :uniqueness => {:scope => 'activity_category_id'}
  validates :activity_category_id,
            :presence => true
          
  scope :in_order, order("#{ActivityPhase.quoted_table_name}.position")

  acts_as_list :scope => :activity_category_id

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def previous
    higher_item
  end

  def next
    lower_item
  end
end

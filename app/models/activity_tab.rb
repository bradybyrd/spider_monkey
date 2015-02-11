################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityTab < ActiveRecord::Base

  belongs_to :activity_category
  
  has_many :activity_tab_attributes, :dependent => :destroy
  has_many :activity_attributes, :through => :activity_tab_attributes, :order => "#{ActivityTabAttribute.quoted_table_name}.position"

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :activity_category_id}
  validates :activity_category_id,
            :presence => true

  attr_accessible :name

  acts_as_list :scope => :activity_category_id

  def has_indexable_fields?
    activity_attributes.present?
  end

  def right_align?
    # FIXME: This is for Novartis only
    name == "Notes"
  end
end

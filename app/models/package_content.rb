################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageContent < ActiveRecord::Base
  
  include ArchivableModelHelpers
  include FilterExt
  
  normalize_attributes :name, :abbreviation
  validates :name,
            :presence => true,
            :uniqueness => true,
            :length => {:maximum =>255}
  validates :abbreviation,
            :length => {:maximum =>255,:allow_nil => true}
  
  scope :in_order, order('package_contents.position')
  scope :in_name_order,order('package_contents.name')

  has_many :request_package_contents, :dependent => :destroy
  has_many :requests, :through => :request_package_contents

  # scoping the position column to exclude archived records 
  # keeps them from messing up the counts
  # and is matched by move to bottoms on leavings for the archive
  # and coming back
  acts_as_list :scope => 'archived_at IS NULL'

  attr_accessible :name, :insertion_point, :request_ids
  
  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }
  
  # may be filtered through REST
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  def self.update_abbreviations!
    names = PackageContent.all.map(&:name).sort
    PackageContent.all.each do |pc|
      pc.abbreviation = names.differentiated_word(pc.name)
      pc.save(:validate => false)
    end
  end

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

  def can_be_archived?
    count_of_associated_requests == 0 && count_of_associated_request_templates == 0
  end
    
  # destroyable if it has been archived and there child objects
  def destroyable?
    return self.archived? && self.requests.functional.empty?
  end

end


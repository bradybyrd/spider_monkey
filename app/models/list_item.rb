################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class ListItem < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  acts_as_archival(:readonly_when_archived => true)
  # check conditions for safe archiving
  before_archive :check_for_archive_blockers
  # if a non-unique names has been added while this as archived, increment the name
  before_destroy :check_destroyable
  
  normalize_attributes :value_text, :with => [ :strip, :blank, { :truncate => { :length => 255 } } ]

  belongs_to :list

  attr_accessible :list_id, :value_text, :last_modified_by_id, :is_active, :value_num
  
  scope :name_order, order('value_text ASC')
  validates :value_text, :length =>{:maximum =>255,:allow_nil =>true}
  validates :value_num,:numericality =>{ :only_integer => true, :allow_nil => true}

  #FIXME: This is a temporary patch to allow test and rest interfaces
  # that do not go through the controller to benefit from updates to these
  # constants (which are then not really constants) when list items are changed
  after_save :reload_list_constants
  
  scope :filter_by_value_text, lambda { |filter_value| where("LOWER(list_items.value_text) like ?", filter_value.downcase) }
  scope :filter_by_value_num, lambda { |filter_value| where(:value_num => filter_value) }
  scope :filter_by_list_id, lambda { |filter_value| where(:list_id => filter_value) }
  scope :filter_by_list_name, lambda { |filter_value| includes(:list).where("LOWER(lists.name) like ?", filter_value.downcase) }
  
  delegate :value_hash, to: :view_object

  # may be filtered through REST
  is_filtered cumulative: [:value_text, :value_num, :list_id, :list_name],
              boolean_flags: {default: :unarchived, opposite: :archived}

  class << self
    def find_it_category(li)
      find_li BudgetLineItem::CorporateIT, li
    end

    def find_cost_type(li)
      find_li BudgetLineItem::CostTypes, li
    end

    def find_category(li)
      find_li BudgetLineItem::Categories, li
    end

    def find_location(li)
      find_li User.locations, li
    end

    def find_li(list_items, li)
      li.present? ? list_items.select {|l| l.downcase == li.downcase}.first : li
    end
  end

  # returns a boolean to the before_archive hook and any view
  # that needs to decide to show or hide the archive link
  def can_be_archived?
    return true
  end

  # destroyable if it has been archived and there child objects
  def destroyable?
    return self.archived?
  end

  private

  # FIXME: These should not be constants at all -- this is a patch to
  # save time and at least guarantee that this is run everytime a list item is added, not just
  # when the controller create action is run so rest and testing benefit from the behavior
  def reload_list_constants
    List.reload_constant!(self.list.name) unless self.list.blank? || self.list.name.blank?
  end

  # lists items have no constraints, but might in the future
  # so I am putting the structure here.  These values tend to
  # get written permenantly into string fields (not associated)
  def check_for_archive_blockers
    unless self.can_be_archived?
      raise ActiveRecord::Rollback
    else
    return true
    end
  end

  # check if the record can be destroyed
  def check_destroyable
    if self.destroyable?
    true
    else
      self.errors.add(:base, "List items are linked to this list and prevented it from being deleted.")
    false
    end
  end

  def view_object
    @view_object ||= ListItemView.new self
  end

end

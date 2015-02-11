################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'sortable_model'

class List < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  sortable_model

  # reload constants after an updates (used to be in the controller which is brittle)
  after_update :reload_constants

  normalize_attributes :name

  has_many :list_items, dependent: :destroy

  attr_accessible :list_item_ids, :name, :created_by_id, :is_text, :is_active, :list_items_attributes, :is_hash
  attr_reader :view_object

  scope :sorted, order('name ASC')

  sortable_model

  can_sort_by :name

  validates :name, uniqueness: true, presence: true, length: {maximum: 255, allow_nil: true}

  REQUIRED_LISTS = %w(ActionOnFail AutomationErrors ClosedStatuses EmploymentTypes
                      EventsForCategories IncludeInSteps Reboot Roles UserRoles
                      ValidStatuses Healths Locations SingleUserMode RequestEstimates)

  # adding a nested attributes capability for list items to allow list creation
  # in a single rest call
  accepts_nested_attributes_for :list_items,
                                reject_if: lambda { |a| a[:value_text].blank? && a[:value_num].blank? },
                                allow_destroy: true


  # Constant Name => Class Name
  ListConstants = {
    'Roles' => 'Activity',
    'Healths' => 'Activity',
    'ValidStatuses' => 'Activity',
    'ClosedStatuses' => 'Activity',
    'IncludeInSteps' => 'Procedure',
    'EventsForCategories' => 'Step',
    'UserRoles' => 'User',
    'EmploymentTypes' => 'User',
    'ReleaseContentItem' => 'ScheduleState'}

  scope :filter_by_name, lambda { |filter_value| where(name: filter_value) }

  # may be filtered through REST
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  class << self

    def reload_constant!(list_name)
      if ListConstants.key?(list_name)
        if ListConstants[list_name].is_a? String
          klass = ListConstants[list_name]
          const = list_name
        else
          klass = ListConstants[list_name][:klass]
          const = ListConstants[list_name][:constant]
        end
        # reseting constants is a no-no, but this code has been here for a while
        # what the conditional tries to do is minimize the number of warnings
        # for unnecessary changes to the constants, thought there will be some.
        new_list = List.get_list_items(list_name).compact.sort
        klass.constantize.const_set(const, new_list) if (const.blank? || const == new_list)
      end
    end

    def get_list_items(list_name, options = {})
      raise ArgumentError, "`list_name` should be a List name string, but integer `#{list_name.inspect}` was given" if list_name.is_a? Integer

      list  = List.unarchived.find :first, conditions: { name: list_name }, include: :list_items

      list_items_by_type list, options
    end

    def list_items_by_type(list, options = {})
      if list.blank?
        list_items = []
      else
        list_items = list.list_items.unarchived
        if list.is_hash?
          list_items = list_items.map{|li| [li.value_text, li.value_num]}
        elsif list.is_text?
          list_items = list_items.pluck(:value_text)
        else
          list_items = list_items.pluck(:value_num)
        end
      end

      list_items = list_items.sort_by &options[:sort_by] if options.fetch(:sort_by, false)
      list_items.blank? ? ['empty list'] : list_items
    end

  end # class methods

  def required_label
    required?.to_s
  end

  def required?
    REQUIRED_LISTS.include?(self.name)
  end
  alias :required :required?

  # lists have list items which should be archived with them
  # unless a list is one of our required system lists.
  # returns a boolean to the before_archive hook and any view
  # that needs to decide to show or hide the archive link
  def can_be_archived?
    !self.required?
  end

  # destroyable if it has been archived and there child objects
  def destroyable?
    self.archived? && !self.required?
  end

  def view_object
    @view_object ||= ListView.new self
  end

  private

  # a hook to reload system constants based on lists
  # FIXME: we should not be storing editable items in these pseudo-constants
  def reload_constants
    List.reload_constant!(self.name)
  end
end


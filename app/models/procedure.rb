################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Procedure < ActiveRecord::Base
  include StepContainer
  include ArchivableModelHelpers
  include FilterExt
  include ObjectState

  IncludeInSteps = List.get_list_items("IncludeInSteps")

  has_many :steps, :dependent => :destroy, :order => 'steps.position'

  has_and_belongs_to_many :apps

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false},
            :length => {:maximum =>255}

  normalize_attributes :name, :description

  attr_accessible :name, :description, :app_ids, :step_ids, :step_ids_to_clone, :aasm_state, :created_by

  attr_accessor :step_ids_to_clone

  # pull in any clonable steps on create using an attribute and a before
  # validation hook so errors can be reported and the transaction rolled back
  # FIXME: The controller still has the legacy method call and is not protected
  # from various kinds of failure, so it should be refactored. For now this is
  # being done for REST so the UI controller has not been touched.
  before_validation :find_steps_to_be_cloned

  after_save :add_new_steps

 # initialize AASM state machine for object status
  init_state_machine

  def add_steps(new_steps)
    @new_steps = new_steps
  end

  #No condition reqd as the associated steps are cloned ;have separate existence and are dependent destroy.
  def can_be_archived?
    true
  end

  scope :with_app_id, lambda { |app_id| includes(:apps).where("apps_procedures.app_id = ?", app_id) }
  scope :filter_by_name, lambda { |filter_value| where("LOWER(procedures.name) like ?", filter_value.downcase) }
  scope :active, where(arel_table[:aasm_state].not_eq('draft').and(arel_table[:aasm_state].not_eq('archived_state')))

  # may be filtered through REST
  is_filtered cumulative: [:name],
              cumulative_by: {app_id: :with_app_id},
              boolean_flags: {default: :unarchived, opposite: :archived}

  private

  # for now this is used by REST, but controller should rely on the model, not method
  # calls for this functionality
  def find_steps_to_be_cloned
    success = false
    # check that someone has set a value
    unless step_ids_to_clone.blank?
      # check if the steps can be found
      @new_steps = Step.find_all_by_id(step_ids_to_clone)

      if @new_steps.blank?
        self.errors.add(:step_ids_to_clone, " could not be found.")
      elsif step_ids_to_clone.length - @new_steps.length > 0
        missing_ids = step_ids_to_clone - @new_steps.map { |m| m.id }
        self.errors.add(:step_ids_to_clone, " could not find the following step ids: #{missing_ids}.")
      else
        success = true
        # blank out the passed ids so they are not there on the next validation round
        step_ids_to_clone = nil
      end
    else
      success = true
    end

    # return a boolean so the validation loop passes
    return success
  end

  def add_new_steps
    if @new_steps
      @new_steps.each do |step|
      #
      # RAJESH: 17 December 2011
      # Postgres does not have a concept of autoincrement Id
      # Now, due to this, after a clone step is attempted to be inserted,
      # it attempts to set the id field to null which causes it to throw a null-voilation
      # So, as a workaround, we mimic the same logic as by create a brand new object
      # and then initializing it with attribute values that we are interested in.
      #
        if PostgreSQLAdapter || MsSQLAdapter
          attribs = {}
          includes_in_steps = List.get_list_items("IncludeInSteps")

          step.attributes.each_pair do |key, value|
            if includes_in_steps.include?(key)
              attribs[key] = value
            end
          end
          new_step = Step.new(attribs)
        else
          new_step = step.dup(:except => (Step.column_names - List.get_list_items("IncludeInSteps")))
        end

        self.steps << new_step
        new_step.save!
        step.copy_script_parameters new_step
      end
    end
  end

  def find_procedure
    begin
      @procedure = Procedure.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Procedure you are trying to access either does not exist or has been deleted"
      redirect_to(procedures_path) && return
    end
  end

end


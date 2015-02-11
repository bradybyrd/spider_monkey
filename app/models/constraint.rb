################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Constraint < ActiveRecord::Base
  include FilterExt

  attr_accessible :active, :constrainable_id, :constrainable_type, :governable_id,
                  :governable_type, :governable, :constrainable

  after_save :refresh_governable_state

  after_destroy :goveranable_post_destroy

  # polymorphic relationship with constrainable models that can serve to limit what
  # requests appear inside a plan stage such as RouteGates.
  belongs_to :constrainable, polymorphic: true

  # polymorphic relationship with governable models that can be passed to a constraint
  # and return a value object detailing their pass/fail status and any error messages.
  belongs_to :governable, polymorphic: true

  validates :constrainable_id, :governable_id, :numericality => { :only_integer => true }
  validates :constrainable_id, :governable_id, :constrainable_type, :governable_type, :presence => true

  # now we need a custom validation that asks the governable model whether or
  # not this constraint is valid for it
  validate :can_be_constrained

  scope :active, where(:active => true)
  scope :inactive, where(:active => false)
  scope :filter_by_governor, lambda { |filter_value| where(:governable_id => filter_value[:id], :governable_type => filter_value[:type]) }
  scope :filter_by_constraint, lambda { |filter_value| where(:constrainable_id => filter_value[:id], :constrainable_type => filter_value[:type]) }
  scope :filter_by_constrainable_type,  lambda { |filter_value| where(:constrainable_type => filter_value) }


  # special scopes for finding typical governable objects
  scope :filter_by_route_id, lambda { |filter_value| joins("INNER JOIN route_gates ON (constraints.constrainable_id = route_gates.id AND constraints.constrainable_type = 'RouteGate')").where("route_gates.route_id = ?", filter_value).order('route_gates.position ASC') }

  # may be filtered through REST
  is_filtered cumulative: [:constraint, :governor, :route_id, :constrainable_type], boolean_flags: {default: :active, opposite: :inactive}

  # place holder method for checking if the constraint can be deleted
  def can_be_deleted?
    true
  end

  # a convenience method for showing the constraint label
  def constrainable_label
    constrainable.try(:constrainable_label) || 'Name Missing'
  end

  private

  # this method asks the governable object
  # whether or not these constraints are valid for it
  def can_be_constrained
    if governable.present? && constrainable.present? && governable.respond_to?(:can_be_constrained_by)
      # this has to return true or false for the validation
      error_message = governable.can_be_constrained_by(constrainable)
      errors.add(:governable_id, error_message) if error_message.present?
    end
  end

  # a callback after any changes
  def refresh_governable_state
    # by convention, governable objects should have a constraint violations
    # method which will set any necessary state -- this model does not
    # need to care about the return values

    # BEFORE: governable.delay.try(:constraint_violations) - TODO: Possible performance issues w/o 'delay'
    governable.try(:constraint_violations) if governable.respond_to?(:constraint_violations)
    true
  end

  # a callback after constraint delete
  def goveranable_post_destroy
    governable.constraint_post_delete if governable.respond_to?(:constraint_post_delete)
  end
end

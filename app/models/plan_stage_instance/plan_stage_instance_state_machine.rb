################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class PlanStageInstance < ActiveRecord::Base

  include AASM

  # allows us to push messages about state changes
  include Messaging
  acts_as_messagable

  aasm do

    # a state for empty or all constraints satisfied
    state :compliant, :initial => true

    # a catch all for constrain violations including being late to start, late to finish, over booked, and accessing
    # invalid environments
    state :noncompliant

    event :mark_compliant, :success => :push_msg do
      transitions :to => :compliant, :from => [:noncompliant]
    end

    event :mark_noncompliant, :success => :push_msg do
      transitions :to => :noncompliant, :from => [:compliant]
    end


  end

  def self.status_filters_for_select
    aasm.states.map { |state| [state.name.to_s.humanize, state.name.to_s] }
  end

end

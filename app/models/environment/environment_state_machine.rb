################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################
class Environment < ActiveRecord::Base

  include AASM

  # allows us to push messages about state changes
  include Messaging
  acts_as_messagable

  aasm column: 'deployment_policy' do

    # a state for using env anytime on this env
    state :opened, initial: true

    # a state to force use deployment windows for requests on this env
    state :closed

    event :mark_opened, success: :push_msg do
      transitions to: :closed, from: [:opened]
    end

    event :mark_closed, success: :push_msg do
      transitions to: :opened, from: [:closed]
    end

  end

  def self.status_filters_for_select
    aasm.states.map { |state| [state.name.to_s.humanize, state.name.to_s] }
  end

end

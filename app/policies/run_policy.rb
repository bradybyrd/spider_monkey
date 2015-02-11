################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RunPolicy
  attr_reader :ignore_states

  def initialize(instance, options = {})
    @run            = instance
    @ignore_states  = options.fetch :ignore_states, false
  end

  # run state to perform validations for
  def aasm_states_to_check
    started? || aasm_event == 'start' || ignore_states
  end

  # it can start if all requests are valid
  def validate_can_start
    if aasm_states_to_check
      cannot_start! if requests_have_notices?
    end
  end

  def cannot_start!
    errors.add(:base, "#{requests_notices_message}")
  end

  def method_missing(*args, &block)
    @run.send(*args, &block)
  end
end

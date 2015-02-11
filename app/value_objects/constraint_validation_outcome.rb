################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# a value object returned by constraint policies such as the RouteGate policy
# that allows for more verbose reporting than a simple success boolean
class ConstraintValidationOutcome

  def initialize(governable, candidate=nil, passed=false, message='Passed')
    # storing these objects allows for introspection and more advanced reporting
    @governable = governable
    @candidate = candidate
    # defaults to blocking so we don't pass things that are not tested or return nil
    @passed = passed
    # defaults to 'Passed to simplify messaging on successful constraints'
    @message = message
  end

  def governable
    @governable
  end

  def candidate
    @candidate
  end

  def passed
    @passed
  end

  def message
    @message
  end

  def to_s
    @message.to_s
  end
end
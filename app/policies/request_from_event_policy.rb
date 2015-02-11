################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class RequestFromEventPolicy
  def initialize(instance)
    @request = instance
  end

  def valid?
    result = check_application
    result = check_estimate && result
    result && @request.valid?
  end

private

  def check_application
    @request.errors.add(:base, "Application can't be empty") if @request.app_ids.blank?
    !@request.app_ids.blank?
  end

  def check_estimate
    @request.errors.add(:base, "Estimate can't be empty") if @request.estimate.blank?
    !@request.estimate.blank?
  end
end

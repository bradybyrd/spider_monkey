################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'rake' 

class AddEstimatedStartForSpendAttributes < ActiveRecord::Migration
  def self.up
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      # added Estimated Start for Spend to activity_attributes
      begin
        Rake::Task["sp:add_estimated_start_for_spend_attributes"].invoke
      rescue
        Rake::Task["db:migrate"].invoke
      end
    end
  end

  def self.down
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      # remove Estimated Start for Spend to activity_attributes
      activity_attribute = ActivityAttribute.find_by_name("Estimated Start for Spend")
      activity_attribute.destroy if activity_attribute
    end
  end
end

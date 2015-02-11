################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
module Helpers

  # a method to wait a specified time
  #
  # wait 20 do
  #   page.should have_content("Copyright")
  # end
  #
  def wait(time, increment = 5, elapsed_time = 0, &block)
    begin
      yield
    rescue Exception => e
      if elapsed_time >= time
        raise e
      else
        sleep increment
        wait(time, increment, elapsed_time + increment, &block)
      end
    end
  end

  def self.verify_models_empty
    # Make sure all data are cleaned
    Rails.application.eager_load!

    dirty = false
    ActiveRecord::Base.descendants.each do |m|
      unless %w(AutomationScript Promotion ReleaseContent FusionChart).include? m.name
        unless m.all.empty?
          puts "#{m.name} is not empty"
          dirty = true
        end
      end
    end
    raise "Some tests left data in database, please clear it" if dirty
  end

  def enable_automations(enabled=true)
    update_global_setting(:automation_enabled, enabled)
    update_global_setting(:bladelogic_enabled, enabled)
  end

  def update_global_setting(key, value)
    GlobalSettings[key] = value
  end

  def self.cleanup_models
    DatabaseCleaner.clean_with :deletion
  end

  def with_current_user(user, &block)
    saved = User.current_user
    User.current_user = user
    return_value = block.call
    User.current_user = saved
    return_value
  end

  def stub_activity_log
    ActivityLog.stub(:log_event_with_user_readable_format)
    ActivityLog.stub(:inscribe)
  end

  delegate :cleanup_models, to: :Helpers
end

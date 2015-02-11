################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
#
# Example:
# class K
#   include AutomationBackgroundable
#   def meth; end
# end
#
# K.background.meth # would run method in background

module AutomationBackgroundable
  DEFAULT_QUEUE_PATH ||= '/queues/backgroundable/automation'

  class BackgroundProxy
    attr_accessor :base, :options

    def initialize(base, options)
      @base     = base
      @options  = (options || {}).update(priority: :low)
    end

    def method_missing(method, *args)
      @base.queue.publish(object:@base, method: method, args: args, options: @options)
    end
  end

  module ClassMethods
    def queue(queue_path = AutomationBackgroundable::DEFAULT_QUEUE_PATH)
      begin
        TorqueBox.fetch queue_path
      rescue
        raise "Queue -- `#{queue_path.inspect}` not found"
      end
    end

    def queue_path
      AutomationBackgroundable::DEFAULT_QUEUE_PATH
    end

    def background(options={})
      BackgroundProxy.new(self, options)
    end

    def remove_messages
      self.queue.remove_messages
    end
  end

  include ClassMethods # make class methods also instance methods
end
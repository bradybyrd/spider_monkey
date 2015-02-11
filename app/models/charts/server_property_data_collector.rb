################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class ServerPropertyDataCollector < PropertyDataCollector
    def initialize(options)
      @server_level_id = options[:server_level_id].to_i
      super
    end

  private

    attr_reader :value_holder_ids

    def server?
      @server_level_id.zero?
    end

    def value_holder_ids
      if server?
        @value_holder_ids ||= Server.ids
      else
        @value_holder_ids ||= ServerLevel.find_by_id(@server_level_id).server_aspect_ids
      end
    end

    def value_holder_type
      return @value_holder_type if @value_holder_type

      @value_holder_type = "Server"
      @value_holder_type << "Aspect" unless server?
      @value_holder_type
    end
  end
end

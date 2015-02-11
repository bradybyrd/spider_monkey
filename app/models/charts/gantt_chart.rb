################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class GanttChart
    %w(bar label_line milestone tooltip).each do |funk|
      define_method(funk) do |*args|
        "gantt.#{funk.camelize :lower}(#{args_to_js(*args)});"
      end
    end

    def args_to_js *args
      args.map do |x| 
        x.camelize_keys! :lower if x.is_a? Hash
        x.to_json
      end.join(',')
    end
  end
end

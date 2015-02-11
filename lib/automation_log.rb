################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AutomationLog
  def initialize(filename = "log/automation.log")
    if File.exists?(filename)
      @log = FileInUTF.open(filename, "a")
      @log.puts logstamp
    else
      @log = FileInUTF.new(filename, "a")
      @log.puts "=========== Automation Log ============"
      @log.puts "New Log #{tstamp}"
    end
  end
  
  def append(new_info)
    @log.puts "\n#{tstamp}:  #{new_info}"
  end
  
  def close
    @log.close
  end
  
  def tstamp
    Time.now.localtime.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def logstamp
    "=========== New Run: #{tstamp} ============"
  end
    
end

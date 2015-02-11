################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#  Sample Script to hog time
#  enter the sleep time in seconds
#   Called by test_sleeper script
require 'monitor'

class Timer
   def initialize(interval, &handler)
     raise ArgumentError, "Illegal interval" if interval < 0
     extend MonitorMixin
     @run = true
     @th = Thread.new do
       t = Time.now
       while run?
          t += interval
          (sleep(t - Time.now) rescue nil) and
            handler.call rescue nil
       end
     end
   end

   def stop
     synchronize do
       @run = false
     end
     @th.join
   end

   def set_action(action)
     synchronize do
       @action = action
     end
   end

   private

   def run?
     synchronize do
       @run
     end
   end
end

def check_status
  puts "Current status: #{@action}"
  @last_action = @action
end

####  Main Routine ####
if ARGV.length > 0
  sleep_interval = ARGV[0].to_i
else
  sleep_interval = 60
end
loop_limit = (sleep_interval/10).to_i
@count = 0
tstart = Time.now.localtime
@last_action = "none"
@action = @last_action
t = Timer.new(1) do
   check_status
   # random sleep to show slot stability
   interval = 2
   @count += 1
   sleep(interval)
end

puts "I'm staying busy here - sleeping for #{sleep_interval} seconds"
for inc in 1..200
  puts "Monitor Checking"
  if inc > loop_limit
    puts "Count reached #{inc}, stopping execution - elapsed time: #{(Time.now.localtime - tstart).to_i} secs"
    t.stop
    break
  else
    puts "Count is #{inc}/#{loop_limit} - keep going... - elapsed time: #{(Time.now.localtime - tstart).to_i} secs"
  end
  @action = "Waiting(#{@count})"
  t.set_action(@action)
  sleep 10
end
t.stop

################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# BJB 4/28/10
#  Lists Rightscale images using rightscale gem
require 'rubygems'
require 'right_aws'

Routines = ["list_instances", 
  "list_images", 
  "launch_image <aws_id>, <note>", 
  "delete_instance <aws_id>"]

def syntax_msg
  puts "##########    Amazon Control Script     ###########"
  puts "   ARGUMENTS"
  Routines.each_with_index do |args, idx|
    puts "#{idx.to_s}) #{args} \n"
  end
  puts "\nEx: /home/streamadmin/rightscale/amazon_control list_instances"
end

def detach_storage(image_id)
  san = @ec2.describe_volumes.reject{ |v| v[:aws_instance_id] != image_id}
  if san.size > 0
    san.each do |vol|
      result = @ec2.detach_volume(vol[:aws_id])
    end
  else
    result = "No storage"
  end
end

def image_exists(image_id)
  result = aws_login # sets @ec2 variable
  @ec2.describe_instances.reject{ |vm| vm[:aws_instance_id] != image_id}.size > 0
end

def instance_status(instance_id, quiet = nil)
  status = aws_login # sets @ec2 variable
  msg = "============ Amazon Server Status ===============\n"
  inst = @ec2.describe_instances.reject{ |vm| vm[:aws_instance_id] != instance_id}
  if inst.size > 0
    msg += pretty_output(inst[0])
  else
    msg += "Instance not found\n"
  end
  puts msg if quiet.nil?
  inst[0]
end

def list_instances(quiet=nil)
  status = aws_login # sets @ec2 variable
  #get instances
  instances = @ec2.describe_instances
  pretty_output(instances, true) if quiet.nil?
  instances
end

def list_images
  status = aws_login #sets the @ec2 handle
  #get images
  images = @ec2.describe_images_by_owner('self')
  images
end

def launch_image(aws_id = 'none', note = '')
  #get instances
  msg = "Creating server from image: #{aws_id}\n"
  puts "AWS_ID: " + aws_id
  unless aws_id == 'none'
    if aws_id.length > 7
      image = aws_id
      result = aws_login
      launch_result = @ec2.run_instances(
        image,
        1, 
        1, 
        ['default'], 
        'ec2-keypair', 
        note, 
        nil, nil, nil, nil, 'us-east-1b', nil)

      msg += "============ Amazon Cloud Creation Results ==============="
      msg += Time.now.to_s
      #puts "# ".ljust(4) + "- ID --".ljust(15) + "- State ----"
      launch_result.each_with_index do |img, idx|
        #puts "#{(idx.to_s + ')').ljust(3)} #{(img[:aws_instance_id] + ':').ljust(16)} #{img[:aws_state]}"
        msg += "Instance_id: #{img[:aws_instance_id]}, Status: #{img[:aws_state]}\n"
      end
    end
  end
  puts msg
  msg
end

def delete_instance(aws_id)
  # Delete instances
  images = Array.new(0)
  image = aws_id
  images[0] = image
  msg = "============ Amazon Cloud Deletion Results ===============\n"
  msg += "\tAttempting to delete: #{aws_id}\n"
  result = aws_login
  if image_exists(image)
    detach_storage(image)
    term_result = @ec2.terminate_instances(images)
    msg += Time.now.to_s + "\n"
    msg += "Terminating: #{aws_id}\n"
    #msg += "# ".ljust(4) + "- ID --".ljust(15) + "- State ----\n"
    term_result.each_with_index do |img, idx|
      #msg += "#{(idx.to_s + ')').ljust(3)} #{(img[:aws_instance_id] + ':').ljust(16)} #{img[:aws_shutdown_state]}\n"
      msg += "Instance_id: #{img[:aws_instance_id]}, Status: #{img[:aws_shutdown_state]}\n"
    end
  end
  puts msg
  msg
end

def pretty_output(aws_result, to_stdout = false)
  return if aws_result.nil? || aws_result.length < 1
  multi_item = aws_result.is_a?(Array)
  if multi_item
    aws_type = aws_result[0].keys.include?(:aws_instance_type) ? "instance" : "image"
  else
    aws_type = aws_result.keys.include?(:aws_instance_type) ? "instance" : "image"
  end
  if aws_type == "image"
    msg = "============ Amazon Cloud Images ===============\n"
    msg += Time.now.to_s + "\n"
    msg += "# ".ljust(4) + "- ID --".ljust(15) + "- Path ----\n"
    aws_result.each_with_index do |img, idx|
       msg += "#{(idx.to_s + ')').ljust(3)} #{(img[:aws_id] + ':').ljust(16)} #{img[:aws_location]}\n"
    end
    puts msg if to_stdout
  elsif aws_type == "instance"
    if multi_item
      msg = "============ Amazon Cloud Instances ===============\n"
      msg += Time.now.to_s + "\n"
      msg += "# ".ljust(4) + "-- DNS ---------------------------".ljust(46) + "OS ----".ljust(11) + "Size ---".ljust(11) + "Status -- ID ----\n"
      aws_result.each_with_index do |vm, idx|
        msg += "#{(idx.to_s + ')').ljust(3)} #{(vm[:dns_name] + ':').ljust(45)} #{(vm[:aws_platform].nil? ? 'Linux' : vm[:aws_platform].capitalize).ljust(10)} #{vm[:aws_instance_type].ljust(10)} #{vm[:aws_state].ljust(9)} #{vm[:aws_instance_id]}\n"
      end
    else
      msg = "============ Instance Status ===============\n"
      msg += "====  #{Time.now.to_s}: ====\n"
      msg += "Current State:     #{aws_result[:aws_state]}\n"
      msg += "DNS Name:          #{aws_result[:dns_name]}\n"
      msg += "Internal DNS:      #{aws_result[:private_dns_name]}\n"
      msg += "Security Group:    #{aws_result[:aws_groups].inspect}\n"
      msg += "SSH Key:           #{aws_result[:ssh_key_name]}\n"
      msg += "Availability Zone: #{aws_result[:aws_availability_zone]}\n"
      msg += "Instance Type:     #{aws_result[:aws_instance_type]}\n"
      msg += "Launch Time:       #{aws_result[:aws_launch_time]}\n"
    end
    puts msg if to_stdout
  end
  msg
end

def aws_login
  # Make a connection handle
  puts "Path is: " + File.expand_path(File.dirname(__FILE__))
  info = File.open(File.expand_path(File.dirname(__FILE__)) + "/amazon_login.txt", "r").read
  # access_id: 1J365I4Q4K33EP2S1Q02
  # secret_key: ogJwelZKvPqNlPoiRqeDJH1rwNxEi+Dt2oRgZ1gP
  # owner_id: 497279483945
  msg = "Failed to obtain login information"
  found = info.scan(/access_id:.+/)
  return msg if found.empty?
  access_id = found[0].gsub("access_id:","").strip.chomp
  found = info.scan(/secret_key:.+/)
  return msg if found.empty?
  secret_key = found[0].gsub("secret_key:","").strip.chomp
  found = info.scan(/owner_id:.+/)
  return msg if found.empty?
  owner_id = found[0].gsub("owner_id:","").strip.chomp
  @ec2 = RightAws::Ec2.new(access_id, secret_key)
  
end

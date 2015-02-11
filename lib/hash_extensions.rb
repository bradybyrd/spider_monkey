################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module HashExtensions
  require 'yaml'

  def camelize_keys! first_letter = :upper
    each_key do |key|
      self[key.to_s.camelize(first_letter)] = delete(key)
    end
  end

  def camelize_keys(first_letter = :upper)
    dup.camelize_keys!(first_letter)
  end

  def get key, temp_default = self.default
    has_key?(key) ? self[key] : temp_default
  end

  def yank! key, temp_default=self.default
    delete(key) || temp_default
  end
  
  def nil_or_empty?
    empty?
  end
  
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  #
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  # RJ: Rails 3: Commented out this block
  # as it interferes with rails new psych yaml program
  # during delayed job etc.
  #def to_yaml( opts = {} )
  #  YAML::quick_emit( object_id, opts ) do |out|
  #    out.map( taguri, to_yaml_style ) do |map|
  #      sort.each do |k, v|   # <-- here's my addition (the 'sort')
  #        map.add( k, v )
  #      end
  #    end
  #  end
  #end

  
end

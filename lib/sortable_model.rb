################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module SortableModel
  def self.extended(mod)
    mod.module_eval do
      @_sort_scopes = []
    end
  end

  def sorted_by name, *args
    if @_sort_scopes.include?(name.to_sym)
      send("_sorted_by_#{name}", *args)
    else
      raise NoMethodError, "Sort condition is not defined: #{name}"
    end
  end

  private
  def can_sort_by name_or_hash, scope_args=nil
    scope_args ||= generate_scope_args(name_or_hash)
    generate_named_scope name_or_hash, scope_args
  end

  def generate_named_scope name_or_hash, scope_args
    name = get_scope_name(name_or_hash)
    @_sort_scopes << name.to_sym
    scope "_sorted_by_#{name}", scope_args
  end

  def get_scope_name name_or_hash
    Hash === name_or_hash ? name_or_hash.keys.first : name_or_hash
  end

  def generate_scope_args name_or_hash
    case name_or_hash
    when Hash
      name, order_col, table = scope_args_from_hash(name_or_hash)
      lambda { |asc| includes(name.to_sym).order("#{table}.#{order_col} #{asc ? "ASC" : "DESC"}") }
    else
      order_col = name_or_hash
      table = quoted_table_name
      lambda { |asc| order("#{table}.#{order_col} #{asc ? "ASC" : "DESC"}") }
    end
  end

  def scope_args_from_hash hash
    name = hash.keys.first
    order_col = hash[name]
    table = reflect_on_association(name.to_sym).quoted_table_name
    [name, order_col, table]
  end
end

ActiveRecord::Base.instance_eval do
  def sortable_model
    extend SortableModel
  end
end

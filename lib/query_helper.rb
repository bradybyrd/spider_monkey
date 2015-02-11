################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module QueryHelper

  IN_CLAUSE_LENGTH = 999
    
  module ClassMethods
    def group_by_all
      self.column_names.map{|c| "#{table_name}.#{c}"}.join(",")
    end
  end

  def self.included(mod)
    mod.extend(ClassMethods)

    ### RVJ: 13 Apr 2012 : RAILS_3_UPGRADE: TODO: Verify that the static method works instead of this removed name scope
    #mod.named_scope :distinct, :select => "DISTINCT #{mod.table_name}.*"
  end

  def self.distinct
    select("#{mod.table_name}.*").uniq
  end

  # Use the following module to look after bunch of records with IN clause in SQL
  # Example:
  # ModelName.scoped.extending(QueryHelper::WhereIn).
  #      select(items_columns).
  #      where_not_in(<field_name>, <array_of_values>).
  #      ...
  # This where_in prevent from Oracle IN Clause issue when number of values more than 1000

  module WhereIn

    def where_in(*args)
      _where_in("IN", "OR", *args)
    end

    def where_not_in(*args)
      _where_in("NOT IN", "AND", *args)
    end

    private

    def _where_in(clouse, cond, field = "id", ids = [])
      ids_in_groups = ids.each_slice(IN_CLAUSE_LENGTH).to_a
      items_search_string = (["(#{field} #{clouse} (?))"]*ids_in_groups.length).join(" #{cond} ")
      where(items_search_string, *ids_in_groups)
    end
  end

end

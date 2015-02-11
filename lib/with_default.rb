################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module WithDefault

  def self.included target
    target.extend ClassMethods
    target.alias_method_chain :destroyable?, :default
    target.attr_protected :default
  end

  module ClassMethods
    def default
      find_by_default true
    end

    def find_or_create_default
      default_model = default
      default_model = create_default unless default_model

      default_model
    end


    ### RVJ: 12 Apr 2012 : RAILS_3_UPGRADE: TODO: Verify that this scope works
    def name_order
      order("'#{self.quoted_table_name}.default' DESC, '#{self.quoted_table_name}.name' ASC") 
    end

    def create_default
      default_model = new :name => '[default]'
      default_model.default = true
      default_model.save
      ApplicationEnvironment.associate_defaults

      default_model
    end

    def has_default?
      default.to_bool
    end
  end

  def destroyable_with_default?
    return false if default?
    destroyable_without_default?
  end

end

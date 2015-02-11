################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Promotion < ActiveRecord::Base

  def self.columns
    @columns ||= []
  end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :app_id,           :string
  column :source_env,       :string
  column :target_env,       :string

  validates :target_env, presence: true
  validates :source_env, presence: true
  validates :app_id, presence: true

  attr_accessible :app_id, :source_env, :target_env

  HUMANIZED_ATTRIBUTES = {
      app_id: 'Application',
      source_env: 'Source environment',
      target_env: 'Target environment'
  }

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def app
    App.find(app_id)
  end

  def application_environments
    app.application_environments.in_order
  end

  def source_environments
    application_environments.find_all_by_environment_id(source_env)
  end

  def target_environments
    application_environments.find_all_by_environment_id(target_env)
  end

  private

  def uniqnuess_of_source_env
    if source_env.present? && target_env.present? && (target_env == source_env)
      self.errors[:base] << 'Target and source environments should be different'
    end
  end

end

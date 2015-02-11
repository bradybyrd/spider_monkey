################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class EnvironmentServer < ActiveRecord::Base
  belongs_to :environment
  belongs_to :server
  belongs_to :server_aspect
  
  attr_accessible :server_id, :environment_id

  validates :environment,
            :presence => true
          
  validate :server_association_validation

  scope :active, joins(:server).where('servers.active' => true)

  def self.import_app(environment_servers_hash)
    environment_servers_hash.map do |environment_server_params|
      ServerImport.new([environment_server_params["server"]]).ids.first
    end
  end

  private

  def server_association_validation
    unless server.to_bool ^ server_aspect.to_bool
      self.errors[:base] << "There must be exactly one server association."
    end
  end
    
end

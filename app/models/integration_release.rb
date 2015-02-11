################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationRelease < ActiveRecord::Base
  
  has_many :release_content_items, :dependent => :nullify
  belongs_to :project, :class_name => "IntegrationProject"
  
  scope :active, where("integration_releases.active" => true)
  scope :inactive, where("integration_releases.active"=> false)
  
  scope :name_order, :order => "integration_releases.name ASC"
  
  validates :name,:presence => true

  attr_accessible :name
  
end

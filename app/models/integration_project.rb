################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationProject < ActiveRecord::Base
  
  include SoftDelete
  
  belongs_to :project_server
  has_many :releases, :class_name => "IntegrationRelease"
  has_many :sub_projects, :class_name => "IntegrationProject", :finder_sql => 
    'SELECT DISTINCT integration_projects.* FROM integration_projects WHERE integration_projects.parent_id = #{id}'
  has_many :release_content_items, :dependent => :nullify
  
  scope :active, where("integration_projects.active" => true)
  scope :inactive, where("integration_projects.active"=> false)
  
  scope :name_order, :order => "integration_projects.name ASC"
  
  validates :name, 
            :presence => true,
            :length => {:minimum => 2, :unless => Proc.new{|ip| ip.name.blank?}}
  

  attr_accessible :name, :releases
  
  def releases=(names)
    return unless names

    (release_names - names).each do |old_name|
      old_release = releases.find_by_name(old_name)
      old_release.destroy if old_release
    end

    (names - release_names).each do |name|
      next if name.blank?
      releases.build :name => name
    end
  end
  
  def release_names
    releases.map(&:name)
  end
  
end

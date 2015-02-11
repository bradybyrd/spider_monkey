################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BusinessProcess < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  normalize_attributes :name

  # NK - These codes should be dynamic
  # This is done as per color codes shown by DT on Pivotal:2491727

  ColorCodes = {
    1 => "#82AEEB", # Standard Release
    2 => "#EB7F79", # Emergency Release
    3 => "#CCEF8E"  # Hotfix
  }

  has_many :requests

  has_many :apps_business_processes , :dependent => :destroy
  has_many :apps, :through => :apps_business_processes

  scope :name_order, order('name asc')

  validates :name, presence: true, uniqueness: true
  validates :label_color, presence: true
  validates :app_ids, presence: true

  attr_accessible :name, :label_color, :app_ids, :request_ids

  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }

  # may be filtered through REST
  is_filtered cumulative: [:name], boolean_flags: {default: :unarchived, opposite: :archived}

  HUMANIZED_ATTRIBUTES = {
    :app_ids => "Application list"
  }

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def can_be_archived?
    (count_of_associated_requests == 0)    && (count_of_associated_request_templates == 0 )
  end

  def validate_updated_apps(updated_apps)
    apps_removed = self.apps.active.map(&:id) - updated_apps.map{ |id| id.to_i }

    apps_removed.each do |app_id|
      bus_proc_is_in_use=Request.extant.with_app_id(app_id).with_business_process_id(self.id)
      raise ActiveRecord::Rollback unless bus_proc_is_in_use.blank?
    end
  end

  def self.import_app_request(xml_hash)
    if xml_hash["business_process"]
      name = xml_hash["business_process"]["name"]
      businessprocess = find_by_name(name)
      if businessprocess.present?
        businessprocess.id
      end
    end
  end

end

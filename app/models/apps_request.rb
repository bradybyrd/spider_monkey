################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AppsRequest < ActiveRecord::Base
  extend AssociationFreezer::ModelAdditions

  acts_as_audited except: [:frozen_app]

  belongs_to :request, touch: true
  belongs_to :app
  has_many :application_environments, foreign_key: :app_id

  attr_accessible :request_id, :app_id

  validates :app_id, uniqueness: {scope: :request_id}

  enable_association_freezer
end

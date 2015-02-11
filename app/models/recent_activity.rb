################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RecentActivity < ActiveRecord::Base
  default_scope :order => 'timestamp DESC'
  
  belongs_to :actor, :polymorphic => true
  belongs_to :object, :polymorphic => true
  belongs_to :indirect_object, :polymorphic => true
  
  validates :actor, :presence => true
  validates :object, :presence => true
  validates :verb, :presence => true
  
  def before_create
    self.timestamp ||= Time.now
  end
  
  def to_s
    default = ["objects.#{object_type.underscore}.#{verb}".intern, "verbs.#{verb}".intern, "#{actor_type.underscore} #{verb} #{object_type.intern}"]
    I18n.t "actors.#{actor_type.underscore}.#{object_type.underscore}.#{verb}", :scope => 'activity_streams', :default => default, :actor => actor, :verb => verb, :object => object, :object_type => object_type
  end
end

################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class NotificationTemplate < ActiveRecord::Base
  include SoftDelete
  include FilterExt

  validates :body,:presence => true
  validates :format,:presence => true
  validates :title,:presence => true

  validates :active,  inclusion: { in: [true, false] }
  validates :event,   inclusion: { in: Notifier.supported_events }
  validates :format,  inclusion: { in: Notifier.supported_formats }

  #validates_uniqueness_of :active, :scope => :event, :message => " cannot be true while another notification template is active for the same event."

  # normalize attributes by default does name and title
  normalize_attributes :description, :title, :subject, :format, :event

  after_save :deactivate_rival_templates

  attr_accessible :title, :format, :event, :description, :subject, :body, :active

  #
  # Usable string representation
  #
  def to_s
    "[NotificationTemplate] Title: #{self.title}, Event: #{self.event}, Method: #{self.format}, Description: #{self.description}, Active: #{self.active}. Body: #{self.body}"
  end

  #
  # If performance becomes a problem, consider serializing the template as per 
  # http://cjohansen.no/en/rails/liquid_email_templates_in_rails
  #

  def deactivate_rival_templates
    if self.active
      rivals = NotificationTemplate.where active: true, event: self.event
      rivals.each { |r| r.update_attribute(:active, false) unless r.id == self.id }
    end
  end

  scope :filter_by_title, lambda { |filter_value| where("LOWER(notification_templates.title) like ?", filter_value.downcase) }

  is_filtered cumulative: [:title], boolean_flags: {default: :active, opposite: :inactive}
end

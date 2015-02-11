################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'file_size_validator'

class Upload < ActiveRecord::Base
  default_scope where(deleted: false)

  attr_accessible :owner_id, :owner, :owner_type, :user_id, :user, :attachment,
                  :uploaded_data, :attachment_cache, :remove_attachment, :updated_at,
                  :deleted, :description, :new_attachment

  attr_accessor :new_attachment

  # new attachment manager
  mount_uploader :attachment, AttachmentUploader

  acts_as_audited :only => [:attachment,:owner_id,:owner_type],  :protect => false

  belongs_to :owner, :polymorphic => true
  belongs_to :user
  before_save :write_user_id
  before_validation :set_content_type

  before_destroy :archive_step_attachments

  validates :attachment, file_size: { maximum: 5.megabytes }
  validates :description, length: { maximum: 255 }
  validates :filename, length: { maximum: 50 }

  # TODO: RJ: Rails 3 - Attachment_fu plugin not compatible with Rails 3.
  # Find and use alternate one
  #has_attachment :storage => :file_system, :max_size => 5.megabytes
  #validates_as_attachment

  delegate :name, to: :user, prefix: true, allow_nil: true

  scope :archieved_attachments, ->{ where(deleted: true).order(:updated_at) }

  def deep_copy(options = {})
    return if new_record?
    new_clone = self.dup
    Array(options[:except]).each{ |attribute| new_clone.attributes[attribute.to_s] = nil }
    success = new_clone.update_attribute(:attachment, self.attachment) # this will also save the new_clone
    new_clone if success
  end

  def write_user_id
    write_attribute(:user_id, User.current_user.id) unless User.current_user.nil?
  end

  def set_content_type
    if attachment.file.present?
      self.content_type = attachment.file.content_type if attachment.file.content_type.present?
      self.filename = attachment.file.filename if attachment.file.filename.present?
    end
  end

  # convenience function for easy REST to json and to xml getting of this property
  def get_attachment_url
    return self.attachment.url unless self.attachment.blank?
  end

  def find_uploader
    user_id.present? ? "#{self.user.try(:to_label)}, #{updated_at.try(:default_format)}" : updated_at.try(:default_format)
  end

  private

  def archive_step_attachments
    if owner_type == 'Step'
      remove_attachment!
      update_attributes(deleted: true, updated_at: Time.now, user: User.current_user)
      false
    else
      true
    end
  end

end

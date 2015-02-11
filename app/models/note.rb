################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Note < ActiveRecord::Base
  belongs_to :user
  #belongs_to :step
  belongs_to :object, :polymorphic => true

  validates :user,:presence => true
  validates :content,:presence => true

  attr_accessible :content, :user_id, :holder_type, :holder_type_id, :object_type, :object_id,:created_at

  acts_as_audited

  def holder
    holder_type.nil? ? nil : holder_type.constantize.find(holder_type_id)
  end

  def user_name
    @user = User.find_by_id user_id
    @user.name
  end

  def self.import_app(object,xml_hash,objecttype)
    if(xml_hash["notes"])
      xml_hash["notes"].each do |xml_hash|
        content = xml_hash["content"]
        name = xml_hash["user_name"].split(',')
        user = User.find_by_last_name_and_first_name(name[0].squish,name[1].squish)
        Note.create(:user_id => user.id,:content => content.to_s,:object_type => objecttype,:object_id => object.id)
      end
    end
  end

end

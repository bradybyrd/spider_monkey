################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class EmailRecipient < ActiveRecord::Base
  acts_as_audited
  belongs_to :request
  belongs_to :recipient, :polymorphic => true

  attr_accessible :request, :recipient, :request_id, :recipient_id, :recipient_type

  validates :request, :presence => true
  validates :recipient, :presence => true

  scope :users, where(:recipient_type => 'User')
  scope :groups, where(:recipient_type => 'Group')

  def recipient_name
    recipient.name
  end

  def self.import_app(request,reqs_components_xml_hash)
    if reqs_components_xml_hash["email_recipients"]
      reqs_components_xml_hash["email_recipients"].each do |key, val|
       recipienttype = key["recipient_type"]
       recipientname = key["recipient_name"]
       if recipienttype == 'Group'
        group = Group.find_by_name recipientname
        find_or_create_by_request_id_and_recipient_id_and_recipient_type(request.id,group.id,recipienttype)
       else
          name = recipientname.split(',')
        user = User.find_by_last_name_and_first_name(name[0].squish,name[1].squish)
        find_or_create_by_request_id_and_recipient_id_and_recipient_type(request.id,user.id,recipienttype)
       end
      end
    end
  end
end

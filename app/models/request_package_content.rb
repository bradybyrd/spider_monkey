################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RequestPackageContent < ActiveRecord::Base

  acts_as_audited
  belongs_to :request
  belongs_to :package_content

  attr_accessible :package_content_id


def self.import_app(request,xml_hash)
  if xml_hash["package_contents"]
    xml_hash["package_contents"].each do | packagecontent |
      obj =  PackageContent.where(name: packagecontent["name"]).first_or_create
      RequestPackageContent.find_or_create_by_request_id_and_package_content_id(request.id,obj.id)
    end
  end
end

end

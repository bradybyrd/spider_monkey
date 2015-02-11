################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class User < ActiveRecord::Base

  def inbound_requests_ids(reqs)
    inbound_requests(reqs).map(&:id)
  end

  def inbound_request_ids_new(reqs)
    @inbound_reqs = reqs.inbound_requests_of_user_new(self)
  end

  def inbound_requests(reqs)
    @inbound_reqs = reqs.inbound_requests_of_user(self)
  end

  def inbound_request_conds
    conds = "requests.requestor_id <> #{self.id} AND "
    if group_ids.empty?
      conds += "(steps.owner_type = 'User' AND steps.owner_id = #{self.id})"
    else
      conds += "((steps.owner_type = 'User' AND steps.owner_id = #{self.id}) OR (steps.owner_type = 'Group' AND steps.owner_id IN (#{group_ids.join(',')})))"
    end
  end

  def outbound_request_ids(reqs)
    outbound_requests(reqs).map(&:id)
  end

  def outbound_requests(reqs)
    @outbound_reqs = reqs.where('requests.requestor_id = ? or requests.owner_id = ?', id, id)
  end

end

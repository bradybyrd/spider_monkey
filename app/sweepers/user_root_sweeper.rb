################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class UserRootSweeper < ActionController::Caching::Sweeper
  observe Group, User

  def after_create(record)
    expire_cache_for(record)
  end

  def after_update(record)
    expire_cache_for(record)
  end

  def after_destroy(record)
    expire_cache_for(record)
  end

  private
  def expire_cache_for(record)
    if record.is_a?(User)
      expire_cache_for_user(record.id)
    elsif record.is_a?(Group)
      expire_cache_for_group(record)
    end
  end

  def expire_cache_for_user(user_id)
    cache_key = [:user_root, user_id]
    Rails.cache.delete(cache_key)
  end

  def expire_cache_for_group(group)
    group.user_ids.each do |user_id|
      expire_cache_for_user(user_id)
    end
  end

end
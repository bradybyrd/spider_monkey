################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActiveRecord
  class Base
    def self.silence
      yield
    end

    def self.search_by_ci(column, keyword)
      self.where(" UPPER(#{column}) like ?", "%#{keyword.upcase}%")
    end
  end
end

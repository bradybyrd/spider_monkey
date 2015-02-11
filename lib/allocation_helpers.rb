################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module AllocationHelpers
  Months = { 1  => 'Jan',
             2  => 'Feb',
             3  => 'Mar',
             4  => 'Apr',
             5  => 'May',
             6  => 'Jun',
             7  => 'Jul',
             8  => 'Aug',
             9  => 'Sep',
             10 => 'Oct',
             11 => 'Nov',
             12 => 'Dec' }

  def months_hash
    Months.dup
  end

  def allocation_total_for_year_and_month(year, month)
    resource_allocations.find_all_by_year_and_month(year, month).map { |alloc| alloc.allocation }.sum
  end

end

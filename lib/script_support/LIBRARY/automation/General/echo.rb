################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])

# ========================================================================
# User Script
# ========================================================================

puts "Echo each step parameter to output"
params.each do |key, val|
  write_to "#{key} ----- #{val}"
end

write_to "Done with the echo script"


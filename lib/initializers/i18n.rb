################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

I18n.load_path += Dir[File.join(Rails.root, 'lib', 'locale', '*.{rb,yml}')]
I18n.default_locale = 'en'

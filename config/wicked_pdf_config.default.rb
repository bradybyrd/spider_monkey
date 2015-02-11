################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# To change this template, choose Tools | Templates
# and open the template in the editor.

# FIXME
# Based on what we decide, if we decide to ship wkhtmltopdf binaries for Windows,
# we should configure the Path relative to installation directory
WickedPdf.config = {
  :exe_path => Windows ? "C:\\Programs\\wkhtmltopdf\\wkhtmltopdf.exe" : `which wkhtmltopdf`.chomp
}


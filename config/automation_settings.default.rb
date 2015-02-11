################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# full path of automation_results folder 
# defult during set by installer is <BRPM_INSTALLATION FOLDER>/automation_results
$OUTPUT_BASE_PATH = File.join(Rails.root, "public")
$AUTOMATION_JAVA_OPTS = "-XX:PermSize=64m -Xmx128m -Xms32m -Xss2048k"

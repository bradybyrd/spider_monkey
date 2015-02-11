################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module RequestTemplatesHelper
  
  def common_environments_of_apps_of_template(req)
    options = ''
    selected = req.environment_id
    req.common_environments_of_apps.map do |environment|
      options += "<option data-deployment-policy='#{environment.deployment_policy}'" +
                 " value='#{environment.id}'"
      options +=' selected="true"' if environment.id == selected
      options +=">#{environment.name}</option>"
    end
    options
  end
  
end

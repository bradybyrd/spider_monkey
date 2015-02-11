################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module PlanRoutesHelper

  def plan_route_title(plan_route)
    "Plan Route for #{truncate(plan_route.plan_name)}: #{h(truncate(plan_route.route_app_name))} - #{h(truncate(plan_route.route_name))}"
  end

  def constraint_type_links(psi)
    links = []
    constraints_by_type = psi.constraints_by_type
    constraints_by_type.each do |type, constraints|
      links << link_to( pluralize(constraints.try(:length), type.underscore.humanize), constraints_plan_path(psi.plan, plan_stage_instance_id: psi.id, constrainable_type: type), :rel => "facebox[.plan_constraint_type_detail_facebox]", :class => "link_constraint_detail")
    end
    # put a 0 entry in no matter what
    if links.empty?
      links << pluralize(0, 'Route gate')
      #TODO: Expand to support other constraints as they become available
    end
    raw links.join(" | ")
  end

end
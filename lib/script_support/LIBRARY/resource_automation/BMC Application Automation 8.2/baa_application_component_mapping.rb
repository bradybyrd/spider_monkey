###
#
# component_template:
#   name: Component Template
#   type: in-external-single-select
#   external_resource: baa_component_templates
#   position: A1:F1
#
###


def execute(script_params, parent_id, offset, max_records)
  write_to("Dummy Resource Automation that is used to facilitate mapping of a BRPM application component to a BAA Component template")
end

def import_script_parameters
  { "render_as" => "Table", "maps_to" => "Component" }
end
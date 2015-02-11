class Step < ActiveRecord::Base

  def resource_automation_script
    if !script.nil?
      current_script_external_resource = script.arguments.map(&:external_resource).compact
      Script.active.where(unique_identifier: current_script_external_resource).as_json(
        only: resource_automation_script_attributes,
        include: resource_automation_script_argument_attributes
      )
    end
  end

  private

  def resource_automation_script_attributes
    [:name, :automation_category, :automation_type, :aasm_state, :content, :description, :template_script_type, :unique_identifier, :tag_id,:render_as, :maps_to]
  end

  def project_server_safe_attributes
    [:server_name_id, :details, :ip, :name, :password, :port, :server_url, :username]
  end

  def resource_automation_script_argument_attributes
    { arguments: { only:[:name, :argument, :argument_type, :position] },
      project_server:{only: project_server_safe_attributes }}
  end
end
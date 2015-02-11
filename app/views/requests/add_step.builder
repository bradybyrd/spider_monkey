xml.instruct!
xml.request do
  xml.request_id @request.number
  xml.message @message
  xml.name @request.name
  xml.environment @request.environment_name
  xml.requestor @request.requestor_name
  xml.owner @request.owner_name
  @request.steps.order_by_position.each do |step|
    xml.step do
      xml.id step.id.to_s
      xml.name step.name
      xml.component step.component.name if step.component
      xml.component_version step.component_version if step.component
      xml.manual step.manual.to_s
      unless step.manual
        xml.script_type step.script_type
        xml.script_id step.script_id.to_s
        xml.script step.script.name
      end
      xml.description step.description
    end
  end
end
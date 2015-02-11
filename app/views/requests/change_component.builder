xml.instruct!
xml.request do
  xml.request_id @request.number
  xml.message @message
  xml.status @request.aasm.current_state.to_s.humanize
  xml.name @request.name
  xml.process @request.business_process.try(:name)
  xml.application @request.app_name
  xml.environment @request.environment_name
  xml.package_content_tags @request.package_content_tags
  xml.requestor @request.requestor_name
  xml.owner @request.owner_name
  xml.release_tag @request.release.try(:name)
  xml.duration request_duration(@request)
  xml.rescheduled @request.rescheduled? ? "Yes" : "No"
  xml.planned_start @request.scheduled_at.try(:default_format)
  xml.actual_start @request.started_at.try(:default_format)
  xml.due_by @request.target_completion_at.try(:default_format)
  xml.actual_completion @request.completed_at.try(:default_format)
  xml.description @request.description
  xml.wiki @request.wiki_url
  xml.notes @request.notes
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

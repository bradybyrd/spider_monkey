xml.instruct!
xml.step_status do
	xml.request_id @request.id
	xml.step_id @step.id
	xml.step @step.name
	xml.message message
  xml.status @step.aasm.current_state.to_s.humanize
  xml.name @request.name
  xml.application @request.app_name unless @request.app.default?
  xml.environment @request.environment_name unless @request.environment.default?
  xml.requestor @request.requestor_name
  xml.owner @request.owner_name
  xml.notes @request.notes
end

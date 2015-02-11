xml.instruct!
xml.request do
	xml.request_id @request.id
  xml.status @request.aasm_state.to_s.humanize
  xml.name @request.name
  xml.application ensure_space(@request.app_name.to_sentence)
  xml.environment @request.environment_name unless @request.environment.default?
	xml.message message
end
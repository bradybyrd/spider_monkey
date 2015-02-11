xml.instruct!
xml.request do
  xml.request_id @step.request.number
  xml.message @message
  xml.status @step.aasm_state.to_s.humanize
  xml.name @step.name
  xml.started_at @step.work_started_at.try(:default_format)
  xml.finished_at @step.work_finished_at.try(:default_format)
end
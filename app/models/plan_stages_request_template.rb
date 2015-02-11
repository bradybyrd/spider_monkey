class PlanStagesRequestTemplate < ActiveRecord::Base
  self.table_name = 'p_stages_request_templates'

  attr_accessible :plan_stage, :request_template, :plan_stage_id, :request_template_id

  belongs_to :plan_stage
  belongs_to :request_template
end

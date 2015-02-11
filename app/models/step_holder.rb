class StepHolder < ActiveRecord::Base
  
  belongs_to :step
  belongs_to :request
  belongs_to :change_request
  
  validates :step_id,
            :presence => true
  validates :request_id,
            :presence => true
  validates :change_request_id,
            :presence => true

  scope :request_id_equals, lambda{|id|
    where(:request_id => id)
  }
  def self.find_operation_ticket_option(request, step)
    return step.change_request  unless step.new_record?
    change_req_id = request.steps.present? && request.steps.map(&:change_request).present? ? 
      StepHolder.where(:request_id => request.id).map(&:change_request_id).first : nil       
    change_req_id.blank? ? nil : change_req_id 
  end
  
end

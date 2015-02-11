class StepReference < ActiveRecord::Base
  belongs_to :step
  belongs_to :owner_object, polymorphic: true

  validates :step_id, presence: true
  validates :reference_id, presence: true
  attr_accessible :reference_id, :step_id, :owner_object_id, :owner_object_type
end

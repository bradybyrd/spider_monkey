class LinkedItem < ActiveRecord::Base
  
  acts_as_audited
  #
  # Polymorphic Relationships
  belongs_to :source_holder, :polymorphic => true
  belongs_to :target_holder, :polymorphic => true

  validates :source_holder_type,:presence => true
  validates :source_holder_id, :presence => true
  validates :target_holder_type,:presence => true
  validates :target_holder_id,:presence => true

  # Generic named scopes that could be used to map onto a specific source holder/target holder
  # For example, I can do 
  # LinkedItem.by_source_holder_type('Ticket').by_target_holder_type('Plan').by_target_holder_id(5).map { |l| l.source_holder}
  # This will give me tickets for the specified plan
  scope :by_source_holder_type, lambda { |source_holder_type| where(:source_holder_type => source_holder_type) }
  scope :by_target_holder_type, lambda { |target_holder_type| where(:target_holder_type => target_holder_type) }
  scope :by_source_holder_id, lambda { |source_holder_id| where(:source_holder_id => source_holder_id) }
  scope :by_target_holder_id, lambda { |target_holder_id| where(:target_holder_id => target_holder_id) }

end

class ExtendedAttribute < ActiveRecord::Base
  #
  # Polymorphic Relationships
  belongs_to :value_holder, :polymorphic => true

  validates :name,
            :presence => true,
            :uniqueness => {:scope => [:value_holder_id, :value_holder_type]}
          
  attr_accessible :name, :value_text
  
  attr_accessible :name, :value_text, :value_holder
  
end

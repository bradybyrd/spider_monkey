class StepsReleaseContentItem < ActiveRecord::Base
  
  belongs_to :step
  belongs_to :release_content_item
end

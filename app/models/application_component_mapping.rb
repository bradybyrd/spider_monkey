class ApplicationComponentMapping < ActiveRecord::Base
  attr_accessible :application_component_id, :data, :project_server_id, :script_id

  belongs_to :application_component
  belongs_to :project_server
  belongs_to :script

  class JsonWrapper
    def self.load(string)
      string.nil? ? string : (string.valid_json? ? JSON.parse(string) : string)
    end

    def self.dump(data)
      data.empty? ? data : data.to_json
    end
  end  
  
  serialize :data, JsonWrapper

  validates :project_server_id, 
            :presence => true,
            :uniqueness => {:scope => :application_component_id, :message => ' for given component has already been mapped to'}

  validates :data, :presence => true
  validates :script_id, :presence => true

end

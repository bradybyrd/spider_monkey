class ServerLevelImport

  def initialize(server_level_hash)
    @server_level = ServerLevel.find_or_initialize_by_name(server_level_hash['name'])
    @server_level.description = server_level_hash['description']
    @server_level.save!
    add_server_level_properties(server_level_hash['properties'])
  end

  def id
    @server_level.id
  end

  private

  def add_server_level_properties(props_list)
    if props_list
      props_list.each do |prop_params|
        prop = Property.find_or_initialize_by_name(prop_params['name'])
        prop_params['server_level_ids'] = (prop.server_level_ids + [@server_level.id]).uniq
        prop.update_attributes!(prop_params)
      end
    end
  end
end
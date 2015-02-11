class ServerGroupImport

  def initialize(server_groups_hash)
    @server_groups = import_server_groups(server_groups_hash || {}).compact || []
  end

  def names
    @server_groups.map(&:name) if @server_groups
  end

  def ids
    @server_groups.map(&:id) if @server_groups
  end

  private

  def import_server_groups(server_groups_hash)
    server_groups_hash.map do |server_group_params|
      server_ids = ServerImport.new(server_group_params['active_servers']).ids
      build_server_group(server_group_params, server_ids)
    end
  end

  def build_server_group(server_group_params, server_ids)
    server_group_params.delete('active_servers')
    server_group_params.delete('type')
    server_group = ServerGroup.find_or_initialize_by_name(server_group_params['name'])
    server_group_params['server_ids'] = server_group.server_ids | server_ids
    server_group.update_attributes!(server_group_params)
    server_group
  end

end
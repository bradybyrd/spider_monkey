class ServerAspectGroupImport

  def initialize(groups_hash, env)
    @server_aspect_groups = import_server_aspect_groups(groups_hash || [], env).compact || []
  end

  def names
    @server_aspect_groups.map(&:name) if @server_aspect_groups
  end

  def ids
    @server_aspect_groups.map(&:id) if @server_aspect_groups
  end

  private

  def import_server_aspect_groups(groups_hash, env)
    groups_hash.compact.map do |sag_params|
      build_server_aspect_group(sag_params, env)
    end
  end

  def build_server_aspect_group(sag_params, env)
    sag = ServerAspectGroup.find_or_initialize_by_name(sag_params['name'])
    server_level = ServerLevelImport.new(sag_params['server_level'])
    sag.server_level_id = server_level.id
    sag.server_aspect_ids |= ServerAspectImport.new(sag_params['server_aspects'], env, server_level).ids
    sag.save!
    sag
  end
end
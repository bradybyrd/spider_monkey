class ServerAspectImport

  def initialize(aspects_hash, env, server_level)
    @env = env
    @server_level = server_level
    @server_aspects = iterate_and_import_server_aspects(aspects_hash || {}).compact || []
  end

  def names
    @server_aspects.map(&:name) if @server_aspects
  end

  def ids
    @server_aspects.map(&:id) if @server_aspects
  end

  private

  def iterate_and_import_server_aspects(aspects_hash)
    aspects_hash.map do |aspect_params|
      if has_good_parent?(aspect_params)
        @server_level = ServerLevelImport.new(aspect_params['server_level']) if @server_level.nil?
        import_server_aspect(aspect_params)
      end
    end
  end

  def import_server_aspect(aspect_params)
    attributes = aspect_finder_params(aspect_params)
    aspect = ServerAspect.where(attributes).first_or_initialize
    build_server_aspect(aspect_params, aspect)
  end

  def aspect_finder_params(aspect_params)
    parent = get_parent_from_hash(aspect_params)
    {
      name: aspect_params['name'],
      parent_type: parent.class.to_s,
      parent_id: parent.id,
      server_level_id: @server_level.id
    }
  end

  def has_good_parent?(aspect_params)
    if aspect_params['parent_type'] == 'Server'
      Server.find_by_name(aspect_params['parent']['name'])
    else
      true
    end
  end

  def build_server_aspect(aspect_params, aspect)
    aspect.description = aspect_params['description']
    aspect.environment_ids = aspect.environment_ids | [@env.id]
    aspect.save!
    update_current_prop_values(aspect_params['current_property_values'], aspect)
    aspect
  end

  def update_current_prop_values(prop_vals, aspect)
    if prop_vals
      prop_vals.each do |prop_val|
        property = Property.find_by_name(prop_val['name'])
        aspect.update_attributes!(properties_with_value_ids: aspect.properties_with_value_ids | [property.id])
        property.update_value_for_object(aspect, prop_val['value'], prop_val['locked'])
      end
    end
  end

  def get_parent_from_hash(aspect_params)
    case aspect_params['parent_type']
    when 'Server'
      Server.find_by_name(aspect_params['parent']['name'])
    when 'ServerGroup'
      ServerGroup.find_by_name(aspect_params['parent']['name'])
    end
  end
end
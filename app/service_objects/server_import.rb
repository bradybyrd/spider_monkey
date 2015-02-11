class ServerImport

  def initialize(servers_hash)
    @servers = import_servers(servers_hash || []).compact || []
  end

  def names
    @servers.map(&:name) if @servers
  end

  def ids
    @servers.map(&:id) if @servers
  end

  private

    def import_servers(servers_hash)
      servers_hash.compact.map do |server_params|
        server = create_server_from_hash(server_params)
        add_server_properties(server_params, server)
        server
      end
    end

    def create_server_from_hash(server_hash)
      server_params = build_server_params(server_hash)
      server = Server.find_or_initialize_by_name(server_hash['name'])
      server.update_attributes!(server_params)
      server
    end

    def build_server_params(server_hash)
      server_params = {}
      server_hash.each do |key, value|
        if key_is_a_server_attribute?(key)
          server_params[key] = value
        end
      end
      server_params
    end

    def key_is_a_server_attribute?(key)
      %w(ip_address dns os_platform name active).include?(key)
    end

    def add_server_properties(server_params, server)
      if server_params['properties']
        create_props_for_server(server_params['properties'], server)
      end
      if server_params['current_property_values']
        update_current_prop_values(server_params['current_property_values'], server)
      end
    end

    def create_props_for_server(props_params, server)
      props_params.each do |prop_params|
        prop = Property.find_or_initialize_by_name(prop_params['name'])
        prop_params['server_ids'] = (prop.server_ids + [server.id]).uniq
        prop.update_attributes!(prop_params)
      end
    end

    def update_current_prop_values(prop_vals, server)
      prop_vals.each do |prop_val|
        Property.find_by_name(prop_val['name']).update_value_for_object(server, prop_val['value'],prop_val['locked'])
      end
    end
end
class RouteGateImport

  def initialize(route_gates_hash, route)
    @route = route
    @route_gates_hash = route_gates_hash || {}
    @route_gates = route_gates
  end

  private

  def route_gates
    @route_gates_hash.map do |route_gate_params|
      build_route_gate_from_params(route_gate_params)
    end
  end

  def build_route_gate_from_params(route_gate_params)
    route_gate_params['route_id'] = @route.id
    route_gate_params['environment_id'] = get_route_gate_envid_from_params(route_gate_params['environment'])
    route_gate_params.delete('environment')
    RouteGate.create!(route_gate_params)
  end

  def get_route_gate_envid_from_params(env_hash)
    env = Environment.find_by_name(env_hash['name'])
    env.id
  end

end
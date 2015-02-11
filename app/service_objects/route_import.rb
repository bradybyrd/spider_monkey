class RouteImport

  def initialize(routes_hash, app)
    @app = app
    @routes_hash  = routes_hash || {}
    @routes = routes
  end

  private

  def routes
    @routes_hash.map do |route_params|
      if route_params['name'] != '[default]'
        route = build_route_from_params(route_params)
        route.route_gates.delete_all
        RouteGateImport.new(route_params['route_gates'], route)
      end
    end.compact
  end

  def build_route_from_params(route_params)
    route = Route.find_or_initialize_by_name_and_app_id(route_params['name'], @app.id)
    route.description = route_params['description']
    route.route_type = route_params['route_type']
    route.save!
    route
  end

end
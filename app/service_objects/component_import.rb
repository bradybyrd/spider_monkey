class ComponentImport

  def initialize(components_hash, app)
    @components_hash = components_hash
    @app = app
    @components = components
  end

  private

  def components
    @components_hash.each do |component|
      comp = Component.find_or_initialize_by_name(component['name'])
      comp.active = true
      comp.save!
      app_component = add_component_to_app(comp)
      add_component_properties(app_component, component['active_properties'] || [])
      comp
    end
  end

  def add_component_to_app(comp)
    if @app.component_ids.include?(comp.id)
      ApplicationComponent.by_application_and_component_names(@app.name,comp.name).first
    else
      @app.application_components.create!(component_id: comp.id)
    end
  end

  def add_component_properties(app_component, properties)
    properties.each do |property|
      prop = create_property_from_hash(property)
      add_property_to_component(prop, app_component)
    end
  end

  def add_property_to_component(prop, app_component)
    if prop.present?
      pcids = prop.component_ids
      pcids << app_component.component.id unless pcids.include?(app_component.component.id)
      prop.update_attributes!({component_ids: pcids})
    end
  end

  def create_property_from_hash(property)
    if property.present?
      prop = Property.find_or_initialize_by_name(property['name'])
      prop.default_value = property['default_value']
      prop.active = property['active']
      prop.is_private = property['is_private']
      prop.save!
      prop
    end
  end
end
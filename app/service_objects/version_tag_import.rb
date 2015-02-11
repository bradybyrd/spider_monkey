class VersionTagImport

  def initialize(version_tags_hash, app)
    @app = app
    @version_tags = import_version_tags(version_tags_hash.compact || []) || []
  end

  def self.version_tag_id_from_hash(xml_hash)
    if xml_hash['component_version']
      name = xml_hash['component_version']
      versiontag = VersionTag.find_by_name name.to_s
      if versiontag.nil?
        name
      else
        versiontag.id
      end
    end
  end

  private

  def import_version_tags(version_tags_hash)
    version_tags_hash.map do |version_tag_hash|
      import_version_tag(version_tag_hash)
    end
  end

  def import_version_tag(version_tag_hash)
    version_tag = VersionTag.find_or_initialize_by_name(version_tag_hash['name'])
    version_tag_params = build_version_tag_params(version_tag_hash)
    version_tag.attributes = version_tag_params
    version_tag.save validate: false
    version_tag
  end

  def generic_version_tag_params(version_tag_hash)
    {
        not_from_rest: true,
        name: version_tag_hash['name'],
        artifact_url: version_tag_hash['artifact_url'],
        app_id: @app.id,
        app_env_id: get_app_env_id_from_hash(version_tag_hash['environment_name'])
    }
  end

  def build_version_tag_params(version_tag_hash)
    if version_tag_hash['component_name'].present?
      add_installed_component_id_to_params(generic_version_tag_params(version_tag_hash), version_tag_hash['component_name'])
    else
      generic_version_tag_params(version_tag_hash)
    end
  end

  def get_app_env_id_from_hash(environment_name)
    environment = Environment.find_by_name(environment_name)
    if environment.present?
      @application_environment = ApplicationEnvironment.find_by_app_id_and_environment_id(@app.id, environment.id)
      @application_environment.id
    end
  end

  def add_installed_component_id_to_params(version_tag_params, component_name)
    component = Component.find_by_name component_name
    @application_component = ApplicationComponent.find_by_app_id_and_component_id(@app.id, component.id)
    version_tag_params[:installed_component_id] = installed_component.id
    version_tag_params[:app_env_id] = nil
    version_tag_params
  end

  def installed_component
    InstalledComponent.where(application_component_id: @application_component.id,
                             application_environment_id: @application_environment.id).first
  end

end

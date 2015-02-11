class AppHash

  attr_reader :imported_hash

  def initialize(file_contents)
    begin
      hash = create_imported_hash(file_contents)
    rescue => e
      Rails.logger.error('ERROR Application Import: ' + e.message + "\n" + e.backtrace.join("\n"))
      raise 'Invalid file provided. Check log for more information.'
    end
    @imported_hash = remove_top_key(hash)
  end

  def components
    @imported_hash['components'] || []
  end

  def environments
    @imported_hash['environments'] || []
  end

  def installed_components
    @imported_hash['installed_components'] || []
  end

  def requests
    @imported_hash['requests_for_export'] || @imported_hash['requests_for_export_with_automations'] || []
  end

  def routes
    @imported_hash['active_routes'] || []
  end

  def packages
    @imported_hash['active_packages'] || []
  end

  def application_packages
    @imported_hash['application_packages'] || []
  end


  def version_tags
    @imported_hash['version_tags'] || []
  end

  def processes
    @imported_hash['active_business_processes'] || {}
  end

  def procedures
    @imported_hash['active_procedures'] || []
  end

  def app_params
    application_params = {}
    @imported_hash.each { |key, val|
      if key_is_an_app_attribute?(key)
        application_params[key] = val
      end
    }
    application_params
  end

  private

  def key_is_an_app_attribute?(key)
    %w(a_sorting_comps a_sorting_envs active app_version name strict_plan_control).include?(key)
  end

  def create_imported_hash(file_content)
    raise 'Implement me'
  end

  def remove_top_key(imported_hash)
    if imported_hash.has_key?('hash')
      imported_hash['hash']
    elsif imported_hash.has_key?('app')
      imported_hash['app']
    else
      raise 'Provided file has invalid format'
    end
  end

end
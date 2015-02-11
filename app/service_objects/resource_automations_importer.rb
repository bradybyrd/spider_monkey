class ResourceAutomationsImporter
  class ImportError < StandardError; end

  def initialize(steps_hash)
    @steps_hash = steps_hash
  end

  def import
    import_resource_automation_scripts
  end

  private

  attr_reader :steps_hash

  def import_resource_automation_script(xml_hash)
    if xml_hash['resource_automation_script']
      attributes = AppImport::ResourceAutomationAttributes.new(xml_hash['resource_automation_script'])
      attributes.import_app_request
    end
  end

  def import_resource_automation_scripts
    if steps_hash['steps'].present?
      steps_hash['steps'].each do |xml_hash|
        import_resource_automation_script(xml_hash)
      end
    end
  end

end

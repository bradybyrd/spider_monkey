class V1::VersionTagsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :version_tags

  # call super with a list of safe fields
  # def as_json( options = nil )
    # super( {:only => safe_attributes }.merge(options) )
  # end
# 
  # # call super with a list of safe fields
  # def to_xml( options = {})
    # super( default_options.merge(options) )
  # end
  
  # # underlying logic for assembling the correct serialized hash
  # def custom_hash
  # data_hash = {
      # :id => version_tag.id,
      # :name => version_tag.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def version
    # Api::V1::ResourcePresenter.new( version.versions ).as_json( false )
  # end
  
  private
  
  def resource_options
    return { :only => safe_attributes,
      :methods => [:application_name, :component_name, :environment_name] }
  end
  
  def safe_attributes
    return [:id, :name, :app_id, :installed_component_id, :artifact_url, :archive_number, :archived_at, :created_at, :updated_at]
  end

end
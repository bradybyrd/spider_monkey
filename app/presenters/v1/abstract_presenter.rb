################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::AbstractPresenter

  attr_reader :resource, :export_xml, :export_app, :optional_components

  def initialize( resource, template = nil, options = {} )
    @template = template
    @resource = resource
    @export_xml = options.has_key?(:export_xml)
    @export_app = options.has_key?(:export_app) || @export_xml
    @optional_components = options[:optional_components] || []
    @include_except = options[:include_except] || []
    @alone = options[:alone] == true
  end

  def alone?
    @alone
  end

  def self.presents(name)
    define_method(name) do
      @resource
    end
  end

  # by default, presenters will pass along the default methods for json
  def as_json( options = {} )
    if @resource.kind_of?(Array)
      @resource.map { |v| v.as_json( default_options.merge(options)) }
    elsif is_app_export?
      result = @resource.as_json( default_options.merge(options.merge({root: true})) )
      result['app']['brpm_version'] = brpm_version
      result
    else
      @resource.as_json( default_options.merge(options) )
    end
  end

  # by default, presenters will pass along the default methods for XML
  def to_xml( options = {} )
    @resource.to_xml( default_options.merge(options) ) do |xml|
      xml.brpm_version brpm_version if is_app_export?
    end
  end

  def brpm_version
    ApplicationController.helpers.get_version_from_file
  end

  private

  # when given a method call (link_to, etc) this will pass it along to the
  # view so you can use link_to and other view methods in the presenter classes
  def method_missing(*args, &block)
    @template.send(*args, &block) unless @template.nil?
  end

  # default options such as including instructions or what not to be shared across
  # the entire API (can be overridden, but remember to include resource_options if you do)
  def default_options
    resource_options_hash = resource_options
    if alone?
      resource_options_hash.delete(:include)
    else
      except!(resource_options_hash) unless @include_except.empty?
    end
    { no_instruct: true }.merge(resource_options_hash)
  end

  # child options are to be overwritten by children to customize field display
  def resource_options
    {}
  end

  def except!(hash)
    @include_except.each { |exception| hash[:include].delete(exception.to_sym) }
  end
  
  def is_app_export?
    false
  end

end

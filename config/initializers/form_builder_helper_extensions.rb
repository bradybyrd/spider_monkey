################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActionView::Helpers::FormBuilder
  def date_field(field_name, html_options = {}, delivery_date = false, delivered_date = false)
    classes = html_options.delete(:class) || ''
    
    if delivery_date == true  && delivered_date == false
      classes << ' delivery'
    elsif delivery_date == false && delivered_date == true
      classes << ' delivered'
    else
      classes << ' date'
    end
    
    unless html_options[:value].blank?
      default_format_date = GlobalSettings[:default_date_format].split(' ')
      html_options[:value] = html_options[:value].to_date.strftime(default_format_date[0])
    end

    inner_contents = text_field(field_name, html_options.merge(:class => classes, :style => 'float:left;')) << \
                 image('calendar_icon.gif', :style => 'float:left;')
    content = label_tag(inner_contents, :class => 'calendar')

    object = @template.instance_variable_get("@#{@object_name}")

    unless object.nil? || options[:hide_errors]
      errors = object.errors.on(field_name.to_sym)
      if errors
        content = ActionView::Base.field_error_proc.call(content)
      end
    end
    
    content
  end

  private
  def image src, opts
    "<img src=\"/images/#{src}\" #{opts_hash_to_html(opts)} />"
  end

  def label_tag contents, opts 
    "<label #{opts_hash_to_html(opts)}>#{contents}</label>"
  end

  def opts_hash_to_html hash
    hash.map {|k, v| "#{k}=\"#{v}\""}
  end
end

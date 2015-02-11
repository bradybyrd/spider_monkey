################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'colors'

module ColorizedModelHelper

  def select_label_color(colorized_model=nil)
    select_tag("#{colorized_model.class.name.underscore}[label_color]", options_with_colors(colorized_model).html_safe, :style => "background-color:#{nil_safe_color(colorized_model.try(:label_color))};", :class => 'label_color')
  end

  def options_with_colors(colorized_model)
    label_color = colorized_model ? colorized_model.label_color : ''
    Colors::Shades.collect do |color|
      "<option #{selected_color?(label_color, color[1])}  value='#{color[1]}' style='background-color:#{color[1]};'>#{color[0]}</option>"
    end.join
  end

  def selected_color?(label_color, color_code)
    label_color == color_code ? "selected='yes'" : ''
  end

  def colorized_label(label_color, label_text)
    label = []
    label << colorized_slug(nil_safe_color(label_color)) unless label_text.blank?
    label << label_text
    raw label.join
  end

  def colorized_slug(label_color)
    content_tag(:span, raw('&nbsp;'), :style => "background:#{nil_safe_color(label_color)}; width:7px; display:inline-block; margin-right: 5px; #{ color_safe_border(label_color) }")
  end

  def colorized_tag_options(label_color)
    tag_options({:style => colorized_style(label_color)}, false)
  end

  def colorized_style(label_color)
    "background: #{ nil_safe_color(label_color) } none repeat scroll 0 0; color: #{contrasting_font_color(label_color) }; #{ color_safe_border(label_color) }"
  end

  def colorized_label_tag_options(label_color)
    tag_options({:style => "color: #{nil_safe_color(label_color)}; font-weight: bold;"}, false)
  end

  def nil_safe_color(label_color)
    label_color.blank? ? '#FFFFFF' : label_color
  end

  def contrasting_font_color(label_color)
    case
      when label_color.blank?
        '#FF0000'
      when light_colors.include?(label_color)
        '#000000'
      else
        '#FFFFFF'
    end
  end

  def color_safe_border(label_color)
    case
      when label_color.blank?
        'border: 1px dotted #FF0000;'
      when light_colors.include?(label_color)
        'border: 1px solid #ccc;'
      else
        "border: 1px solid #{ label_color };"
    end
  end

  def light_colors
    %w(#FFFFFF #FAEBD7 #F0F8FF #FAEBD7 #F0FFFF #F5F5DC #FFF8DC #FFFAF0 #DCDCDC #F8F8FF #F0FFF0 #E6E6FA #FFF0F5 #FFFACD #FAFAD2 #FFFFE0 #FAF0E6 #F5FFFA #FDF5E6 #FFEFD5 #FFF5EE #FFFAFA #F5F5F5)
  end


end

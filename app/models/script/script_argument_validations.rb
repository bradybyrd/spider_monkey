################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'jruby-parser'


class Script < ActiveRecord::Base

  SUPPORTED_ARGUMENT_PARAMETERS = ["name", "description", "private", "position", "type", "required", "external_resource", "list_pairs"]

  validate :argument_syntax_validation
  validate :script_syntax_validation
  validate :check_argument_syntax

  private

  def argument_syntax_validation
    check_content
    if @content_changed
      begin
        # This logic will check for any syntax errors
        input_argument_position = {}
        output_argument_position = {}
        argument_position = {}
        argument_external_resource = []
          pa = parsed_arguments
        if pa.present? && ( pa.values.include?(nil) || self.content.match(argument_regex).nil? )
          self.errors[:base] << "Argument parsing error."
        end
        if self.automation_type == "ResourceAutomation"
          # TODO: make sure this validation works with # present before def execute
          if self.content.match('def execute\(script_params, parent_id, offset, max_records\)').nil?
            self.errors[:base] << "Script must contain <u>def execute(script_params, parent_id, offset, max_records)</u> block.".html_safe
          end
        end

        pa.each do |argument_name, val|

          if val.is_a?(Hash)
            if Script::SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES.include?(val['type'])
              output_argument_position[argument_name] = val["position"] if val["position"].present?
            else
              input_argument_position[argument_name] = val["position"] if val["position"].present?
            end
            argument_external_resource << val["external_resource"] if val["external_resource"].present?

            unless val.keys.include?("name")
              unless val.keys.include?("description")
                self.errors[:base] << "Argument #{argument_name} must contain name."
              end
            end

            if val.keys.include?("external_resource")
              if val["external_resource"].present?
                external_rescource_script = Script.find_by_unique_identifier(val["external_resource"])
                self.errors[:base] << "external_resource parameter present under argument <u>#{pa.key(val)}</u> does not contain a valid Resource Automation script.".html_safe unless external_rescource_script
                if external_rescource_script.present? && external_rescource_script.arguments.present?
                  external_rescource_script.arguments.each do |argument|
                    unless pa.keys.include?(argument.argument)
                      self.errors[:base] << "Resource automation script <u>#{val["external_resource"]}</u> associated with argument <u>#{pa.key(val)}</u> contains some additional arguments which are not present under current script.".html_safe
                    end
                  end
                end
              end
              if !( val.keys.include?("type") && ( ["in-external-single-select", "in-external-multi-select", "out-external-multi", "out-external-single"].include?(val["type"]) ))
                self.errors[:base] << "Argument <u>#{pa.key(val)}</u> must contain valid type.".html_safe
              end
            end

            if val.keys.include?("type") && val["type"].include?("external")
              self.errors[:base] << "Argument <u>#{pa.key(val)}</u> must contain external_resource parameter.".html_safe unless val.keys.include?("external_resource")
            end

            if val.keys.include?("type") && !val.keys.include?("external_resource") &&!( val.keys.include?("type") && Script::SUPPORTED_DATA_TYPES.include?(val["type"]) )
              self.errors[:base] << "Argument <u>#{pa.key(val)}</u> must contain valid type.".html_safe
            end

            if val.keys.include?("type") && ( val["type"] == "in-list-single" ||  val["type"] == "in-list-multi" )
              if val["list_pairs"].blank?
                self.errors[:base] << "Argument <u>#{pa.key(val)}</u> must contain valid list_pairs.".html_safe
              elsif (val["list_pairs"] =~ /^(?:[a-z0-9]+,([^|,]+)(?:\||$))+$/i) == nil
                self.errors[:base] << "Argument <u>#{pa.key(val)}</u> must contain valid list_pairs(e.g 1,a|2,b|3,c)".html_safe
              end
            end

            if val.keys.include?("required")
              unless (val["required"] == true || val["required"] == false)
                self.errors[:base] << "Argument <u>#{argument_name}</u> must contain valid required type(e.g yes or no)".html_safe
              end
            end

            if val.keys.present?
              val.keys.each do |parameter|
                unless SUPPORTED_ARGUMENT_PARAMETERS.include?(parameter)
                  self.errors[:base] << "Argument <u>#{argument_name}</u> must contain valid parameters(e.g #{SUPPORTED_ARGUMENT_PARAMETERS.join(', ')})".html_safe
                end
              end
            end
          else
            self.errors[:base] << "Argument parsing error."
          end
        end

        argument_position = input_argument_position.merge(output_argument_position)

        parsed_arguments.keys.each do |argument|
          if argument_position.present?
            unless argument_position[argument].present?
              self.errors[:base] << "Position must be present for argument <u>#{argument}</u>.".html_safe
            end
          end
        end

        # This condition will check for duplicate argument names used in the script
        if pa && pa.keys.size > 1 && pa.keys.uniq.size == 1
          self.errors[:base] << "Argument name must be unique for the script."
        end

        # This condition will check of multiple input arguments which are having the same position
        if input_argument_position.present? && (input_argument_position.values.uniq.length != input_argument_position.values.length)
          self.errors[:base] << "Position must be unique across all input arguments."
        end

        # This condition will check of multiple output arguments which are having the same position
        if output_argument_position.present? && (output_argument_position.values.uniq.length != output_argument_position.values.length)
          self.errors[:base] << "Position must be unique across all output arguments."
        end

        # if argument_external_resource.present? && argument_external_resource.size > 1 && argument_external_resource.uniq.size == 1
        #   self.errors[:base] << "External Resource must be unique across all the arguments."
        # end

        if argument_position.present?
          argument_position.each do |argument_name, position|
            unless position_validator(position)
              self.errors[:base] << "Position present under argument <u>#{argument_name}</u> is invalid.".html_safe
            end
            left_position, right_position = position.split(":")
            acceptable_position_values = ["A", "B", "C", "D", "E", "F"]

            if !acceptable_position_values.include?(left_position.gsub(/\d/,'')) || !acceptable_position_values.include?(right_position.gsub(/\d/,''))
              self.errors[:base] << "Position present under argument <u>#{argument_name}</u> is invalid.".html_safe
            end

            if left_position.gsub(/\d/,'') == right_position.gsub(/\d/,'')
              self.errors[:base] << "Position present under argument <u>#{argument_name}</u> is invalid.".html_safe
            end

            if (left_position.try(:length) == 2 && left_position.match("0")) || (right_position.try(:length) == 2 && right_position.match("0") )
              self.errors[:base] << "Position present under argument <u>#{argument_name}</u> is invalid.".html_safe
            end
          end
        end

      rescue Exception => err
        self.errors[:base] << "Argument parsing error : #{err.message}"
      end
    end
  end

  def script_syntax_validation
    begin
      #script_file = File.new("#{Rails.root}/#{self.name}.rb", "w+")
      #script_file.print(content)
      #script_file.close

      #script = File.open("#{Rails.root}/#{self.name}.rb", "r").read
      begin
        JRubyParser.parse(content)
      rescue org.jrubyparser.lexer.SyntaxException => e
        self.errors[:base] << "#{e.cause.message} on line number <span class='error_line_number'>#{e.cause.position.start_line.to_i + 1}</span>".html_safe
      end

      # command = "#{RUBY_PATH} -c '#{File.absolute_path(script_file)}'"
      # test_output = `#{command} 2>&1`
      # if test_output.match("Syntax OK") == nil
      #   self.errors[:base] << "#{test_output}"
      # end
      #File.delete("#{script_file.path}")
    rescue Exception => err
      self.errors[:base] << "Error in script content : #{err.message}."
    end
  end

  # def position_validator(str)
  #     /^([A-F])(\d):([A-Z])(\d)$/.match(str) && $1 < $3 && $2 < $4
  # end

  def position_validator(str)
    a,b = str.split(":")
    !(/([A-F])\d/ =~ a).nil? && !(/[#{$1}-Z]\d/ =~ b).nil?
  end

  def check_argument_syntax
    return if self.content.blank?
    arg_string = self.content && self.content.match(argument_regex)
    if arg_string.blank? && self.arguments.present?
      self.errors[:base] << "Arguments are not enclosed in triple-quoted comment(###)."
    end
  end

end

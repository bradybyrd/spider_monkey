################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'open-uri'

class Step < ActiveRecord::Base

  validate :validate_presence_of_script_arguments

  validate :validate_primitive_script_arguments

  private

  # This validates the presence of mandatory script arguments
  def validate_presence_of_script_arguments
    return true if script_type == "BladelogicScript"
    if script && script.arguments.present?
      script.arguments.each do |argument|
        unless Script::SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES.include?(argument.argument_type)
          if argument.is_required? && !selected_step_arguments.nil? && !selected_step_arguments.keys.include?(argument.id.to_s)
            if StepScriptArgument.find_by_step_id_and_script_argument_id(id, argument.id).try(:value).nil?
              self.errors[:base] << "Script argument <u>#{argument.argument}</u> must contain value.".html_safe
            end
          end
        end
      end
    end
  end

  def validate_primitive_script_arguments
    return true if script_type == "BladelogicScript"
    if selected_step_arguments.present?
      selected_step_arguments.each do |argument_id, argument_value|
        new_val = argument_value.first
        arg = ScriptArgument.find(argument_id)
        if new_val.present? && !Script::SUPPORTED_AUTOMATION_OUTPUT_DATA_TYPES.include?(arg.argument_type)
          case arg.argument_type
          when "in-int"
            decimal_match = /^(\+\d)*(\-\d)*\d+?$/
            if !decimal_match.match(new_val)
              self.errors[:base] << "Script argument <u>#{arg.argument}</u> must contain valid numeric value.".html_safe
            end
          # when "in-text"
          #   if new_val.to_i != 0
          #     self.errors[:base] << "script argument <u>#{arg.argument}</u> must contain valid text value".html_safe
          #   end
          when "in-decimal"
            decimal_match = /^(\+\d)*(\-\d)*\d*(\.\d+)?$/#/[0-9]\.[0-9]/
            if !decimal_match.match(new_val)
              self.errors[:base] << "Script argument <u>#{arg.argument}</u> must contain valid decimal value.".html_safe
            end
          when "in-email"
            email_match = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
            if email_match.match(new_val).nil?
              self.errors[:base] << "<u>#{arg.argument}</u> is invalid email address.".html_safe
            end
          when "in-url"
            begin
              open(new_val, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
            rescue Exception => err
              self.errors[:base] << "Script argument <u>#{arg.argument}</u> must contain accessible URL.".html_safe
            end
          when "in-date"
          when "in-time"
          else
          end
        end
      end
    end
  end

end

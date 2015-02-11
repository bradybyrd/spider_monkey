################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ExposedTime
  
  def self.included(target)
    target.extend ClassMethods
  end
  
  module ClassMethods
    def expose_time_for_selector(*args)
      args.each do |field|
        
        attr_writer "#{field}_hour", "#{field}_minute", "#{field}_meridian", "#{field}_date"
        
        define_method("#{field}_date") do
          field_value = self.send(field)
          field_value.nil? ? '' : field_value.to_date.to_s(:simple)
        end
      
        define_method("#{field}_hour") do
          field_value = self.send(field)
          field_value_hour = field_value.nil? ? '' : field_value.hour
          
          final_value = case field_value_hour
                        when 0 then 12
                        when (13..23) then (field_value_hour - 12)
                        else
                          field_value_hour
                        end

          final_value.to_s.rjust(2,'0')
        end
      
        define_method("#{field}_minute") do
          field_value = self.send(field)
          field_value.nil? ? '' : field_value.min.to_s.rjust(2,'0')
        end
      
        define_method("#{field}_meridian") do
          field_value = self.send(field)
          field_value.nil? ? '' : (field_value.hour >= 12 ? 'PM' : 'AM')
        end
        
        define_method("#{field}_as_string") do
          
          date_field = self.instance_variable_get("@#{field}_date").to_s
          hour_field = self.instance_variable_get("@#{field}_hour").to_s
          minute_field = self.instance_variable_get("@#{field}_minute").to_s
          meridian_field = self.instance_variable_get("@#{field}_meridian").to_s
          
          unless date_field.empty?
            hour_field = '12' if hour_field.empty?
            meridian_field = 'AM' if meridian_field.empty?
            minute_field = '00' if minute_field.empty?
          end

          "#{date_field} #{hour_field}:#{minute_field} #{meridian_field}"
        end
        
        define_method("stitch_together_#{field}") do
          parsed_time = self.send("#{field}_as_string")
          if parsed_time.blank? || parsed_time.strip == ':'
            parsed_time = nil
          else
            parsed_time = Time.zone.parse(parsed_time)
          end
          self.send("#{field}=", parsed_time)
        end
        
      end
    end

    def reformat_date(date_string)
      return if date_string.nil?
      month = "1"
      day = "1"
      year = "1900"
      #logger.info "SS__ StartDate: #{date_string}"
      match = date_string.gsub("-","/").split("/")
      month_numbers = {"Jan" => "1", "Feb" => "2", "Mar" => "3", "Apr" => "4", "May" => "5", "Jun" => "6",
        "Jul" => "7", "Aug" => "8", "Sep" => "9", "Oct" => "10", "Nov" => "11", "Dec" => "12"}
      format_codes = GlobalSettings[:default_date_format].gsub("-","/").gsub(" ", "/").split("/")
      format_codes.each_with_index do |fmt, idx|
        #logger.info "SS__ #{fmt} => #{match[idx]}"
        case fmt.downcase
          when '%m'
            month = match[idx]
          when '%d'
            day = match[idx]
          when '%y'
            year = match[idx]
          when '%b'
            month = month_numbers[match[idx]]
        end
      end
      "#{month}/#{day}/#{year}"
    end

  end
  
  
  
end

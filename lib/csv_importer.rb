################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'csv'

class CSVImporter

  FIRST_TAB_COLUMN = 8
  CREATE_COLUMN    = 6
  INDEX_COLUMN     = 7

  def self.import(template)

    filename = template
    filename = "#{filename}.csv" unless filename =~ /\.\w+$/
    filename = File.join('data', 'csv', filename) unless File.exist? filename
    begin
      csv = File.open(filename)
    rescue Errno::ENOENT => e
      print_and_exit e
    end

    ActiveRecord::Base.transaction do
      lines = CSV.parse(csv)

      category_name = lines.first[1]
      phase_names = lines[1][1].split(';').map &:strip
      puts "Creating: #{category_name}"
      category = ActivityCategory.find_or_initialize_by_name(category_name)
      category.update_attributes!(:request_compatible => false)
      phase_names.each do |phase|
        category.activity_phases.find_or_create_by_name(phase)
      end
      category.activity_phases.each do |phase|
        phase.destroy unless phase_names.include? phase.name
      end

      tabs = lines[2][FIRST_TAB_COLUMN..-1]
      content = lines[3..-1]

      tabs.each_with_index do |name, idx|
        tab_col = FIRST_TAB_COLUMN + idx

        read_only = name.ends_with? ':ro'
        name = name.split(':').first

        tab = category.activity_tabs.find_or_initialize_by_name(name.strip)
        tab.read_only = read_only
        tab.insert_at idx + 1

        # Columns:
        #  0 - Field Type (custom, static, widget)
        #  1 - Name
        #  2 - Field (for static)
        #  3 - Input Type (for custom and static)
        #  4 - Values (for selects)
        #  5 - Elemental? (for selects)
        #  6 - Create screen order and optional disabled
        #  7 - Index
        #  8 - General tab
        #  9 - Requests tab
        # 10 - Notes tab
        content.reject { |c| c[tab_col].blank? }.sort_by { |c| c[tab_col].to_i }.each_with_index do |row, idx|
          attr_type = case row[0]
                        when 'widget' then 'ActivityWidget'
                        when 'custom', 'static' then "Activity#{row[0].camelize :upper}Attribute"
                      end

          attr_name        = row[1].try(:strip)
          attr_field       = row[2].try(:strip)
          attr_required    = row[3].to_s.ends_with?(':r')
          attr_input_type  = row[3].to_s.split(':').first.try(:strip)
          attr_values      = (row[4] || '').split(';').map(&:strip)
          attr_from_system = row[5].present?
          attr_disabled    = row[tab_col].ends_with? ':d'

          log attr_name, "#{tab.name} tab" do
            attr = ActivityAttribute.find_or_initialize_by_name(attr_name)
            attr = attr.becomes(attr_type.constantize)
            attr.type = attr_type
            attr.update_attributes!(:field => attr_field, :required => attr_required,
                                    :input_type => attr_input_type, :attribute_values => attr_values,
                                    :from_system => attr_from_system)

            tab.activity_attributes << attr unless tab.activity_attributes.include? attr
            tab.activity_tab_attributes.find_by_activity_attribute_id(attr.id).insert_at(idx + 1)

            if attr_disabled
              attr.disable_on tab
            else
              attr.enable_on tab
            end
          end
        end
      end

      # Creation attributes
      content.reject { |c| c[CREATE_COLUMN].blank? }.sort_by { |c| c[CREATE_COLUMN].to_i }.each_with_index do |row, idx|
        attr_name     = row[1].try(:strip)
        attr_disabled = row[CREATE_COLUMN].ends_with? ':d'

        log attr_name, 'create screen' do
          creation_attr = category.creation_attributes.find_or_initialize_by_activity_attribute_id(ActivityAttribute.find_by_name(attr_name).id)
          creation_attr.update_attributes!(:disabled => attr_disabled)
          creation_attr.insert_at idx + 1
        end
      end

      # Clear removed attributes
      attr_names = content.map { |c| c[1] }
      category.activity_tabs.each do |tab|
        tab.activity_attributes.reject { |attr| attr_names.include? attr.name }.each(&:destroy)
      end
    end
  end

  private

  def self.print_and_exit(message, err_code = 1)
    print "#{message}\n"
    $stdout.flush
    exit err_code
  end

  def self.log(attr_name, tab_name)
    print "Adding #{attr_name} to #{tab_name}... "
    begin
      yield
    rescue => e
      print_and_exit "FAILED!\n\n#{e}"
    end
    print "Done.\n"
  end

end

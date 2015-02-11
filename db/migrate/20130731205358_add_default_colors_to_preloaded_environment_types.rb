class AddDefaultColorsToPreloadedEnvironmentTypes < ActiveRecord::Migration
  def self.up


    list_items = %w(Generic Development Testing Production)
    default_colors = {'Generic' => '#A9A9A9',
                      'Development' => '#228B22',
                      'Testing' => '#FFD700',
                      'Production' => '#FF0000'}

    puts 'Setting default colors for default environment types...'

    begin

      # grab all of the existing applications that are named the default names and still have the default color
      environment_types = EnvironmentType.where("environment_types.name in (?) AND environment_types.label_color = '#C7A465'", list_items)

      # assign a preselected color so these line up in a standard green for dev, red for prod order
      environment_types.each do |et|
        unless default_colors[et.name].blank?
          success = et.update_attributes(:label_color => default_colors[et.name])
          print (success ? '.' : 'x')
          unless success
            "\nEnvironment type failed to save: #{ et.name } - #{ et.errors.full_messages }"
          end
        end
      end

    rescue => e
      puts "There was an error setting the default colors: #{ e.message }"
      puts e.backtrace.join("\n")
    else
      puts "\nDefault colors set for #{ environment_types.length } environment types."
    end

  end

  def self.down
    list_items = %w(Generic Development Testing Production)
    default_colors = {'Generic' => '#C7A465',
                      'Development' => '#C7A465',
                      'Testing' => '#C7A465',
                      'Production' => '#C7A465'}

    puts 'Resetting original colors for default environment types...'

    begin

      # grab all of the existing applications that are named the default names and still have the default color
      environment_types = EnvironmentType.where("environment_types.name in (?) AND environment_types.label_color <> '#C7A465'", list_items)

      # assign a preselected color so these line up in a standard green for dev, red for prod order
      environment_types.each do |et|
        unless default_colors[et.name].blank?
          success = et.update_attributes(:label_color => default_colors[et.name])
          print (success ? '.' : 'x')
          unless success
            "\nEnvironment type failed to save: #{ et.name } - #{ et.errors.full_messages }"
          end
        end
      end

    rescue => e
      puts "There was an error setting the default colors: #{ e.message }"
      puts e.backtrace.join("\n")
    else
      puts "\nOriginal colors set for #{ environment_types.length } environment types."
    end
  end
end

namespace :scripts do
  namespace :automation do
    desc 'Updates BMC Application Automation 8.2 scripts'
    task baa_update: :environment do
      update_script_content('BMC Application Automation 8.2')
    end

    desc 'Updates RLM Deployment Engine scripts'
    task rlm_update: :environment do
      update_script_content('RLM Deployment Engine')
    end

    desc 'Updates BMC Remedy 7.6.x scripts'
    task remedy_update: :environment do
      update_script_content('BMC Remedy 7.6.x')
    end
  end

  private
    def execution_confirmed?(input = false)
      unless input
        puts 'You are going to update scripts to default. All your changes will be overwritten.'
        print 'Do you want to proceed? (y/n): '
      end

      input = STDIN.gets.chomp
      case input.downcase
      when 'yes', 'y'
        true
      when 'no', 'n'
        false
      else
        print 'Please enter Yes(Y) or No(N): '
        execution_confirmed?(input)
      end
    end

    def update_script_content(automation_category)
      return puts('Good Bye.') unless execution_confirmed?

      Dir.glob(File.join(AutomationCommon::DEFAULT_AUTOMATION_SCRIPT_LIBRARY_PATH, 'automation', automation_category, '*.rb')).each do |file_path|
        file_name = file_path.split('/').last.gsub(/\.rb/, '').humanize
        script = Script.where(name: file_name).first
        if script
          new_content = script.project_server.add_update_integration_values(File.read(file_path), true)
          if script.update_attributes(content: new_content)
            puts "Script: #{file_name} updated successfully"
          else
            puts "Script #{file_name} update failed with errors: #{script.errors.full_messages.join(', ')}"
          end
        end
      end
    end
end

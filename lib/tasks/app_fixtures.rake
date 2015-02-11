require 'active_record/fixtures'

def load_custom_fixtures_from(dir)
  require 'active_record/fixtures'
  ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(Rails.root, 'data', dir, '*.{yml,csv}'))).each do |fixture_file|
    begin
    puts "Loading fixtures from #{fixture_file}..."
    ActiveRecord::Fixtures.create_fixtures("data/#{dir}", File.basename(fixture_file, '.*'))
    rescue Exception => e
      puts '-----------------------'
      puts e.message
      puts 'Just ignore it.. This table is not used any more...'
      puts '-----------------------'
    end
  end
end

def generate_default_scripts_from(dir)
  full_path = Dir["#{Rails.root}/data/#{dir}/default_scripts/*.{jy,py,rb}"]
  
  unless full_path.empty?
    BladelogicScript.delete_all
    BladelogicScriptArgument.delete_all
    CapistranoScript.delete_all
    CapistranoScriptArgument.delete_all

    full_path.each do |script_file|
      script_type = script_file.ends_with?('.rb') ? "Capistrano" : "Bladelogic"
      puts "Generating #{script_type} script from #{script_file}..."

      script = "#{script_type}Script".constantize.new

      script.name = File.basename(script_file).gsub(/\..*/, '').humanize
      script.authentication = 'default' if script_type == 'Bladelogic'

      File.open(script_file) { |file| script.content = file.read }

      script.save!
    end
  end
end

def copy_default_logo_from(dir)
  files = Dir["#{Rails.root}/data/#{dir}/default_logos/*"]

  files.each do |file|
    puts "Copying logo #{File.basename(file)}..."
    File.makedirs "#{Rails.root}/public/images/logos/default_logo"
    FileUtils.cp(file, "#{Rails.root}/public/images/logos/default_logo/")
    GlobalSettings['default_logo'] = "logos/default_logo/#{File.basename(file)}"
  end
end

namespace :app do
  namespace :fixtures do

    Dir["#{Rails.root}/data/*"].each do |directory|
      directory = File.basename(directory)
      desc "Load fixtures from data/#{directory}"
      task directory => :environment do
        load_custom_fixtures_from directory
        copy_default_logo_from directory
      end

      namespace directory do
        desc "Load fixtures from data/#{directory} with fresh scripts"
        task :new_scripts => :environment do
          load_custom_fixtures_from directory
          generate_default_scripts_from directory
          copy_default_logo_from directory
        end
      end
    end

  end
end

require 'rake'
require 'fileutils'
require 'yaml'

RAILS_ROOT = File.expand_path(__FILE__).gsub(File.join("lib","tasks","app_plugins.rake"),"").chomp("/")
puts "RAILS_ROOT=#{RAILS_ROOT}"

def show_help
help_info =<<-END
#--------- BRPM Plugin Help -----------#
#=> In order to work with plugins, the variable PLUGIN_LOCATION
needs to be defined - to do this, run:
   jruby -S rake app:plugins_setup PLUGIN_LOCATION='opt/bmc/rlm/persist/plugins'
This will create a config file to hold the value in BRPM

#=> To load plugins, run this:
jruby -S rake app:load_plugins
This will load all plugins in the plugins directory

#=> To load a single plug-in enter the command like this:
jruby -S rake app:load_plugins PLUGIN=config

#=> Suported actions:
  app:plugins_setup
  app:plugins_load
  app:plugins_remove
  app:plugins_help (this info)
END
  puts help_info
end

def build_plugin_initializer(plugin_location)
  code_to_add =<<-END
    PLUGIN_LOCATION = "#{plugin_location.gsub("'","")}"
    # Registered plugins
    PLUGINS_REGISTERED = {
    "__REPLACE" => "",
    "__NONE" => ""
    }
    END
  unless File.exist?(plugin_location)
    puts "ERROR: Invalid path: #{plugin_location}"
    exit(1)
  end
  puts "#=> Creating config/initializers/plugin.rb"
  plugin_init = File.join(RAILS_ROOT,"config","initializers","brpm_plugin.rb")
  unless File.exist?(plugin_init)
   fil = File.open(plugin_init, "w+")
   fil.puts code_to_add
   fil.close
  else
    puts "Plugin initializer already exists"
  end
end

def register_plugin(plugin, plugin_route, register = true)
  puts "#=> #{register ? "R" : "Unr"}egistering Plugin: #{plugin}"
  replace_line = "\"__REPLACE\" => \"\","
  plugin_initializer = File.join(RAILS_ROOT,"config","initializers","brpm_plugin.rb")
  if File.exist?(plugin_initializer)
    contents = File.open(plugin_initializer).read
    unless contents.include?(plugin_initializer)
      if register
        contents.gsub!(replace_line, "\"#{plugin}\" => \"#{plugin_route}\",\n#{replace_line}")
      else
        contents.gsub!("\"#{plugin}\",\n", "")
      end
      fil = File.open(plugin_initializer, "w+")
      fil.puts contents
      fil.close
    end
  end
end

def modify_routes(plugin)
  # Important - this should be the last action line in the routes file
  insert_line = "sessions#bad_route"
  code_to_add =<<-END
  # Plugin Routes
  # Register Plugin Routes
  if File.exist?(File.join(Rails.root,"config/initializers/brpm_plugin.rb"))
    require File.join(Rails.root,"config/initializers/brpm_plugin.rb")
    if defined?(PLUGIN_LOCATION) && File.exist?(PLUGIN_LOCATION)
      if defined?(PLUGINS_REGISTERED)
        PLUGINS_REGISTERED.reject{|k| k.start_with?("__") }.each do |plugin|
          next unless File.exist?(File.join(PLUGIN_LOCATION, plugin, "config", "routes.rb"))
          puts "Registering plugins: #{plugin}"
          config.paths["config/routes"] << File.join(PLUGIN_LOCATION, plugin, "config", "routes.rb")
        end
      end
    end
  end
    # /Register Plugin Routes
END
  routes = File.join(RAILS_ROOT,"config","application.rb")
  puts "#=> Modifying config/application.rb"
  FileUtils.cp routes, File.join(plugin, "orig_application.rb"), :verbose => true
  contents = File.open(routes).read
  lines = contents.lines.to_a
  ipos = 0
  #lines.each_with_index{|line, idx| ipos = idx if line.include?(last_route_line)}
  new_line = ""
  insert_pos = lines.size
  10.times do |idx|
    if lines[insert_pos - idx - 1].include?("PLUGIN_ROUTES_INSERT")
      new_line = lines[insert_pos - idx - 1]
      new_line += code_to_add
      lines[insert_pos - idx - 1] = new_line
      break
    end
  end
  if new_line == ""
    puts "Unable to initialize plugin capability - missing key line in application.rb"
    exit(1)
  end
  fil_name = File.join(RAILS_ROOT, "config", "application.rb")
  fil = File.open(fil_name, "w+")
  fil.write(lines.join(""))
  fil.close
end

def plugin_init
  begin
    require File.join(RAILS_ROOT,"config","initializers","brpm_plugin.rb")
    puts "Plugins master directory: #{PLUGIN_LOCATION}"
  rescue Excepion => e
    puts e.message
    show_help
    exit(1)
  end
end

namespace :app do
  
  task :plugins_load do
    plugin_init
    plugin_choice = ENV.has_key?("PLUGIN") ? ENV["PLUGIN"] : nil
    Dir.entries(PLUGIN_LOCATION).reject{|k| k.start_with?(".") || File.file?(File.join(PLUGIN_LOCATION,k)) }.each do |plugin|
      puts "Plugin: #{plugin}"
      next if !plugin_choice.nil? && plugin != plugin_choice
      if File.exist?(File.join(PLUGIN_LOCATION, plugin, "config", "manifest.yml"))
        puts "#-------- Loading Plugin: #{plugin} ------------#"
        manifest = YAML.load(File.open(File.join(PLUGIN_LOCATION, plugin, "config", "manifest.yml")).read)
        puts "#\tAuthor: #{manifest["info"]["author"]}"
        puts "#\tVersion: #{manifest["info"]["version"]}"
        puts "#\tRouting: #{manifest["info"]["default_route"]}"
        manifest["paths"].each do |item|
          path = item["path"]
          files = item["files"]
          FileUtils.mkdir_p File.join(RAILS_ROOT, path) unless File.exist?(File.join(RAILS_ROOT, path))
          puts "#=> Adding to: #{path}"
          files.reject{|k| k.start_with?("orig_") }.each do |file|
            target = File.join(RAILS_ROOT, path, file)
            if File.exist?(target)
              backup = File.join(PLUGIN_LOCATION, plugin, "undo", path, "orig_#{file}")
              FileUtils.mkdir_p backup
              FileUtils.cp target, backup
            end
            FileUtils.cp File.join(PLUGIN_LOCATION, plugin, path, file), target
            puts "\t#{file}"
          end
        end
        register_plugin(plugin, manifest["info"]["default_route"])
      else
        puts "Not a valid plugin: #{plugin}"
      end
    end
  end
  
  task :plugins_remove do
    plugin_init
    plugin_choice = ENV.has_key?("PLUGIN") ? ENV["PLUGIN"] : nil
     Dir.entries(PLUGIN_LOCATION).reject{|k| k.start_with?(".") || File.file?(File.join(PLUGIN_LOCATION,k)) }.each do |dir|
       puts "Plugin: #{dir} = #{plugin_choice}"
       next if !plugin_choice.nil? && dir != plugin_choice
       if File.exist?(File.join(PLUGIN_LOCATION, dir, "config", "manifest.yml"))
         puts "#-------- Removing Plugin: #{dir} ------------#"
         manifest = YAML.load(File.open(File.join(PLUGIN_LOCATION, dir, "config", "manifest.yml")).read)
         manifest["paths"].each do |item|
           path = item["path"]
           files = item["files"]
           puts "#=> Removing: #{path}"
           files.each do |file|
             target = File.join(RAILS_ROOT, path, file)
             puts "\t#{file}"
             FileUtils.rm target, :verbose => true
           end
         end
        register_plugin(dir, "", false)
       else
         puts "Not a valid plugin: #{dir}"
       end
     end  
  end

  task :plugins_setup do
    unless defined?(PLUGIN_LOCATION) 
       plugin = ENV.has_key?("PLUGIN_LOCATION") ? ENV["PLUGIN_LOCATION"] : nil
       if plugin.nil?
         show_help
         exit(1)
       end
       puts "#-------- Preparing BRPM for Plugins --------------#"
       build_plugin_initializer(plugin)
       # modify_routes(plugin)
    else
      puts "Plugin initializer already exists"
    end
  end

  task :plugins_help do
    show_help
  end

end


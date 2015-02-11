require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Brpm
  class Application < Rails::Application
    # Use TorqueBox::Infinispan::Cache for the Rails cache store
    if defined? TorqueBox::Infinispan::Cache
      config.cache_store = :torquebox_store
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{Rails.root}/app/presenters)
    config.autoload_paths += %W(#{Rails.root}/app/sweepers)
    config.autoload_paths += %W(#{Rails.root}/app/concerns)
    config.autoload_paths += %W(#{Rails.root}/lib)
    config.autoload_paths += %W(#{Rails.root}/lib/permissions)
    config.autoload_paths += %W(#{Rails.root}/lib/permissions/model)
    config.autoload_paths += %W(#{Rails.root}/lib/permissions/granters)
    config.autoload_paths += %W(#{Rails.root}/public)
    config.autoload_paths += %W(#{Rails.root}/app/jobs)
    config.autoload_paths += %W(#{Rails.root}/app/services)
    config.autoload_paths += %W(#{Rails.root}/app/forms)
    config.autoload_paths += %W(#{Rails.root}/app/policies)
    config.autoload_paths += %W(#{Rails.root}/app/view_objects)
    config.autoload_paths += %W(#{Rails.root}/app/value_objects)
    config.autoload_paths += %W(#{Rails.root}/app/service_objects)
    config.autoload_paths += %W(#{Rails.root}/app/query_objects)
    config.autoload_paths += %W(#{Rails.root}/app/import)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    ### RVJ: 12 Apr 2012 : RAILS_3_UPGRADE: TODO: Enable this after verifying if is already being used or not
    # config.active_record.observers = :activity_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    config.assets.initialize_on_precompile = true

    #PLUGIN_ROUTES_INSERT
    # Plugin Routes
    # Register Plugin Routes
    if File.exist?(File.join(Rails.root,"config/initializers/brpm_plugin.rb"))
      require File.join(Rails.root,"config/initializers/brpm_plugin.rb")
      if defined?(PLUGIN_LOCATION) && File.exist?(PLUGIN_LOCATION)
        if defined?(PLUGINS_REGISTERED)
          PLUGINS_REGISTERED.keys.reject{|k| k.start_with?("__") }.each do |plugin|
            next unless File.exist?(File.join(PLUGIN_LOCATION, plugin, "config", "routes.rb"))
            puts "Registering plugins:"
            config.paths["config/routes"] << File.join(PLUGIN_LOCATION, plugin, "config", "routes.rb")
          end
        end
      end
    end
    # /Register Plugin Routes

    config.paths["config/routes"] << File.join(Rails.root,"config","routes_last.rb")
      
    config.logger = TorqueBox::Logger.new
    config.logger.level = 2

  end
end

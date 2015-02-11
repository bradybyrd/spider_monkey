if Rails.env.test? or Rails.env.cucumber?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
end

carrierwave_settings_config_file = File.join(Rails.root, 'config', 'carrierwave_settings.rb')
if File.exist?(carrierwave_settings_config_file)
  load carrierwave_settings_config_file
else
  # if there is no user defined carrierwave_settings.rb, then load the default
  load File.join(Rails.root, 'config', 'carrierwave_settings.default.rb')
end
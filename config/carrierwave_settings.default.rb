CarrierWave.configure do |config|
  config.root = Rails.root
  config.cache_dir = config.root.to_s + "/uploads/temp"
  config.base_path = ""
end
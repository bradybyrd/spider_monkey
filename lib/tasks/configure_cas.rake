desc "Activate/De-active CAS Authentication"
namespace :app do
  namespace :cas_auth do
    task :on => :environment do
      write_cas_file(cas_config_file, true)
    end
  end
end

namespace :app do
  namespace :cas_auth do
    task :off => :environment do
      write_cas_file(cas_config_file, false)
    end
  end
end

def write_cas_file(cas_file, cas_enabled)
  if cas_file
    f = File.open(cas_file) # Multiple opening and closing of file can be avoided
    modified_f = f.read.to_s.gsub("ENABLED = #{!cas_enabled}", "ENABLED = #{cas_enabled}")
    f.close
    write_file(cas_file, modified_f)
    handle_cas_filter!(cas_enabled)
    puts "CAS Authentication is #{cas_enabled ? 'enabled' : 'disabled'}"
  else
    puts "Permission Denied ! CAS Configuration cannot be managed by rake app:cas_auth:on"
  end
end

def write_file(path, content)
  fw = File.open(path, "w")
  fw.write(content)
  fw.close
end

def cas_config_file
  f_path = "#{Rails.root}/config/initializers/rubycas.rb"
  File.writable?(f_path) ? f_path : false
end

def handle_cas_filter!(cas_enabled)
  cf_path = "#{Rails.root}/app/controllers/sessions_controller.rb"
  cf = File.open(cf_path)
  filter_statement = "before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => :new"
  if cas_enabled
    modified_cf = cf.read.to_s.gsub("# #{filter_statement}", filter_statement)
  else
    modified_cf = cf.read.to_s.gsub(filter_statement, "# #{filter_statement}")
  end
  cf.close
  write_file(cf_path, modified_cf)
end
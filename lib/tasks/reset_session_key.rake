desc "Reset Instance Session Key"
require 'digest/md5'

namespace :app do
  task :reset_session_key => :environment do
    cur_host = `hostname`.chomp
    new_key = "_stream_step_session_#{RAILS_ENV}_#{cur_host + Digest::MD5.hexdigest(RAILS_ROOT)}"
    GlobalSettings[:session_key] = new_key
  end
end
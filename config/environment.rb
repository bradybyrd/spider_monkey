# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Brpm::Application.initialize!

# add some enhanced logging to console sessions as per
# http://rors.org/2011/07/17/inline-logging-in-rails-console.html
# if "irb" == $0
  # ActiveRecord::Base.logger = Logger.new(STDOUT)
  # ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
# end

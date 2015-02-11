source 'https://rubygems.org'

gem 'rails', '3.2.18'

gem 'activerecord-jdbc-adapter', '~> 1.3.7'
gem 'activerecord-jdbcmssql-adapter', '~> 1.3.7'
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.7'
gem 'activerecord-oracle_enhanced-adapter', '1.4.3', :require => 'activerecord-jdbc-adapter' #|BMC TPS Info    |TPSDR0034741     |DR4JT.1.4.00 |https://github.com/rsim/oracle-enhanced  |Registered |

#gem 'jruby-openssl', '0.9.4' # '0.7.7' #openssl is now built into jruby-1.7.8

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyrhino'
  gem 'uglifier', '>= 1.0.3'
  #gem 'turbo-sprockets-rails3', '0.3.11' # To build assets faster; git: https://github.com/ndbroadbent/turbo-sprockets-rails3
end

gem 'jquery-rails', '2.0.2'

################################################# Gems added for rails 3.2 migration ####################

gem 'wicked_pdf', '0.7.7' #'0.8.0' # turbo-sprockets-rails3 requires version >= 0.8
gem 'attribute_normalizer'
gem 'aasm', '3.2.0'
gem 'concerned_with'
gem 'acts_as_list'
gem 'acts_as_audited'
gem 'net-ldap'
gem 'xml-simple'
gem 'devise'
gem 'devise-encryptable'
gem 'gene_pool'
gem 'acts_as_archival'
gem 'will_paginate'
gem 'cancan'
gem 'rails_autolink'
gem 'popen4'
gem 'hudson-remote-api'
gem 'capistrano', '2.15.5'
gem 'net-ssh', '2.3.0' # used for executing ssh script. Higher version broke RPM's current ssh script. Consider fixing them before updating the gem
gem 'highline', '1.6.11' # capistrano dependency. `1.6.20` includes fixed bug for jruby-1.7.8
gem 'jruby-rack', '>=1.1.7'
gem 'handsoap'
gem 'rubycas-client'
gem 'deep_cloneable', '~> 1.4.0'
gem 'nokogiri', '1.6.1'  #|BMC TPS Info    |TPSDR0033648     |DR4T4.1.4.04 |http://nokogiri.org/ |Registered  |
gem 'liquid'
gem 'dynamic_form'
gem 'savon', '1.1.0'
gem 'rest-client'
gem 'carrierwave' # file attachment gem replacement for attachment_fu, https://github.com/jnicklas/carrierwave
gem 'jruby-parser', '~> 0.3'
gem 'torquebox', '3.1.0'
gem 'torquebox-mailer', '1.0.0'
gem 'rally_rest_api', '1.0.3'
gem 'ice_cube', '0.11.0' # recurrence, https://github.com/seejohnrun/ice_cube
gem 'recurring_select', '1.2.0' # recurrence_helpers, https://github.com/GetJobber/recurring_select
gem 'jquery_context_menu-rails'
gem 'activerecord-import', '0.5.2' # 0.5.2 -- homemade version out of 0.5.0 but with jdbc-mssql support. bulk create instances (aka mass-insert)

gem 'cache_digests', '0.3.1'
gem 'slim', '2.0.2'
gem 'slim-rails', '2.1.4'
gem 'underscore-rails' # handy JS helper methods (by Nazar Khmil)
# gem 'goldiloader' # automatically eager load associations, git: 'https://github.com/salsify/goldiloader'
gem 'draper', '1.3.1'  # for decorators
gem 'gibberish'   #for encrypted passwords

group :test, :development do
  gem 'rspec-rails', '2.99.0' #https://github.com/rspec/rspec-rails
  gem 'random_data', '1.6.0'  # forms test reports (rspec in our case) into XML for CI server
  gem 'ci_reporter', '1.8.4'  # a formatting tool for
  gem 'pry', '0.9.12.3'
  gem 'pry-rails', '0.3.2'
  gem 'letter_opener', '1.2.0'
  gem 'newrelic_rpm', '3.7.3.204'
  gem 'bullet', '4.8.0'
  # gem 'lol_dba'
  # gem 'trinidad'
end

group :test do
  gem 'spork', '~> 1.0.0rc4' # a DRB server for speeding up test running
  gem 'spork-rails', '~> 4.0.0'
  gem 'simplecov', '0.7.1', :require => false # a rails 3 version of rcov to provide code coverage
  gem 'capybara', '2.4.1' # a full stack driver for feature and api level testing
  gem 'factory_girl_rails', '4.4.1' # a fixture and database populating gem for creating test data
  gem 'shoulda-matchers', '2.5.0' # a powerful set of matchers for rspec and cucumber testing
  gem 'database_cleaner', '1.2.0' #https://github.com/bmabey/database_cleaner.git
  gem 'json_select', '0.1.4' # https://github.com/fd/json_select
  gem 'rspec-http', '>= 0.9' #https://github.com/c42/rspec-http, a library for providing http return code matchers
  gem 'poltergeist', '~> 1.5.1'
end

require 'rubygems'

spec_helper_setup = proc do
  # all RSpec configuration goes in here

  # customization for ruby 1.9 compatible code coverage
  require 'simplecov'
  SimpleCov.start 'rails' if ENV['COVERAGE']

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'shoulda/matchers'

  # customization for webrat alternative
  require 'capybara/rails' #an alternative to webrat
  require 'capybara/poltergeist'

  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
  # Adding all page objects to require path
  Dir[Rails.root.join('spec/features/page_objects/**/*.rb')].each { |f| require f }

  # let you to `login_as(user)` skipping the controller
  include Warden::Test::Helpers
  Warden.test_mode!

  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, {
        timeout: 120
    })
  end

  RSpec.configure do |config|
    Capybara.default_driver         = :rack_test
    Capybara.javascript_driver      = :poltergeist
    Capybara.ignore_hidden_elements = false
    Capybara.default_wait_time      = 10
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    # turning this to false to let database cleaner do it
    config.use_transactional_fixtures = false

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = '1234'

    config.infer_spec_type_from_file_location!

    # Use the specified formatter
    config.formatter = :documentation # :progress, :html, :textmate

    # BMC Config Customizations Start

    config.before(:suite) do
      DatabaseCleaner.clean_with(:deletion)
      DatabaseCleaner.strategy = :transaction
    end

    config.before(:all) do
      @user = create :user, :with_role_and_root_group
    end

    config.before(:each) do
      User.current_user = @user
      PermissionMap.any_instance.stub(:get_permission) do |id|
        Permission.find(id).to_simple_hash
      end
    end

    config.before(:each, type: :controller) do
      sign_in @user
    end

    config.before(:each) do |example|
      if example.metadata[:js]
        DatabaseCleaner.strategy = :deletion
      else
        DatabaseCleaner.strategy = :transaction
      end
      DatabaseCleaner.start
    end

    config.after(:each) do
      User.current_user = nil
      Warden.test_reset!
      DatabaseCleaner.clean
    end

    config.after(:all) do
      DatabaseCleaner.clean_with(:deletion)
    end

    config.include Helpers
    config.include FactoryGirl::Syntax::Methods
    config.include AttributeNormalizer::RSpecMatcher, type: :model
    config.include Devise::TestHelpers,               type: :controller
    config.include ValidUserRequestHelper,            type: :feature
    config.include APISpecHelper,                     type: :request
    config.include WaitForAjax,                       type: :feature
    config.include PoltergeistShortcutsHelper,        type: :feature
    config.include PackageHelper,                     type: :feature
  end
end

require 'spork'

if defined?(Spork) && Spork.using_spork?
  #uncomment the following line to use spork with the debugger
  #require 'spork/ext/ruby-debug'
  Spork.prefork &spec_helper_setup
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  Spork.each_run do
    # This code will be run each time you run your specs.
    # Requires supporting ruby files with custom matchers and macros, etc,
    # in spec/support/ and its subdirectories.
    FactoryGirl.reload

    # http://stackoverflow.com/questions/8774227/why-not-use-shared-activerecord-connections-for-rspec-selenium
    # ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

    # reload permissions related stuff
    Dir[Rails.root + 'lib/permissions/**/*.rb'].each do |file|
      load file
    end
  end
else
  spec_helper_setup.call
end

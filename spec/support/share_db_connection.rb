# source:       https://github.com/railscasts/391-testing-javascript-with-phantomjs/blob/master/checkout-after/spec/support/share_db_connection.rb
# why using it: http://stackoverflow.com/questions/18623661/why-is-capybara-discarding-my-session-after-one-event
# why it's bad: http://stackoverflow.com/questions/8774227/why-not-use-shared-activerecord-connections-for-rspec-selenium

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    # @@shared_connection || ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
    @@shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
# Because of using Spork this line goes to `Spork.each_run` block
# ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection unless defined?(Spork) && Spork.using_spork?

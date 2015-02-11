namespace :perf do
  task :setup => :environment do
    Bundler.require(:test)
  end
  task :strip_data => 'perf:setup' do
    User.all.each do |u|
      u.update_attributes!({
        :login => Random.alphanumeric(7),
        :email => FactoryGirl.generate(:email),
        :first_name => Random.firstname,
        :last_name => Random.lastname,
        :contact_number => Random.phone,
      })
      # If some user in db has password which matches to ours, we don't want to reveal it with validation error
      rand_password = Random.alphanumeric
      u.update_attributes!({
        :password => rand_password,
        :password_confirmation => rand_password,
        })
      u.update_attributes!({
        :password => 'password1',
        :password_confirmation => 'password1',
      })
    end
  end
end
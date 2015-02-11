require "rubygems"
require "faker"
require File.dirname(__FILE__) + "/../config/environment"

the_user = User.find(3)

app = App.find_or_create_by_name(:name => "The App")
environment = Environment.find_or_create_by_name(:name => "The Environment")
component = Component.find_or_create_by_name(:name => "The Component")

app.environments << environment
app.components << component

InstalledComponent.create!(:application_environment => app.application_environments.first, 
                           :application_component => app.application_components.first)

Request.delete_all
Step.delete_all


beginning_of_month = Time.now.beginning_of_month + 9.hours
steps_n = 500
20.times do |n|
  puts "Creating request #{n + 1}..."
  beginning_of_day = beginning_of_month + (n / 6).days
  req = Request.create!(:requestor => the_user, :deployment_coordinator => the_user,
                        :app => app, :environment => environment,
                        :scheduled_at => beginning_of_day,
                        :target_completion_at => beginning_of_day + 1.hour)

  Step.transaction do
    steps_n.times do |m|
      puts("   Creating steps #{m + 1}-#{m + 100}...") if m % 100 == 0
      req.steps.create!(:owner => the_user, :component => component)
    end
  end
  
  steps_n = 50
end

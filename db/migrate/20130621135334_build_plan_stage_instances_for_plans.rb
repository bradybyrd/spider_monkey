class BuildPlanStageInstancesForPlans < ActiveRecord::Migration

  def self.up

    # performing this insert in sql is challenging in a multi-vendor database context as the
    # sequence mechanisms for a unique ID vary alot, so using Ruby objects

    # declare the class in case it is missing in the source code, see
    # http://chrisroos.co.uk/blog/2006-05-12-using-active-record-models-in-rails-migrations
    # for a more robust implementation that is out of scope for this patch

    begin

      # now find all the plans
      plans = Plan.all

      # set a counter and start a prompt
      counter = 0
      puts 'Creating plan_stage_instances...'

      # cycle through them and create an instance if none exists
      plans.each do |plan|
        # only work on it if it has plan_stages and no plan_stage_instances
        if plan.stages.present?
            plan.stages.each do |ps|
              psi = plan.plan_stage_instances.find_or_create_by_plan_stage_id(ps.id)
              if psi.present?
                print '.'
                counter += 1
              else
                print 'e'
              end
            end
        end
      end
    rescue => e
      puts 'Unable to create plan stage instances due to a system error.'
      puts "Error message: #{e.message}"
      puts 'Backtrace: '
      puts e.backtrace.join("\n")
    ensure
      puts "\nFinished finding or creating #{ counter } Plan Stage Instances."
    end

  end

  def self.down
    # the reverse of this migration is challenging because we will not know which plans
    # had their instances created by our script.  My inclination is to not have a down
    # message beyond a reminder that plan_stage_instances will continue to exist until
    # the table is removed in the previous migration or a manual database operation is
    # performed
    puts 'Plan Stage Instances created by this migration are not removable during roll back.'
    puts 'Remove automatically by rolling back the PlanStageInstance creation migration'
  end
end
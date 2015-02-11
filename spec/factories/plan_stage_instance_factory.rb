# be sure to turn off creation callback
# on plan or you will get a validation error
# because an identical plan_stage_instance
# was created by the plan
#
# Sample code for spec
#
#before(:all) do
#  # without this, it is difficult to get a plan assigned without two copies
#  # of the plan stage instance
#  Plan.skip_callback(:create, :after, :build_plan_stage_instances)
#end
#after(:all) do
#  # without this, it is difficult to get a plan assigned without two copies
#  # of the plan stage instance
#  Plan.set_callback(:create, :after, :build_plan_stage_instances)
#end

FactoryGirl.define do
  factory :plan_stage_instance do

    plan_stage
    plan { create(:plan, :plan_template => plan_stage.plan_template) }


  end
end
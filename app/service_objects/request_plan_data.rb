class RequestPlanData
  attr_reader :plan_member

  def initialize(request, params, current_user)
    @request, @params, @current_user = request, params, current_user

    @plan_stage_id = params[:plan_stage_id].to_i
    # find the current plan, or one from passed ids (create request from plan)
    @plan = @request.plan || Plan.find(@params[:plan_id].to_i) rescue nil
    # TODO - PP - Add a instance method in User Model that returns boolean after checking user role
    @plan_stages = @plan.try(:stages) || []    #build a plan member if one does not exist
    @plan_member = @request.plan_member || build_new_plan_member
  end

  def available_plans_for_select
    Plan.functional.select([:name, :id]).order('plans.name asc').map{ |lc| [lc.name, lc.id] }
  end

  def available_plan_stages_for_select
    result = [['Unassigned', 0]]
    unless @plan_stages.nil?
      result += @plan_stages.map{ |lc| [lc.name, lc.id] }
    end
    result
  end

  def stages_requestor_can_not_select
    # TODO: requestor_access here
    unless @current_user.can?(:select, PlanStage.new)
      @plan_stages.reject { |lc| lc.requestor_access }.map { |lc| [lc.id] }
    end
  end

  private

  def build_new_plan_member
    member_attributes = {plan: @plan}
    if @plan_stage_id == 0 || @plan_stages.map(&:id).include?(@plan_stage_id)
      member_attributes[:plan_stage_id] = @plan_stage_id
    end
    @request.build_plan_member( member_attributes )
  end
end

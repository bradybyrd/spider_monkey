class V1::PlanStageInstancesController < V1::AbstractRestController

  def index
    @plan_stage_instances = PlanStageInstance.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @plan_stage_instances.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => plan_stage_instances_presenter }
        format.json { render :json => plan_stage_instances_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @plan_stage_instance = PlanStageInstance.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @plan_stage_instance.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => plan_stage_instance_presenter }
        format.json { render :json => plan_stage_instance_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # special case of a model that can only be created through programmatic automation
  def create
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  # special case of a model that can only be created through programmatic automation
  def update
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  # special case of a model that can only be created through programmatic automation
  def destroy
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  private

  # helper for loading the plan stage instances presenter
  def plan_stage_instances_presenter
    @plan_stage_instances_presenter ||= V1::PlanStageInstancesPresenter.new(@plan_stage_instances, @template)
  end

  # helper for loading the plan stage instance present
  def plan_stage_instance_presenter
    @plan_stage_instance_presenter ||= V1::PlanStageInstancePresenter.new(@plan_stage_instance, @template)
  end
end

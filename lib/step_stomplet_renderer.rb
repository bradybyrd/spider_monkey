class StepStompletRenderer < StompletRenderer
  def initialize
    super
    @formats << :status_buttons
    
    @av = ActionView::Base.new
    @av.view_paths = ActionController::Base.view_paths
    @av.extend StepsHelper
  end

  def render_status_buttons(model, properties)
    return unless properties[:event] == 'update'
    @av.render({
      :partial => "steps/step_rows/status_buttons",
      :locals => {:unfolded_steps => true, :step => model, :request => model.request}
    })
  end
end
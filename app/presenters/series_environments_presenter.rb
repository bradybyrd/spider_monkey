class SeriesEnvironmentsPresenter
  attr_reader :series, :user, :real_series

  def initialize(series, user)
    @series, @user = series, user
    @real_series = series.respond_to?(:series) ? series.series : series
  end

  def to_sym
    :"#{series.class.name.underscore}"
  end

  def listable_props
    series.environment_names.split(', ')
  end

  def linkable_props
    link = Struct.new(:name, :html_attrs, :applications)
    events.inject([]) do |memo, e|
      memo.push link.new(e.environment.name, html_attrs(e), e.environment.apps)
    end
  end

  private

    def events
      series.events
    end

    def data_attrs(event)
      {
        id: event.id,
        in_past: event.in_past?,
        can_edit: user.can?(:edit, real_series),
        can_schedule: user.can?(:create, Request.new),
        behavior: behavior,
        event_state: event.state,
      }.merge(aasm_state)
    end

    def html_attrs(event)
      {
        data: data_attrs(event),
        class: 'environment-link',
        title: title(event)
      }
    end

    def behavior
      series.behavior
    end

    def aasm_state
      real_series.respond_to?(:aasm_state) ? { aasm_state: real_series.aasm_state } : {}
    end

    def title(event)
      title = "Current state: <span class='lighter'>#{event.state}</span> <br/>"
      title << "Reason of move/suspend/resume: <span class='lighter'>#{event.reason}</span>" if event.reason.present?
      title
    end
end

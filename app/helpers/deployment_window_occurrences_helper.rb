module DeploymentWindowOccurrencesHelper

  def occurrence_environments_links(occurrence, current_user)
    if occurrence.events.any?
      options = {}
      options[:only_names] = occurrence.series.archived? || occurrence.in_past?
      ListBuilder.new(SeriesEnvironmentsPresenter.new(occurrence, current_user), options).display_list
    end
  end

  def display_state(occurrence)
    current_states = occurrence.events.map(&:state)
    current_state = nil

    DeploymentWindow::Event::STATES.each do |state|
      if current_states.all? {|s| s == state }
        current_state = state
        break
      end
    end

    current_state ? current_state : 'modified'
  end
end

module DeploymentWindowSeriesHelper

  def duration_days_select
    DeploymentWindow::Series::DURATION_DAYS.map{|duration| ["#{duration} #{duration == 1 ? 'day' : 'days'}", duration]}
  end

  def deployment_window_event_option_text(event, include_month = false)
    return "" if event.nil?
    text = "#{ordinalize(event.start_at.day)}, " + event.start_at.strftime("%I:%M%P") +
        ", #{distance_between(event.start_at, event.finish_at)} - #{event.occurrence.series.name}"
    text = event.start_at.strftime("%b") + " " + text if include_month
    text
  end

  def distance_between(start_date, end_date)
    duration = (end_date - start_date)
    rest, secs = duration.divmod( 60 )
    rest, mins = rest.divmod( 60 )
    days, hours = rest.divmod( 24 )

    result = []
    result << "#{days}d" if days > 0
    result << "#{hours}h" if hours > 0
    result << "#{mins}m" if mins > 0
    return result.join(' ')
  end

  def series_environments_links(series, current_user)
    if series.events.any?
      options = {}
      options[:only_names] = series.recurrent? || series.archived? || series.in_past?
      series_environments_presenter = SeriesEnvironmentsPresenter.new(series, current_user)
      ListBuilder.new(series_environments_presenter, options).display_list
    end
  end

  def unarchived?(scope)
    scope == :unarchived
  end

  def start_at_disabled?(series)
    if series.start_at && series.non_recurrent?
      series.start_at < DateTime.now && !series.start_at_changed?
    elsif series.start_at && series.recurrent?
      series.start_at < DateTime.now && !series.start_date_changed?
    else
      false
    end
  end

  def prepare_name(series)
    content = []
    content << content_tag('span', series.name, class: 'series-name')
    content << link_to('(occurrences)', deployment_window_series_occurrences_path(series), class: 'occurrences-link')
    content.join(' ').html_safe
  end
end

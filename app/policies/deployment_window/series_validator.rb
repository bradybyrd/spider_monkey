module DeploymentWindow
  class SeriesValidator
    attr_reader   :series
    attr_accessor :occurrences

    def initialize(series)
      @series = series
    end

    def validate
      if @series.recurrent?
        check_overlapping_occurrences
        check_schedule
        check_occurrence_limit_count
      end
      check_occurrences_ready
      check_appropriate_environments
    end

    def check_dates_exist(dates_existing)
      series.errors.add(:base, I18n.t('deployment_window.validations.start_date_not_exist')) if dates_existing[:start_at_invalid]
      series.errors.add(:base, I18n.t('deployment_window.validations.finish_date_not_exist')) if dates_existing[:finish_at_invalid]
    end

    def check_overlapping_occurrences
      series.errors.add(:base, I18n.t('deployment_window.validations.check_overlapping_occurrences')) if overlap_occurrences?
    end

    def check_appropriate_environments
      return unless series.environment_ids && series.environment_ids.any?
      series.errors.add(:base, I18n.t('deployment_window.validations.check_appropriate_environments')) if proper_environments_policy?
    end

    def check_occurrences_ready
      series.errors.add(:base, I18n.t('deployment_window.validations.check_occurrences_ready')) unless series.occurrences_ready?
    end

    def check_schedule
      unless series.finish_before_past_time?
        series.errors.add(:base, I18n.t('deployment_window.validations.no_occurrences_to_generate')) if no_occurrences?
      end
    end

    def check_occurrence_limit_count
      return if stop_proceed?
      max_occurrences   = DeploymentWindow::Series::OCCURRENCE_LIMIT_COUNT
      max_years         = (DeploymentWindow::Series::OCCURRENCE_LIMIT_COUNT / 365).floor
      calculated_occurrences

      series.errors.add(:base, I18n.t('deployment_window.validations.occurrence_limit_exceeded',
                                      max_occurrences: max_occurrences, max_years: max_years)) if occurrence_limit_exceeded?
    end

    def check_bad_date_format(exception)
      expected_date_format = GlobalSettings[:default_date_format].split(' ').first
      exception.errors.each do |error|
        %w(start_at finish_at).each do |attr_name|
          series.errors.add(:base, I18n.t("deployment_window.validations.#{attr_name}_incorrect_format",
                                        expected_date_format: expected_date_format)) if error.attribute == attr_name
        end
      end
    end

    private

    def stop_proceed?
      series.schedule.nil? || series.start_at.nil? || series.finish_at.nil?
    end

    def proper_environments_policy?
      environments = Environment.scoped.extending(QueryHelper::WhereIn).where_in(:id, series.environment_ids)
      if series.behavior == DeploymentWindow::Series::ALLOW
        environments = environments.opened
      elsif series.behavior == DeploymentWindow::Series::PREVENT
        environments = environments.closed
      end
      environments.count > 0
    end

    def overlap_occurrences?
      return false if series.non_recurrent? || stop_proceed? || calculated_occurrences.count < 2
      occurs = calculate_occurrences(series.start_at.utc, series.finish_at.utc)
      prev_occur = occurs.shift
      occurs.any? do |occur|
        overlap = prev_occur.end_time > occur.start_time
        prev_occur = occur
        overlap
      end
    end

    def occurrence_limit_exceeded?
      return false if stop_proceed?
      calculated_occurrences.count > DeploymentWindow::Series::OCCURRENCE_LIMIT_COUNT
    end

    def no_occurrences?
      return false if stop_proceed?
      calculated_occurrences.count.zero?
    end

    def calculated_occurrences
      @calculated_occurrences ||= calculate_occurrences(series.start_at, series.finish_at)
    end

    def calculate_occurrences(start_at, finish_at)
      series.schedule_from(start_at).occurrences(finish_at - series.duration).sort || []
    end

  end
end

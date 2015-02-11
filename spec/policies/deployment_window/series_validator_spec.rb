require 'spec_helper'

describe DeploymentWindow::SeriesValidator do
  describe "#overlap_occurrences?" do
    let(:series_with_overlapped_occurrences) {
      build :recurrent_deployment_window_series, {
        finish_at: Time.zone.now + 10.days,
        frequency: {interval: 1, validations: {day: [1,2] }, rule_type: "IceCube::WeeklyRule"}
      }
    }
    let(:series_without_overlapped_occurrences) {
      Time.zone = "Eastern Time (US & Canada)" # Timezone which has summer time(Daylight saving time)
      build :recurrent_deployment_window_series, finish_at: Time.zone.now + 1.year
    }

    it "returns true if occurrences overlap" do
      series = series_with_overlapped_occurrences
      series.stub(:duration).and_return(48.hours)
      series.send(:update_schedule)

      validator = DeploymentWindow::SeriesValidator.new(series)
      expect(validator.send(:overlap_occurrences?)).to be_truthy
    end

    it "returns false if occurrences do not overlap" do
      series = series_without_overlapped_occurrences
      series.stub(:duration).and_return((23.5).hours.to_i)
      series.send(:update_schedule)

      validator = DeploymentWindow::SeriesValidator.new(series)
      expect(validator.send(:overlap_occurrences?)).to be_falsey
    end
  end

  describe '#check_dates_exist' do
    let(:series) { create :deployment_window_series }

    it 'generates error messages if dates do not exist' do
      validator = DeploymentWindow::SeriesValidator.new(series)
      validator.check_dates_exist(start_at_invalid: true, finish_at_invalid: true)
      expect(series.errors[:base]).to eq [I18n.t('deployment_window.validations.start_date_not_exist'), I18n.t('deployment_window.validations.finish_date_not_exist')]
    end

    it 'generates error messages if start date does not exist' do
      validator = DeploymentWindow::SeriesValidator.new(series)
      validator.check_dates_exist(start_at_invalid: false, finish_at_invalid: true)
      expect(series.errors[:base]).to eq [I18n.t('deployment_window.validations.finish_date_not_exist')]
    end

    it 'generates error messages if finish date does not exist' do
      validator = DeploymentWindow::SeriesValidator.new(series)
      validator.check_dates_exist(start_at_invalid: true, finish_at_invalid: false)
      expect(series.errors[:base]).to eq [I18n.t('deployment_window.validations.start_date_not_exist')]
    end

    it 'generates no error messages if dates are valid' do
      validator = DeploymentWindow::SeriesValidator.new(series)
      validator.check_dates_exist(start_at_invalid: false, finish_at_invalid: false)
      expect(series.errors[:base]).to eq []
    end
  end
end

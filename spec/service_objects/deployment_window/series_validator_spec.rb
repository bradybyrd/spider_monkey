require 'spec_helper'

describe DeploymentWindow::SeriesValidator do
  let(:series) { create :recurrent_deployment_window_series }
  let(:validator) { series.validator }

  before { DeploymentWindow::SeriesBackgroundable.stub(:background) { DeploymentWindow::SeriesBackgroundable } }

  describe '#check_overlapping_occurrences' do
    it 'should add errors if occurrences overlaps' do
      validator.stub(:overlap_occurrences?).and_return true
      validator.check_overlapping_occurrences
      series.errors.count.should eq 1
    end
  end

  describe 'check_appropriate_environments' do
    let(:env_closed){create(:environment, :closed)}
    let(:env_opened){create(:environment, :opened)}
    let(:mixed_environment_ids) {[env_closed.id, env_opened.id]}
    let(:opened_environment_ids) {[env_opened.id]}
    let(:closed_environment_ids) {[env_closed.id]}

    context 'allow series' do
      let(:series) { build :deployment_window_series, behavior: DeploymentWindow::Series::ALLOW }

      it 'should add errors with mixed env polices because only closed env allowed' do
        series.environment_ids = mixed_environment_ids
        series.validator.check_appropriate_environments

        expect(series.errors).to_not be_empty
      end

      it 'should add errors with opened env policy because only closed env allowed' do
        series.environment_ids = opened_environment_ids
        series.validator.check_appropriate_environments

        expect(series.errors).to_not be_empty
      end

      it 'should not add errors with closed env because only closed env allowed' do
        series.environment_ids = closed_environment_ids
        series.validator.check_appropriate_environments

        expect(series.errors.full_messages).to eq []
      end
    end

    context 'prevent series' do
      let(:series) { build :deployment_window_series, behavior: DeploymentWindow::Series::PREVENT }

      it 'should add errors with mixed env polices because only opened env allowed' do
        series.environment_ids = mixed_environment_ids
        validator.check_appropriate_environments

        expect(series.errors).to_not be_empty
      end

      it 'should add errors with closed env policy because only opened env allowed' do
        series.environment_ids = closed_environment_ids
        validator.check_appropriate_environments

        expect(series.errors).to_not be_empty
      end

      it 'should not add errors with opened env because only opened env allowed' do
        series.environment_ids = opened_environment_ids
        validator.check_appropriate_environments

        expect(series.errors.full_messages).to eq []
      end
    end
  end

  describe '#check_occurrences_ready' do
    it 'should add errors in case occurrences has not yet been generated' do
      series = build :deployment_window_series, occurrences_ready: false
      series.validator.check_occurrences_ready

      expect(series.errors).to_not be_empty
    end

    it 'should not add errors in case occurrences has already been generated' do
      series = build :deployment_window_series, occurrences_ready: true
      series.validator.check_occurrences_ready

      expect(series.errors).to be_empty
    end
  end

  describe '#check_occurrence_limit_count' do
    context 'if series is recurrent and has start_at and finish_at' do

      it 'should pre calculate occurrences' do
        validator.stub(:occurrence_limit_exceeded?).and_return false
        validator.stub(:occurrences).and_return false

        validator.should_receive :calculated_occurrences
        validator.check_occurrence_limit_count
      end

      it 'should not validate if schedule/frequency is missing' do
        validator.stub(:occurrence_limit_exceeded?).and_return false
        validator.stub(:no_occurrences?).and_return false
        series.stub(:schedule).and_return nil

        validator.should_not_receive :calculated_occurrences
        validator.check_occurrence_limit_count
      end


      context 'stubbed calculated_occurrences' do
        before { validator.stub(:calculated_occurrences) }

        it 'should add errors in case occurrence limit exceeded' do
          validator.stub(:occurrence_limit_exceeded?).and_return true
          validator.stub(:no_occurrences?).and_return false
          validator.check_occurrence_limit_count

          expect(series.errors).to_not be_empty
        end

        it 'should not add errors in case occurrence limit not exceeded' do
          validator.stub(:occurrence_limit_exceeded?).and_return false
          validator.stub(:no_occurrences?).and_return false
          validator.check_occurrence_limit_count

          expect(series.errors).to be_empty
        end

        it 'should add errors if no occurrences to be created' do
          validator.stub(:occurrence_limit_exceeded?).and_return true
          validator.stub(:calculated_occurrences).and_return []
          validator.check_occurrence_limit_count

          expect(series.errors).to_not be_empty
        end

        it 'should add errors if no occurrences to be created' do
          validator.stub(:occurrence_limit_exceeded?).and_return false
          validator.stub(:no_occurrences?).and_return false
          validator.check_occurrence_limit_count

          expect(series.errors).to be_empty
        end
      end
    end
  end

  describe '#overlap_occurrences?' do
    it 'returns false for valid series' do
      series = build(:recurrent_deployment_window_series, start_at: Time.zone.now + 1.day, finish_at: Time.zone.now + 3.days)
      series.send(:update_schedule)
      series.validator.send(:overlap_occurrences?).should be_falsey
    end

    it 'returns true for invalid series' do
      series = build(:recurrent_deployment_window_series, start_at: Time.zone.now + 1.day, finish_at: Time.zone.now + 3.days + 1.hour)
      series.send(:update_schedule)
      series.validator.send(:overlap_occurrences?).should be_truthy
    end
  end

  describe '#occurrence_limit_exceeded?' do
    let(:start_at) { Time.zone.now + 1.day }
    let(:series_no_overlimit) { create(:recurrent_deployment_window_series) }
    let(:series_with_overlimit) do
      create :recurrent_deployment_window_series,
             start_at: start_at,
             finish_at: start_at + 2.years + 2.days, # extra days to include leap year
             frequency: { interval: 1, rule_type: 'IceCube::DailyRule' }
    end

    #before { DeploymentWindow::Series.any_instance.stub(:recurrent?){true} }

    it 'returns false for series with occurrences count below limit' do
      validator = series_no_overlimit.validator
      validator.send(:calculated_occurrences)
      validator.send(:occurrence_limit_exceeded?).should be_falsey
    end

    it 'returns true for series with too many occurrences' do
      validator = series_with_overlimit.validator
      validator.send(:calculated_occurrences)
      validator.send(:occurrence_limit_exceeded?).should be_truthy
    end
  end

  describe '#no_occurrences?' do
    it 'should be true if no occurrences' do
      validator.stub(:calculated_occurrences).and_return []
      validator.send(:no_occurrences?).should be_truthy
    end

    it 'should be false if any of occurrences' do
      validator.stub(:occurrences).and_return ['#!/bin/bash']
      validator.send(:no_occurrences?).should be_falsey
    end
  end

  describe '#calculated_occurrences' do
    it 'should return occurrences if any' do
      validator.send(:calculated_occurrences).should_not be_empty
    end
  end

  describe '#check_bad_date_format' do
    context 'with exception about start_at' do
      let(:exception)   { OpenStruct.new(errors: [OpenStruct.new(attribute: 'start_at')]) }

      it 'adds error to series' do
        expect{validator.check_bad_date_format(exception)}.to change{validator.series.errors.count}.by(1)
      end
    end

    context 'with exception about finish_at' do
      let(:exception)  { OpenStruct.new(errors: [OpenStruct.new(attribute: 'finish_at')]) }

      it 'adds error to series' do
        expect{validator.check_bad_date_format(exception)}.to change{validator.series.errors.count}.by(1)
      end
    end
  end

end

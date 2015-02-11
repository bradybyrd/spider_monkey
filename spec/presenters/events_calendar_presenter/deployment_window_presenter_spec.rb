require 'spec_helper'

module EventsCalendarPresenter
  describe DeploymentWindowPresenter do
    let(:environment) { double('environment', id: 1, name: 'first') }
    let(:date) { Date.today }
    let(:presenter) { EventsCalendarPresenter::DeploymentWindowPresenter.new event, environment.id, date-2.days, date-1.day }

    describe '#start_at' do
      let(:event) { double('deployment_window_event', start_at: date) }

      context 'when events start_at is greater than diagram_start_at' do
        it 'returns events start_at date' do
          expect(presenter.start_at).to eq(date)
        end
      end

      context 'when events start_at is less than diagram_start_at' do
        let(:event) { double('deployment_window_event', start_at: date-3.days) }
        it 'returns passed in start_at date' do
          expect(presenter.start_at).to eq(date-2.days)
        end
      end
    end

    describe '#finish_at' do
      let(:event) { double('deployment_window_event', finish_at: date) }

      context 'when events finish_at is greater than diagram_finish_at' do
        it 'returns passed in finish_at date' do
          expect(presenter.finish_at).to eq(date-1.day)
        end
      end

      context 'when events finish_at is less than diagram_finish_at' do
        let(:event) { double('deployment_window_event', finish_at: date-2.days) }
        it 'returns events finish_at date' do
          expect(presenter.finish_at).to eq(date-2.days)
        end
      end
    end

    describe '#color' do
      let(:time) { Time.now }
      subject { presenter.color }

      context 'when events finish_at is in the past' do
        let(:event) { double('deployment_window_event', finish_at: (time - 1.day)) }
        it { should be EventsCalendarPresenter::DeploymentWindowPresenter::GREY }
      end

      context 'when events finish_at is not in the  past' do
        let(:event) { double('deployment_window_event', finish_at: (time + 1.day)) }
        it 'should call upcoming_event_color' do
          presenter.should_receive(:upcoming_event_color)
          presenter.color
        end
      end
    end

    describe '#tooltext' do
    end
  end
end

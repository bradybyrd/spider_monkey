require 'spec_helper'

module EventsCalendarPresenter
  describe DeploymentWindowDecorator do
    let(:date) { Date.today }
    describe '#allow?' do
      context 'allow' do
        let(:event) { double(DeploymentWindow::Event, behavior: DeploymentWindow::Series::ALLOW) }
        subject { DeploymentWindowDecorator.new(event, date, date+1.day).allow? }
        it { should be_truthy }
      end

      context 'prevent' do
        let(:event) { double(DeploymentWindow::Event, behavior: DeploymentWindow::Series::PREVENT) }
        subject { DeploymentWindowDecorator.new(event, date, date+1.day).allow? }
        it { should be_falsey }
      end
    end

    describe '#old?' do
      subject do
        event = double(DeploymentWindow::Event, finish_at: date)
        decorator = DeploymentWindowDecorator.new event, date, date+1.day
        decorator.old?
      end

      context 'past' do
        let(:date) { Time.now - 1.day }
        it { should be_truthy }
      end

      context 'future' do
        let(:date) { Time.now + 1.day }
        it { should be_falsey }
      end
    end

    describe '#permitted_actions' do
      it 'returns an empty array when event is in the past' do
        event = double :event, in_past?: true
        user = double :user

        expect(DeploymentWindowDecorator.new(event).permitted_actions(user)).to eq([])
      end

      it 'returns an empty array when user has no permissions' do
        event = double :event, in_past?: false, behavior: DeploymentWindow::Series::ALLOW
        user = double :user, can?: false

        expect(DeploymentWindowDecorator.new(event).permitted_actions(user)).to eq([])
      end

      it 'injects only `edit` action when event has `prevent` behavior even if user has all permissions' do
        event = double :event, in_past?: false, behavior: DeploymentWindow::Series::PREVENT
        user = double :user, can?: true

        expect(DeploymentWindowDecorator.new(event).permitted_actions(user)).to eq([:edit])
      end

      it 'injects `edit` action when user has permission to edit event' do
        event = double :event, in_past?: false, behavior: DeploymentWindow::Series::PREVENT
        user = double :user, can?: false
        user.stub(:can?).with(:edit, event).and_return(true)

        expect(DeploymentWindowDecorator.new(event).permitted_actions(user)).to eq([:edit])
      end

      it 'injects `schedule` action when event has `allow` behavior and user has permission to create request' do
        event = double :event, in_past?: false, behavior: DeploymentWindow::Series::ALLOW
        user = double :user, can?: false
        user.stub(:can?).with(:create, an_instance_of(Request)).and_return(true)

        expect(DeploymentWindowDecorator.new(event).permitted_actions(user)).to eq([:schedule])
      end
    end
  end
end

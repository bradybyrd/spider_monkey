require 'spec_helper'

describe MainTabs do
  let(:user) { create :user }

  describe '.root_path' do
    before { MainTabs::PERMISSIONS_PATHS.keys.each { |subj| user.stub(:can?).with(:view, subj).and_return(true) } if user.present? }

    context 'all tabs are opened' do
      it 'returns default root /' do
        expect(MainTabs.root_path(user)).to eq '/'
      end
    end

    context 'dashboard is closed' do
      before { user.stub(:can?).with(:view, :dashboard_tab).and_return(false) }

      it 'returns /plans' do
        expect(MainTabs.root_path(user)).to eq '/plans'
      end
    end

    context 'all tabs are closed' do
      before { MainTabs::PERMISSIONS_PATHS.keys.each { |subj| user.stub(:can?).with(:view, subj).and_return(false) } if user.present? }

      it 'returns /dashboard' do
        expect(MainTabs.root_path(user)).to eq '/dashboard'
      end
    end

    context 'no user' do
      let(:user) { nil }

      it 'returns default root /' do
        expect(MainTabs.root_path(user)).to eq '/'
      end
    end
  end

  describe '.selected_any?' do
    before { MainTabs::PERMISSIONS_PATHS.keys.each { |subj| user.stub(:can?).with(:view, subj).and_return(false) } if user.present? }

    context 'all tabs are closed' do
      it 'returns false' do
        expect(MainTabs.selected_any?(user)).to be false
      end
    end

    context 'some tabs are opened' do
      before { user.stub(:can?).with(:view, :dashboard_tab).and_return(true) }

      it 'returns true' do
        expect(MainTabs.selected_any?(user)).to be true
      end
    end

    context 'no user' do
      let(:user) { nil }

      it 'returns false' do
        expect(MainTabs.selected_any?(user)).to be_falsey
      end
    end
  end
end

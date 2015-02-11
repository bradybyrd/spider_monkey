require 'spec_helper'

describe SeriesEnvironmentsPresenter do
  let(:user) { stub_model(User) }

  describe '#to_sym' do
    it 'returns symbol presentation of subject' do
      series = stub_model(DeploymentWindow::Series)
      expect(SeriesEnvironmentsPresenter.new(series, user).to_sym).to eq(:"deployment_window/series")
    end
  end

  describe '#listable_props' do
    it 'returns array of indicated subject properties' do
      series = double('series', environment_names: 'env1, env2')
      expect(SeriesEnvironmentsPresenter.new(series, user).listable_props).to eq(['env1', 'env2'])
    end
  end

  describe '#linkable_props' do
    it 'returns array of indicated subject properties' do
      series = double('series', environment_names: 'env1, env2', behavior: 'open')
      environment = double('environment', apps: [], name: '[default]')
      event = double('event', id: 1, in_past?: false, state: 'created', series: series, environment: environment)
      SeriesEnvironmentsPresenter.any_instance.stub(:events).and_return([event])
      SeriesEnvironmentsPresenter.any_instance.stub(:title).and_return('title')
      presenter = SeriesEnvironmentsPresenter.new(series, user)

      expect(presenter.linkable_props.first[:name]).to eq('[default]')
      result_data = { id: 1, in_past: false, can_edit: false, can_schedule: false, behavior: 'open', event_state: 'created' }
      result_html_attrs = { data: result_data, class: 'environment-link', title: 'title' }
      expect(presenter.linkable_props.first[:html_attrs]).to eq(result_html_attrs)
    end
  end

  describe '#linkable_props for occurrence' do
    it 'returns array with aasm_state of series' do
      env = create(:environment, name: 'cool_env')
      series = create(:deployment_window_series, :with_occurrences, environment_ids: [env.id], environment_names: env.name)
      occurrence = series.occurrences.first
      presenter = SeriesEnvironmentsPresenter.new(occurrence, user)

      expect(presenter.linkable_props.first[:name]).to eq('cool_env')
      expect(presenter.linkable_props.first[:html_attrs][:data]).to include(aasm_state: series.aasm_state)
    end
  end
end

require 'spec_helper'

describe ListBuilder do
  describe '#display_list' do
    context 'when list does not exceeds permitted length' do
      it 'displays list of names' do
        options = {only_names: true}
        series_environments_presenter = double('presenter', listable_props: ['env_1','env_2'], to_sym: :"deployment_window/series")
        expect(ListBuilder.new(series_environments_presenter, options).display_list).to eq('env_1, env_2')
      end

      it 'displays list of links when app assigned' do
        options = {only_names: false}
        link1 = {name: 'env_1', html_attr: '', applications: [:common_app]}
        user = double('User', apps: [:common_app], 'root?' => false)
        series_environments_presenter = double('presenter', linkable_props: [link1], to_sym: :"deployment_window/series", user: user)
        expect(ListBuilder.new(series_environments_presenter, options).display_list).to eq("<a href=\"javascript:void(0);\">env_1</a>")
      end

      it 'displays list of names when app not assigned' do
        options = {only_names: false}
        link1 = {name: 'env_1', html_attr: '', applications: []}
        user = double('User', apps: [], 'root?' => false)
        series_environments_presenter = double('presenter', linkable_props: [link1], to_sym: :"deployment_window/series", user: user)
        expect(ListBuilder.new(series_environments_presenter, options).display_list).to eq("env_1")
      end
    end

    it 'displays list of links when app not assigned, but root user' do
      options = {only_names: false}
      link1 = {name: 'env_1', html_attr: '', applications: [:common_app]}
      user = double('User', apps: [], 'root?' => true)
      series_environments_presenter = double('presenter', linkable_props: [link1], to_sym: :"deployment_window/series", user: user)
      expect(ListBuilder.new(series_environments_presenter, options).display_list).to eq("<a href=\"javascript:void(0);\">env_1</a>")
    end

    context 'when list exceeds permitted length' do
      it 'appends additional elements' do
        options = {only_names: true}
        series_environments_presenter = double('presenter', listable_props: ['env_1','env_2', 'env'*50], to_sym: :"deployment_window/series")
        result = "<span>env_1, env_2, <a href=\"javascript:void(0);\" class=\"more-links\">...(1)</a></span><span class=\"hidden\">env_1, env_2, #{'env'*50}</span>"
        expect(ListBuilder.new(series_environments_presenter, options).display_list).to eq(result)
      end
    end
  end
end

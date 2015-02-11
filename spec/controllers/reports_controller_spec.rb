require 'spec_helper'

describe ReportsController do
  shared_examples 'prepare_calendar' do |action|
    describe '@width' do
      context 'params[:width].present?' do
        let(:valid_params) { { width: '999' } }

        it 'assigns width' do
          get action, valid_params
          assigns(:width).should == 999
        end
      end

      ##### ##### #####

      context 'params[:screen_resolution].present?' do
        let(:valid_params) { { screen_resolution: '888' } }

        it 'assigns width' do
          get action, valid_params
          assigns(:width).should == 888
        end
      end

      ##### ##### #####

      context 'neither width nor screen_resolution passed' do
        let(:valid_params) { {} }

        it 'assigns width' do
          get action, valid_params
          assigns(:width).should be_nil
        end
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe 'params[:filters]' do
      let(:filter_params) { { 'beginning_of_calendar' => start_date.strftime('%m/%d/%Y'),
                              'end_of_calendar' => finish_date.strftime('%m/%d/%Y') } }

      it 'sets params' do
        params = valid_params.merge({ filters: filter_params })
        get action, params
        controller.params[:filters].should == { 'beginning_of_calendar' => start_date,
                                                'end_of_calendar' => finish_date }
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '@report_type' do
      it 'assigns' do
        get action, valid_params
        assigns(:report_type).should == action
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '#set_filter_session' do
      context 'filter params are present' do
        let(:filter_params) { { 'beginning_of_calendar' => start_date.strftime('%m/%d/%Y'),
                                'end_of_calendar' => finish_date.strftime('%m/%d/%Y') } }

        it 'resets filter session' do
          params = valid_params.merge({ filters: filter_params }).merge({ 'reset_filter_session' => 'true' })
          get action, params
          session[action.to_sym].should be_empty
          session[:scale_unit].should be_empty
        end

        it 'sets session' do
          get action, valid_params.merge({ filters: filter_params, scale_unit: 'm' })
          session[action.to_sym].should include({ filters: { 'beginning_of_calendar' => start_date,
                                                             'end_of_calendar' => finish_date } })
          session[:scale_unit].should == 'm'
        end
      end

      ##### ##### #####

      context 'filter params are not present' do
        it 'does not set session' do
          get action, valid_params
          session[action.to_sym].should be_nil
          session[:scale_unit].should be_nil
        end
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '@open_filter' do
      it 'assigns' do
        get :toggle_filter, open_filter: 'true'
        get action, valid_params
        assigns(:open_filter).should be_truthy
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '#set_calender_session' do
      let(:filter_params) { { 'beginning_of_calendar' => start_date.strftime('%m/%d/%Y'),
                              'end_of_calendar' => finish_date.strftime('%m/%d/%Y') } }

      it 'sets calendar dates session' do
        get action, valid_params.merge({ filters: filter_params })
        assigns(:beginning_of_calendar).should == start_date
        assigns(:end_of_calendar).should == finish_date
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '@selected_options' do
      context 'filters' do
        it 'assigns' do
          get action, valid_params.merge({ filters: { some: :values } })
          assigns(:selected_options).should == { 'some' => 'values' }
        end
      end

      context 'no filters' do
        it 'assigns {}' do
          get action, valid_params
          assigns(:selected_options).should == {}
        end
      end
    end

    ##### ##### #####
    ##### ##### #####

    describe '#initialize_fusion_chart' do
      it 'initializes chart' do
        get action, valid_params
        assigns(:fusionchart).should be_an_instance_of FusionChart
      end
    end
  end

  shared_examples 'clear_filter' do |action|
  #   let(:keys) { ReportsController::FILTER_DATES_KEYS[action] }

  #   context 'commit "Clear Filter"' do
  #     it 'sets false into session' do
  #       # keys = ReportsController::FILTER_DATES_KEYS[action]
  #       session[keys.first] = 123
  #       session[keys.second] = 456

  #       post action, valid_params.merge({ commit: 'Clear Filter' })

  #       session[keys.first].should be_falsey
  #       session[keys.second].should be_falsey
  #     end
  #   end

  #   context 'no proper commit' do
  #     it 'leaves as is' do
  #       # keys = ReportsController::FILTER_DATES_KEYS[action]
  #       session[keys.first] = 123
  #       session[keys.second] = 456

  #       post action, valid_params

  #       session[keys.first].should == 123
  #       session[keys.second].should == 456
  #     end
  #   end
  end

  shared_examples 'render_index' do |action|
    context 'params[:p].present?' do
      it 'yields execution' do
        controller.should_receive action
        get action, p: '1'
      end
    end

    context 'params[:r].present?' do
      it 'yields execution' do
        controller.should_receive action
        get action, r: '1'
      end
    end

    context 'filter' do
      it 'yields execution' do
        controller.should_receive action
        get action, commit: 'Filter'
      end
    end

    context 'params[:q].blank?' do
      it 'renders index' do
        controller.should_not_receive action
        get action, {}
        response.should render_template :index
      end
    end
  end

  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####

  let(:valid_render_index_params) { { p: 'any value' } }
  let(:valid_params) { valid_render_index_params.merge({ width: '999' }) }
  let(:start_date) { (Time.now + 1.day).to_date }
  let(:finish_date) { (Time.now + 2.days).to_date }

  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####

  describe 'GET release_calendar' do
    include_examples 'prepare_calendar', 'release_calendar'
    include_examples 'clear_filter', 'release_calendar'
    include_examples 'render_index', 'release_calendar'

    before {
      FusionChart.any_instance.stub(:release_calendar).and_return([ calendar_data, start_date, finish_date, plans ])
    }

    let(:calendar_data) { [ 'some', 'data', 'no matter' ] }
    let(:plans) { [] }

    it 'assigns @release_calendar' do
      get :release_calendar, valid_params
      assigns(:release_calendar).should be
    end

    it 'stores start and finish dates' do
      get :release_calendar, valid_params
      session[:rel_start].should == start_date
      session[:rel_end].should == finish_date
    end

    context '@release_calendar.empty?' do
      let(:calendar_data) { [] }

      it 'sets flash notice' do
        get :release_calendar, valid_params
        flash[:notice].should match 'No matching records'
      end
    end

    it 'renders index' do
      get :release_calendar, valid_params
      response.should render_template('index')
    end

    context 'xhr?' do
      context '@release_calendar.present?' do
        let(:calendar_data) { ['some', 'data'] }

        it 'renders partial' do
          xhr :get, :release_calendar, valid_params
          response.should render_template('release_calendar')
        end
      end
    end
  end

  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####
  ##### ##### ##### ##### #####

  describe 'GET environment_calendar' do
    include_examples 'prepare_calendar', 'environment_calendar'
    include_examples 'clear_filter', 'environment_calendar'
    include_examples 'render_index', 'environment_calendar'

    before {
      FusionChart.any_instance.stub(:environment_calendar).and_return(environment_calendar)
    }

    let(:environment_calendar) { [ 'some', 'data', 'no matter' ] }

    it 'assigns @environment_calendar' do
      get :environment_calendar, valid_params
      assigns(:environment_calendar).should be
    end

    it 'renders partial' do
      xhr :get, :environment_calendar, valid_params
      response.should render_template('environment_calendar')
    end

    context '@environment_calendar.empty?' do
      let(:environment_calendar) { [] }

      it 'sets flash notice' do
        get :environment_calendar, valid_params
        flash[:notice].should match 'No matching records'
      end
    end
  end
end

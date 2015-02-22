require 'spec_helper'

describe ReportsController, type: :controller do
  context '#index' do
    it 'renders template index' do
      get :index, report_type: 'volume_report'

      expect(response).to render_template('index')
    end

    it 'clears filters for release calendar' do
      get :index, { report_type: 'release_calendar',
                    commit: 'Clear Filter',
                    width: '1024' }

      expect(session[:rel_start]).to be_falsey
      expect(session[:rel_end]).to be_falsey
    end

    it 'clears filters for release calendar' do
      get :index, { report_type: 'environment_calendar',
                    commit: 'Clear Filter',
                    width: '1024' }

      expect(session[:env_start]).to be_falsey
      expect(session[:env_end]).to be_falsey
    end

    it "returns flash 'No mathing records'" do
      get :index, { report_type: 'volume_report',
                    width: '1024' }

      expect(flash[:notice]).to include('No matching records')
    end

    it "renders partial 'release_calendar'" do
      get :index, { report_type: 'release_calendar',
                    width: '1024',
                    p: true }

      expect(response).to render_template(partial: '_release_calendar')
    end

    it "renders partial 'environment_calendar'" do
      get :index, { report_type: 'environment_calendar',
                    width: '1024',
                    r: true }

      expect(response).to render_template(partial: '_environment_calendar')
    end

    it "renders partial 'process_volume'" do
      get :index, { report_type: 'volume_report',
                    width: '1024',
                    q: true }
      expect(response).to render_template(partial: 'fusioncharts/_process_volume')
    end

    it "renders partial 'time_to_complete'" do
      get :index, { report_type: 'time_to_complete',
                    width: '1024',
                    q: true}
      expect(response).to render_template(partial: 'fusioncharts/_time_to_complete')
    end

    it "renders partial 'problem_trend'" do
      get :index, { report_type: 'problem_trend_report',
                    width: '1024',
                    q: true }
      expect(response).to render_template(partial: 'fusioncharts/_problem_trend')
    end

    it "renders partial 'time_of_problem'" do
      get :index, { report_type: 'time_of_problem',
                    width: '1024',
                    q: true}
      expect(response).to render_template(partial: 'fusioncharts/_time_of_problem')
    end

    context '#set_filter_session' do
      specify 'reset_filter_session' do
        get :index, { report_type: 'release_calendar',
                      reset_filter_session: 'true',
                      filters: { beginning_of_calendar: '01/10/2013',
                                 end_of_calendar: '12/10/2013'}}

        expect(session[:scale_unit]).to be_empty
      end

      specify 'scale_unit eql params' do
        get :index, { report_type: 'release_calendar',
                      filters: { beginning_of_calendar: '01/10/2013',
                                 end_of_calendar: '12/10/2013' },
                      scale_unit: 'scaling' }

        expect(session[:scale_unit]).to eq 'scaling'
      end

      specify 'delete beginning and end date from params' do
        get :index, { report_type: 'volume_report',
                      scale_unit: 'scaling',
                      filters: {} }
        expect(assigns(:beginning_of_calendar)).to be_nil
        expect(assigns(:end_of_calendar)).to be_nil
      end

      specify 'set beginning and end date from session' do
        session[:volume_report] = {filters: { 'beginning_of_calendar' => '01/10/2013',
                                              'end_of_calendar' => '12/10/2013'}}

        get :index, { report_type: 'volume_report',
                      scale_unit: 'scaling',
                      filters: {} }

        expect(assigns(:beginning_of_calendar)).to eq '01/10/2013'
        expect(assigns(:end_of_calendar)).to eq '12/10/2013'
      end
    end

    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :index,
                                                params:            { report_type: 'volume_report' },
                                                ability_object:    :reports_tab

      it_behaves_like 'authorizable', controller_action: :index,
                                      params:            { report_type: 'volume_report' },
                                      ability_action: :view,
                                      subject: :volume_report

      it_behaves_like 'authorizable', controller_action: :index,
                                      params:            { report_type: 'time_to_complete' },
                                      ability_action: :view,
                                      subject: :time_to_complete_report

      it_behaves_like 'authorizable', controller_action: :index,
                                      params:            { report_type: 'problem_trend_report' },
                                      ability_action: :view,
                                      subject: :problem_trend_report

      it_behaves_like 'authorizable', controller_action: :index,
                                      params:            { report_type: 'time_of_problem' },
                                      ability_action: :view,
                                      subject: :time_to_problem_report
    end
  end

  it '#environment_options' do
    app = create(:app)
    env = create(:environment)
    create(:application_environment, app: app, environment: env)

    get :environment_options, app_id: app.id

    expect(response.body).to include(env.name)
  end

  it '#requests' do
    test_request = create(:request)

    get :requests, request_ids: test_request.id.to_s

    expect(response).to render_template(partial: '_requests_list')
  end

  context '#toggle_filter' do
    specify 'report_filter true' do
      get :toggle_filter, open_filter: 'true'

      expect(session[:open_report_filter]).to be_truthy
    end

    specify 'report_filter false' do
      get :toggle_filter

      expect(session[:open_report_filter]).to be_false
    end
  end

  it '#generate_csv' do
    User.stub(:find).and_return(@user)
    test_request = create(:request)

    get :generate_csv, { request_ids: test_request.id.to_s,
                         format: 'csv'}
    expect(response.body).to include(test_request.number.to_s)
  end

  it '#set_resolution_session' do
    get :set_resolution_session, screen_width: '1024'

    expect(response.body).to include('1024')
  end
end

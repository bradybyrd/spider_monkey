require 'spec_helper'

describe DashboardController, type: :controller do
  it '#self_services' do
    get :self_services
    response.should render_template('dashboard/self_services')
  end

  context '#recent_activities' do
    it 'renders recent_activities template and return paginated records' do
      pending 'Recent activity don`t in use in project`'
      @activities = 5.times.collect { create(:activity) }
      get :recent_activities, {per_page: 4, page: 1}
      @activities[0..3].each { |el| assigns(:recent_activities).should include(el) }
      assigns(:recent_activities).should_not include(@activities[4])
      response.should render_template('recent_activities')
    end
  end

  context '#recent_requests' do
    it 'returns paginated records and renders template' do
      requests = 21.times.collect { create(:request) }
      requests.reverse!
      request_ids = []
      requests.each { |el| request_ids << el.number }

      get :recent_requests, { request_ids: request_ids }

      requests[0..19].each { |el| expect(assigns(:requests)).to include(el) }
      expect(assigns(:requests)).to_not include(requests[20])
      expect(response).to render_template('dashboard/index')
    end

    it 'renders partial requests' do
      xhr :get, :recent_requests, {request_ids: [create(:request).number]}

      expect(response).to render_template(partial: 'dashboard/self_services/_requests')
    end
  end

  describe '#index' do
    it 'returns paginated requests and renders template self_services' do
      requests_per_page = 2
      requests = create_list(:request, requests_per_page + 1)
      requests_on_current_page = requests[0..requests_per_page]
      requests_on_other_page = requests[requests_per_page..-1]

      xhr :get, :index, {per_page: requests_per_page}

      paginated_requests = assigns(:request_dashboard)[:requests]
      expect(paginated_requests).to match_array(requests_on_current_page)
      expect(paginated_requests).to_not match_array(requests_on_other_page)
      expect(response).to render_template('dashboard/self_services')
    end

    it 'searches requests by name when "reqname" prefix given' do
      request1 = create(:request, name: 'Dev1')
      request2 = create(:request)

      xhr :get, :index, {q: 'reqname:Dev'}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
      expect(requests).to_not include(request2)
    end

    it 'search requests by name' do
      request1 = create(:request, name: 'Some Request')

      xhr :get, :index, {q: 'Some Request'}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
    end

    it 'searches requests by number and render partial requests' do
      request1 = create(:request)
      request2 = create(:request)

      xhr :get, :index, {q: request1.number}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
      expect(requests).to_not include(request2)
      expect(response).to render_template(partial: 'dashboard/self_services/_requests')
    end

    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :self_services,
                      ability_object: :dashboard_tab
    end
  end

  describe '#request_dashboard' do
    it 'returns paginated requests and renders template self_services' do
      requests_per_page = 2
      requests = create_list(:request, requests_per_page + 1)
      requests_on_current_page = requests[0..requests_per_page]
      requests_on_other_page = requests[requests_per_page..-1]

      get :request_dashboard, {per_page: requests_per_page, show_all: '1'}

      paginated_requests = assigns(:request_dashboard)[:requests]
      expect(paginated_requests).to match_array(requests_on_current_page)
      expect(paginated_requests).to_not match_array(requests_on_other_page)
      expect(response).to render_template('index')
    end

    it 'searches requests by name when "reqname" prefix given' do
      request1 = create(:request, name: 'Dev1')
      request2 = create(:request)

      get :request_dashboard, {q: 'reqname:Dev', show_all: '1'}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
      expect(requests).to_not include(request2)
    end

    it 'searches requests by number when "reqid" prefix given' do
      request1 = create(:request)
      request2 = create(:request)

      get :request_dashboard, {q: "reqid:#{request1.number}", show_all: '1'}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
      expect(requests).to_not include(request2)
    end

    it 'search requests by name' do
      request1 = create(:request, name: 'Some Request')

      get :request_dashboard, {q: 'Some Request', show_all: '1'}

      expect(assigns(:request_dashboard)[:requests]).to include(request1)
    end

    it 'searches requests by number' do
      request1 = create(:request)
      request2 = create(:request)

      xhr :get, :request_dashboard, {q: request1.number, show_all: '1'}

      requests = assigns(:request_dashboard)[:requests]
      expect(requests).to include(request1)
      expect(requests).to_not include(request2)
      expect(response).to render_template(partial: 'dashboard/self_services/_requests')
    end

    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :request_dashboard,
                      params: {show_all: '1'},
                      ability_object: :requests_tab
    end
  end

  context '#promotions' do
    it 'renders partial promotions and returns requests' do
      requests = 21.times.collect{create(:request, promotion: true, requestor: @user)}

      xhr :get, :promotions, { filters: {ignore_month: '', sort_scope: 'id', sort_direction: 'asc'} }

      paginated_requests = assigns(:request_dashboard)[:requests]
      requests[0..19].each { |el| expect(paginated_requests).to include(el) }
      expect(paginated_requests).to_not include(requests[20])
      expect(response).to render_template(partial: 'dashboard/self_services/_promotions')
    end

    it 'renders template self_services and returns apps' do
      apps = 7.times.collect { create(:app) }
      apps.sort_by! { |el| el.name }

      get :promotions

      my_apps = assigns(:my_applications)
      apps[0..5].each { |el| expect(my_apps).to include(el) }
      expect(my_apps).to_not include(apps[6])
      expect(response).to render_template('dashboard/self_services')
    end
  end

  context '#steps_for_request_ajax' do
    before(:each) do
      @request1 = create(:request, owner: @user)
      @parent_step = create(:step, request: @request1, owner: @user)
      @step = create(:step, request: @request1, parent: @parent_step, owner: @user)
    end

    it 'returns request preferences' do
      preference = @user.request_list_preferences.create!(text: 'text',
                                                           position: 1,
                                                           active: true)
      get :steps_for_request_ajax, {request_id: @request1.id,
                                    session_filter_var: 'dashboard_self_services'}
      expect(assigns(:request_active_list_preferences)).to include(preference)
    end

    it 'renders partial' do
      get :steps_for_request_ajax, {request_id: @request1.id,
                                    session_filter_var: 'dashboard_self_services'}
      expect(response).to render_template(partial: 'steps/_dashboard_list')
    end

    context 'with filter' do
      before(:each) do
        pending "undefined method `owned_by_user' and `owned_by_user_including_groups'"
        controller.should_receive(:render).with({partial: 'steps/dashboard_list',
                                                 locals: {req: @request1, steps: [@parent_step, @step]}})
        controller.should_receive(:render)
      end

      it 'clear' do
        get :steps_for_request_ajax, {request_id: @request1.id,
                                      session_filter_var: 'dashboard_self_services'}
      end

      it 'by user id' do
        session[:dashboard_self_services] = {user_id: @user.id,
                                             include_groups: 'false'}
        get :steps_for_request_ajax, {request_id: @request1.id,
                                      session_filter_var: 'dashboard_self_services'}
      end

      it 'include groups' do
        session[:dashboard_self_services] = {user_id: @user.id,
                                             include_groups: 'true'}
        get :steps_for_request_ajax, {request_id: @request1.id,
                                      session_filter_var: 'dashboard_self_services'}
      end
    end
  end

  it '#my_applications' do
    apps = 7.times.collect { create(:app) }
    apps.sort_by! { |el| el.name }

    xhr :get, :my_applications, {page: 1}

    apps[0..5].each { |el| expect(assigns(:my_applications)).to include(el) }
    expect(assigns(:my_applications)).to_not include(apps[6])
    expect(response).to render_template(partial: 'dashboard/self_services/tables/_my_applications')
  end

  it '#my_environments' do
    envs = 7.times.collect { create(:environment) }

    xhr :get, :my_environments, {page: 1}

    envs[0..5].each { |el| expect(assigns(:my_environments)).to include(el) }
    expect(assigns(:my_environments)).to_not include(envs[6])
    expect(response).to render_template(partial: 'dashboard/self_services/tables/_my_environments')
  end

  it '#my_servers' do
    servers = 7.times.collect { create(:server) }
    servers.sort_by! { |el| el.name }

    xhr :get, :my_servers, {page: 1}

    servers[0..5].each { |el| expect(assigns(:my_servers)).to include(el) }
    expect(assigns(:my_servers)).to_not include(servers[6])
    expect(response).to render_template(partial: 'dashboard/self_services/tables/_my_servers')
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#self_services' do
        include_context 'mocked abilities', :cannot, :view, :dashboard_tab
        specify { get :self_services }
      end

      context '#promotions' do
        include_context 'mocked abilities', :cannot, :view, :dashboard_promotions
        specify { get :promotions }
      end

      context '#my_applications' do
        include_context 'mocked abilities', :cannot, :view, :my_applications
        specify { get :my_applications }
      end

      context '#my_environments' do
        include_context 'mocked abilities', :cannot, :view, :my_environments
        specify { get :my_environments }
      end

      context '#my_servers' do
        include_context 'mocked abilities', :cannot, :view, :my_servers
        specify { get :my_servers }
      end
    end
  end
end

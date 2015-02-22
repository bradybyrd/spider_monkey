require 'spec_helper'

describe NotificationTemplatesController, type: :controller do
  let(:notification_template) { create(:notification_template) }

  it '#index' do
    notification_template
    get :index

    expect(assigns(:notification_templates)).to include(notification_template)
    expect(response).to render_template('index')
  end

  context '#show' do
    it 'success' do
      get :show, { id: notification_template.id }

      expect(response).to render_template('show')
    end

    it 'return flash error and redirects' do
      @request.env["HTTP_REFERER"] = '/index'

      get :show, id: '-1'

      expect(flash[:error]).to include('not found')
      expect(response).to redirect_to('/index')
    end
  end

  it '#new' do
    pending "undefined local variable or method `parent_request_id' for Request"
    request1 = create(:request)
    create(:step, :request => request1)

    get :new

    expect(response).to render_template('new')
  end

  it '#edit' do
    get :edit, { id: notification_template.id }

    expect(response).to render_template('edit')
  end

  context '#create' do
    before(:each) do
      @params = {notification_template: { title: 'User Forgot Login',
                                          subject: 'A subject line',
                                          description: 'A testing template',
                                          body: 'My template: {{hello_world}}',
                                          event: 'exception_raised',
                                          format: 'text/plain',
                                          active: true}}
    end

    it 'success' do
      expect{ post :create, @params
            }.to change(NotificationTemplate, :count).by(1)
      expect(response.code).to eq '302'
    end

    it 'fails' do
      notification_template
      NotificationTemplate.stub(:new).and_return(notification_template)
      notification_template.stub(:save).and_return(false)

      post :create, @params

      expect(response).to render_template('new')
    end
  end

  context '#update' do
    it 'success' do
      put :update, { id: notification_template.id,
                     notification_template: { title: 'Changed' }}

      notification_template.reload
      expect(notification_template.title).to eq 'Changed'
      expect(response).to redirect_to(notification_template)
    end

    it 'fails' do
      NotificationTemplate.stub(:find).and_return(notification_template)
      notification_template.stub(:update_attributes).and_return(false)

      put :update, { id: notification_template.id,
                     notification_template: { title: 'Changed' }}

      expect(response).to render_template('edit')
    end
  end

  it '#destroy' do
    notification_template
    expect{ delete :destroy, { id: notification_template.id }
          }.to change(NotificationTemplate, :count).by(-1)
  end
end

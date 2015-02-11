require 'spec_helper'

describe NotificationTemplatesController, :type => :controller do
  before(:each) { @notification_template = create(:notification_template) }

  it "#index" do
    get :index
    assigns(:notification_templates).should include(@notification_template)
    response.should render_template('index')
  end

  context "#show" do
    it "success" do
      get :show, {:id => @notification_template.id}
      response.should render_template('show')
    end

    it "return flash error and redirects" do
      @request.env["HTTP_REFERER"] = '/index'
      get :show, {:id => '-1'}
      flash[:error].should include('not found')
      response.should redirect_to('/index')
    end
  end

  it "#new" do
    pending "undefined local variable or method `parent_request_id' for Request"
    @request1 = create(:request)
    @step = create(:step, :request => @request1)
    get :new
    response.should render_template('new')
  end

  it "#edit" do
    get :edit, {:id => @notification_template.id}
    response.should render_template('edit')
  end

  context "#create" do
    before(:each) do
      @params = {:notification_template => {:title => 'User Forgot Login',
                                            :subject => 'A subject line',
                                            :description => 'A testing template',
                                            :body => 'My template: {{hello_world}}',
                                            :event => 'exception_raised',
                                            :format => "text/plain",
                                            :active => true}}
    end

    it "success" do
      expect{post :create, @params
            }.to change(NotificationTemplate, :count).by(1)
      response.code.should eql('302')
    end

    it "fails" do
      NotificationTemplate.stub(:new).and_return(@notification_template)
      @notification_template.stub(:save).and_return(false)
      post :create, @params
      response.should render_template('new')
    end
  end

  context "#update" do
    it "success" do
      put :update, {:id => @notification_template.id,
                    :notification_template => {:title => 'Changed'}}
      @notification_template.reload
      @notification_template.title.should eql('Changed')
      response.should redirect_to(@notification_template)
    end

    it "fails" do
      NotificationTemplate.stub(:find).and_return(@notification_template)
      @notification_template.stub(:update_attributes).and_return(false)
      put :update, {:id => @notification_template.id,
                    :notification_template => {:title => 'Changed'}}
      response.should render_template('edit')
    end
  end

  it "#destroy" do
    expect{delete :destroy, {:id => @notification_template.id}
          }.to change(NotificationTemplate, :count).by(-1)
  end
end

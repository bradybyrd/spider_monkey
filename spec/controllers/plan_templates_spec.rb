require 'spec_helper'

describe PlanTemplatesController, :type => :controller do
  ### TODO check controller method to returning flashes and replace find_by_id by find method
  before (:each) { @plan_template = create(:plan_template) }

  #### common values
  model = PlanTemplate
  factory_model = :plan_template
  can_archive = true
  #### values for index
  models_name = 'plan_templates'
  model_index_path = 'index'
  be_sort = true
  per_page = 10
  index_flash = "No Plan Template"
  #### values for edit
  model_edit_path = '/environment/metadata/plan_templates'
  edit_flash = 'does not exist'
  http_refer = '/index'
  #### values for destroy
  model_delete_path = '/environment/metadata/plan_templates'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  pending "undefined method `include?' for nil:NilClass" do
    it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  end
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  it_should_behave_like 'status of objects controller', factory_model, models_name

  context "#create" do
    it "success" do
      post :create, {:plan_template => {:name => "PlanTemplate1",
                                        :template_type => 'continuous_integration'}}
      response.code.should eql('302')
    end

    it "fails" do
      PlanTemplate.stub(:new).and_return(@plan_template)
      @plan_template.stub(:save).and_return(false)
      post :create, {:plan_template => {:name => "PlanTemplate1",
                                       :template_type => 'continuous_integration'}}
      response.should render_template('new')
    end
  end

  context "#update" do
    it "valid params" do
      put :update, {:id => @plan_template.id,
                    :plan_template => {:name => "PlanTemplate_changed"}
                   }
      @plan_template.reload
      @plan_template.name.should eql("PlanTemplate_changed")
      flash[:notice].should include('successfully')
      response.should redirect_to(plan_template_path(@plan_template))
    end

    it "invalid params" do
      PlanTemplate.stub(:find_by_id).and_return(@plan_template)
      @plan_template.stub(:update_attributes).and_return(false)
      put :update, {:id => @plan_template.id}
      response.should render_template('edit')
    end
  end

  context "#show" do
    it "success html " do
      get :show, {:id => @plan_template.id}
      response.should render_template('show')
    end

    it "success json " do
      get :show, {:id => @plan_template.id,
                  :format => 'json'}
      response.should render_template(:json => @plan_template)
    end

    it "doesn`t found record" do
      get :show, {:id => '-1'}
      response.status.should eql(406)
    end
  end
end

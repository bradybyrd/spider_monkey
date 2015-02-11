require 'spec_helper'

describe PackageContentsController, :type => :controller do
  #### common values
  model = PackageContent
  factory_model = :package_content
  can_archive = true
  #### values for index
  models_name = 'package_contents'
  model_index_path = 'index'
  be_sort = false
  per_page = 20
  index_flash = 'No Package Content'
  #### values for edit
  model_edit_path = '/environment/metadata/package_contents'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for create
  model_create_path = '/environment/metadata/package_contents'
  create_params =  {:package_content => {:name => "PG1"}}
  #### values for update
  update_params = {:name => "PG1"}
  #### values for destroy
  model_delete_path = '/environment/metadata/package_contents'
  pending 'returns bad data format' do
    it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  end
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD POST create", model, factory_model, model_create_path, create_params)
  it_should_behave_like("CRUD PUT update", model, factory_model, update_params)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  it "#reorder" do
    @pgcontent = create(:package_content)
    put :reorder, {:id => @pgcontent.id,
                   :package_content => {:insertion_point => '2'}}
    PackageContent.find(@pgcontent.id).insertion_point.should eql(2)
    response.should render_template(:partial => 'package_contents/_package_content')
  end
end

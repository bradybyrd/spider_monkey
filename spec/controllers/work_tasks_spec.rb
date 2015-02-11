require "spec_helper"

describe WorkTasksController, :type => :controller do
  #### common values
  model = WorkTask
  factory_model = :work_task
  can_archive = true
  #### values for index
  models_name = 'work_tasks'
  model_index_path = 'index'
  be_sort = false
  per_page = 20
  index_flash = "No Work Task"
  #### values for edit
  model_edit_path = '/index'
  edit_flash = 'Work Task was not found'
  http_refer = true
  #### values for create
  model_create_path = '/environment/metadata/work_tasks'
  create_params =  {:work_task => {:name => 'WT1'}}
  #### values for update
  update_params = {:name => 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/metadata/work_tasks'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD POST create", model, factory_model, model_create_path, create_params)
  it_should_behave_like("CRUD PUT update", model, factory_model, update_params)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  it "#reorder" do
    @work_task = create(:work_task)
    put :reorder, {:id => @work_task.id,
                   :work_task => {:insertion_point => 3}}
    @work_task.reload
    @work_task.insertion_point.should eql(3)
    response.should render_template(:partial => 'work_tasks/_work_task')
  end
end

require 'spec_helper'

describe PackageInstancesController do
  context 'GET to #index' do
    it 'displays a list of PackagesInstances the User can see' do
      package = create(:package)
      accessible_active_instance = create :package_instance,
        package: package,
        active: true
      accessible_inactive_instance = create :package_instance,
        package: package,
        active: false
      inaccessible_instance = create(:package_instance)

      get :index, package_id: package.id

      expect(assigns(:active_package_instances)).
        to eq [accessible_active_instance]
      expect(assigns(:inactive_package_instances)).
        to eq [accessible_inactive_instance]
    end

    it 'shows index with empty page parameter' do
      package = create(:package)
      get :index, {package_id: package.id, page: ''}
      expect(response.code).to eq '200'
    end
  end

  def index
    page.find('#search_result')
  end

  def have_package_instance(instance)
    have_css('.name', text: instance.name)
  end

  context '#create' do
    before(:each) do
      @test_package = create(:package)
      @test_package.name = 'TestPackage2'
      @test_package.next_instance_number = 200
      @test_package.instance_name_format = 'updated format'
      @test_package.save
      request.env['HTTP_REFERER'] = '/package_instance'

      User.current_user = User.find_by_login('admin')

      @test_package_instance = create(:package_instance, package: @test_package, active: true, name: 'test')
      @test_package_instance.save
    end

    it 'errors_on_name_too_long' do
      post :create, { package_id: @test_package.id, package_instance: { name: 'n' * 256 }}
      expect(flash[:error]).to include('Error creating package instance')
    end

    it 'errors_on_name_supplied by empty' do
      post :create, { package_id: @test_package.id, package_instance: { name: '' }}
      expect(flash[:error]).to include('Error creating package instance')
    end

    it 'success' do
      post :create, { package_id: @test_package.id, package_instance: { name: 'myname' }}
      expect(flash[:notice]).to include('successfully')
    end
  end

  context '#update' do
    before(:each) do
      @test_package = create(:package)
      @test_package.name = 'TestPackage2'
      @test_package.next_instance_number = 200
      @test_package.instance_name_format = 'updated format'
      @test_package.save
      request.env['HTTP_REFERER'] = '/package_instance'

      User.current_user = User.find_by_login('admin')

      @test_package_instance = create(:package_instance, package: @test_package, active: true, name: 'test2')
      @test_package_instance.save

    end

    it 'updates instance name' do
      put :update, { id: @test_package_instance.id, package_instance: { name: 'newName' }}

      @test_package_instance.reload
      @test_package_instance.name.should eql('newName')
      expect(flash[:notice]).to eq I18n.t('package_instance.updated')
    end
  end

  describe 'delete inactive and activate' do
    before(:each) do
      @test_package = create(:package)
      @test_package.name = 'TestPackage2'
      @test_package.next_instance_number = 200
      @test_package.instance_name_format = 'updated format'
      @test_package.save

      User.current_user = User.find_by_login('admin')

      @test_package_instance = create(:package_instance, package: @test_package, active: true, name: 'test2')
      @test_package_instance.save
    end

    it 'delete a package instance' do
      expect{ delete :destroy, { id: @test_package_instance.id }
            }.to change(PackageInstance, :count).by(-1)
    end

    it 'inactivate a package instance' do
      post :deactivate, { id: @test_package_instance }

      @test_package_instance.reload
      expect( @test_package_instance ).not_to be_active
    end

    it 'activate a package instance' do
      @test_package_instance.active = false

      post :activate, { id: @test_package_instance }

      @test_package_instance.reload
      expect( @test_package_instance ).to be_active
    end
  end
end

shared_examples 'status of objects controller' do |factory_model, models_name, method = :index|
  let(:normal_user) {create(:user, :non_root, :with_role_and_group, roles: [ create(:role, name: 'deployment_coordinator') ])}
  let(:admin)       {create(:user, :with_role_and_root_group)}

  describe '#index with drafts' do
    context 'lists' do
      before(:each) do
        @normal_user_items = create_pair(factory_model, created_by: normal_user.id, aasm_state: 'draft')
        @admin_items = create_pair(factory_model, created_by: admin.id, aasm_state: 'draft')

        GlobalSettings.stub(:automation_enabled?).and_return(true)
        DeploymentWindow::Series.stub(:fetch_depends_on_user).and_return(DeploymentWindow::Series.visible_in_index)
        DeploymentWindow::Series.any_instance.stub_chain(:filter, :search).and_return(DeploymentWindow::Series.visible_in_index)
        RequestTemplate.stub(:templates_for).and_return(RequestTemplate.unarchived)
        controller.stub(:authorize!).and_return(true)
      end

      it "only those owned by normal user" do
        sign_in normal_user
        get method, {}

        @normal_user_items.each{ |item| expect(assigns(models_name)).to include(item) }
        @admin_items.each{ |item| expect(assigns(models_name)).not_to include(item) }

        sign_out normal_user
      end

      it "all for admin user" do
        sign_in admin
        get method, {}

        @normal_user_items.each{ |item| expect(assigns(models_name)).to include(item) }
        @admin_items.each{ |item| expect(assigns(models_name)).to include(item) }

        sign_out admin
      end
    end
  end
end

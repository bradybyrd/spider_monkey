require 'spec_helper'

describe BladelogicScriptsController, :type => :controller do
  context 'authorization' do
    context 'authorize fails' do
      before(:each) { @script = create(:bladelogic_script) }
      after { expect(response).to redirect_to root_path }

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { get :new }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { post :create }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { get :edit, id: @script }
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { put :update, id: @script }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, :automation
        specify { delete :destroy, id: @script }
      end

      context '#test_run' do
        include_context 'mocked abilities', :cannot, :test, :automation
        specify { get :test_run, id: @script }
      end
    end
  end

  describe "#bladelogic?" do
    it "returns true" do
      controller.send(:bladelogic?).should be(true)
    end
  end

  describe "#use_template" do
    it "returns bladelogic" do
      controller.send(:use_template).should eql('bladelogic')
    end
  end
end


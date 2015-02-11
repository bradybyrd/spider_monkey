require 'spec_helper'

class ObjectsController < ApplicationController
  include ObjectStateController
end

describe ObjectsController do
  describe '#update_object_state' do
    before do
      routes.draw do
        match 'objects/update_object_state' => 'objects#update_object_state', via: :get
      end
    end

    after do
      Rails.application.reload_routes!
    end

    context 'user does not have permissions to update state of object' do
      it 'does not update state' do
        user = create :old_user
        object = Object.new
        User.any_instance.stub(:can?).with(:update_state, object).and_return(false)
        ObjectsController.any_instance.stub(:find_object).and_return(object)
        allow(object).to receive(:release!)
        sign_in user

        get :update_object_state, transition: 'release'

        expect(object).not_to have_received(:release!)
      end
    end

    context 'user has permissions to update state of object' do
      it 'updates state' do
        user = create :old_user
        object = Object.new
        User.any_instance.stub(:can?).with(:update_state, object).and_return(true)
        ObjectsController.any_instance.stub(:find_object).and_return(object)
        allow(object).to receive(:release!)
        sign_in user

        get :update_object_state, transition: 'release'

        expect(object).to have_received(:release!)
      end
    end
  end
end

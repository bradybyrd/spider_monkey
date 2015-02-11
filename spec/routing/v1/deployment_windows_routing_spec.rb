require 'spec_helper'

describe 'deployment_window namespace routing' do
  describe V1::DeploymentWindow::SeriesController do

    it 'routes to #index' do
      get('/v1/deployment_window/series').should route_to('v1/deployment_window/series#index')
    end

    it 'routes to #show' do
      get('/v1/deployment_window/series/1').should route_to('v1/deployment_window/series#show', :id => '1')
    end

    it 'routes to #create' do
      post('/v1/deployment_window/series').should route_to('v1/deployment_window/series#create')
    end

    it 'routes to #update' do
      put('/v1/deployment_window/series/1').should route_to('v1/deployment_window/series#update', :id => '1')
    end

    it 'routes to #destroy' do
      delete('/v1/deployment_window/series/1').should route_to('v1/deployment_window/series#destroy', :id => '1')
    end

  end
end

require 'spec_helper'

describe PlanStagesController, type: :controller do
  let(:plan_template) { create(:plan_template) }
  let(:plan_stage) { create(:plan_stage, plan_template: plan_template) }

  it '#new' do
    get :new, { plan_template_id: plan_template.id }

    expect(response).to render_template('new', layout: false)
  end

  it '#edit' do
    get :edit, { id: plan_stage.id,
                 plan_template_id: plan_template.id }
    expect(response).to render_template('edit', layout: false)
  end

  context '#create' do
    context 'success' do
      it "returns flash 'success' and ajax redirect" do
        xhr :post, :create, { plan_template_id: plan_template.id,
                              plan_stage: { name: 'Stage1' }}

        expect(flash[:notice]).to include('successfully')
        expect(response).to render_template('misc/redirect')
      end

      it 'redirects to' do
        post :create, { plan_template_id: plan_template.id,
                        plan_stage: { name: 'Stage1' }}

        expect(response).to redirect_to(plan_template_path(plan_template))
      end
    end

    context 'fails' do
      before(:each) do
        plan_template
        PlanTemplate.stub(:find).and_return(plan_template)
        plan_template.stages.stub(:build).and_return(plan_stage)
        plan_stage.stub(:save).and_return(false)
      end

      it 'show validation errors' do
        xhr :post, :create, { plan_template_id: plan_template.id,
                              plan_stage: { name: 'Stage1' }}
        expect(response).to render_template('misc/update_div')
      end

      it 'render action new' do
        post :create, { plan_template_id: plan_template.id,
                        plan_stage: { name: 'Stage1' }}

        expect(response).to render_template('new')
      end
    end
  end

  context '#update' do
    context 'success' do
      it "returns flash 'success' and ajax redirect" do
        xhr :put, :update, { plan_template_id: plan_template.id,
                             id: plan_stage.id,
                             plan_stage: { name: 'Stage1' }}

        expect(flash[:notice]).to include('successfully')
        expect(response).to render_template('misc/redirect')
      end

      it 'redirects to' do
        put :update, { plan_template_id: plan_template.id,
                       id: plan_stage.id,
                       plan_stage: { name: 'Stage1' }}
        expect(response).to redirect_to(plan_template_path(plan_template))
      end
    end

    context 'fails' do
      before(:each) do
        PlanTemplate.stub(:find).and_return(plan_template)
        plan_template.stages.stub(:find).and_return(plan_stage)
        plan_stage.stub(:update_attributes).and_return(false)
      end

      it 'show validation errors' do
        xhr :put, :update, { plan_template_id: plan_template.id,
                             id: plan_stage.id,
                             plan_stage: { name: 'Stage1' }}
        expect(response).to render_template('misc/update_div')
      end

      it 'render action new' do
        put :update, { plan_template_id: plan_template.id,
                       id: plan_stage.id,
                       plan_stage: { name: 'Stage1' }}
        expect(response).to render_template('edit')
      end
    end
  end

  it '#destroy' do
    plan_stage
    expect{ delete :destroy, { plan_template_id: plan_template.id,
                               id: plan_stage.id }
          }.to change(PlanStage, :count).by(-1)
    expect(response).to redirect_to(plan_template)
  end

  it '#reorder' do
    put :reorder, { plan_template_id: plan_template.id,
                    id: plan_stage.id,
                    plan_stage: { position: '2' }}

    plan_stage.reload
    expect(plan_stage.position).to eql(2)
    expect(response).to render_template(:partial => 'plan_stages/_plan_stage')
  end
end
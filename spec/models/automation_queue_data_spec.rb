require 'spec_helper'

describe AutomationQueueData do
  before(:each) { model.stub(:remove_messages).and_return true }
  let(:model)   { AutomationQueueData }

  describe '#clear_queue!' do
    it 'should work well' do
      2.times{create :automation_queue_data}

      expect{model.clear_queue!}.to change(model, :count).to(0)
    end
  end

  describe '#track_queue_data' do
    it 'should create a new queue imprint' do
      model.track_queue_data 1

      model.find_by_step_id(1).should_not be_nil
    end
  end

  describe '#clear_queue_data' do
    it 'should delete a new queue imprint' do
      model.create run_at: Time.now, step_id: 2
      expect{model.clear_queue_data(2)}.to change(model, :count).from(model.count).to(model.count-1)

      model.find_by_step_id(2).should be_nil
    end
  end

  describe '#error_queue_data' do
    let(:queue)   { model.find_by_step_id 1 }
    before(:each) do
      create :automation_queue_data
      model.error_queue_data 1, 'error'
    end

    it 'should increase the attempt count' do
      queue.attempts.should eq 1
    end

    it 'should include the error message' do
      queue.last_error.should eq 'error'
    end

  end

end
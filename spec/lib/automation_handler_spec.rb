require 'spec_helper'

describe AutomationHandler do
  let(:automation_handler) { AutomationHandler.new }
  let(:obj_mock) {mock 'object'}

  describe '#on_message' do
    it 'should work with valid params' do
      body      = {object: obj_mock, method: :some_method, args: [2, some:'params']}
      obj_mock.stub(:some_method).with(2, some: 'params').and_return true
      automation_handler.on_message(body)

      expect(automation_handler.on_message(body)).to be true
    end

    it 'should raise exception in case method was not specified' do
      body = {object: obj_mock, args: [2, {some:'params'}] }

      expect{automation_handler.on_message(body)}.to raise_error(ArgumentError, 'Method not specified')
    end

    it 'should raise exception in case method was not specified' do
      body = {method: :some_method, args: [2, {some:'params'}] }

      expect{automation_handler.on_message(body)}.to raise_error(ArgumentError, 'Object not specified')
    end
  end

  describe '#on_error' do
    let(:exception_message ) { 'omg, it\'s an exception' }

    it 'should raise exception if error_handler not specified' do
      expect{automation_handler.on_error(exception_message)}.to raise_error(RuntimeError, exception_message.inspect)
    end

    it 'should call `error_handler` if specified' do
      options = { error_handler_method: :some_method, args:['ar', 'gs'] }
      automation_handler.instance_variable_set :@options, options
      automation_handler.instance_variable_set :@object, obj_mock
      obj_mock.should_receive(:some_method).with('ar','gs', exception_message.inspect)

      expect{automation_handler.on_error(exception_message)}.to_not raise_error
    end
  end
end

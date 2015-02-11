require 'spec_helper'

describe AuditHandler::MessagesSaver do
  describe '.save' do
    it 'raises not implemented error' do
      expect{AuditHandler::MessagesSaver.save}.to raise_error NotImplementedError
    end
  end
end

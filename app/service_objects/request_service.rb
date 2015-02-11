module RequestService
  class RequestStarter
    attr_accessor :starter

    def initialize(instance)
      @request  = instance
      @starter  = RequestPureStarter.new @request
    end

    def within(sym)
      case sym
        when :run
          @starter = RequestInRunStarter.new @request
        when :request
          @starter = RequestPureStarter.new @request
        else
          raise NotImplementedError
      end
    end

    def start_request!
      starter.start_request!
    end
  end

  class RequestInRunStarter
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def start_request!
      if request.start!
        request.update_attributes automatically_start_errors: nil      # clean errors if request started automatically if any
      else
        errors = request.deployment_window_notices_message
        #request.notes.create user_id: request.user_id, content: errors # write notices to request notes
        request.update_attribute :automatically_start_errors, errors   # save errors in DB
      end
    end
  end

  class RequestPureStarter
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def start_request!
      request.start!
    end
  end
end



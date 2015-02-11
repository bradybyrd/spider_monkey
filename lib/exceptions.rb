module Exceptions
  class ResourceAutomationError < StandardError

    attr :exception_code

    def initialize(exception_code)
      @exception_code = exception_code
    end

  end
end
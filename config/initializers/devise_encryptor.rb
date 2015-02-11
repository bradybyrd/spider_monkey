require "digest/sha1"

module Devise
  module Encryptable
    module Encryptors
      class OldRestfulAuthentication < Base
        def self.digest(password, stretches, salt, pepper)
          Digest::SHA1.hexdigest("--#{salt}--#{password}--")
        end
      end
    end
  end
end


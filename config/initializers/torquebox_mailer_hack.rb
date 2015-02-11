#-*- encoding: utf-8 -*-
module TorqueBox
  module Mailer
    module Extensions

      class DelayedMailer
        include TorqueBox::Messaging::Backgroundable
        always_background :perform

        def self.perform(target, method_name, *args)
          msg = target.send(method_name, *args)
          begin
            msg.deliver if msg && (msg.to || msg.cc || msg.bcc) && msg.from
          rescue EOFError,
                 IOError,
                 TimeoutError,
                 Errno::ECONNRESET,
                 Errno::ECONNABORTED,
                 Errno::EPIPE,
                 Errno::ETIMEDOUT,
                 Net::SMTPAuthenticationError,
                 Net::SMTPFatalError,
                 Net::SMTPServerBusy,
                 Net::SMTPSyntaxError,
                 Net::SMTPUnknownError,
                 Net::SMTPUnsupportedCommand,
                 OpenSSL::SSL::SSLError => e
            target.send(:new_user_email_verification_failed, *args).deliver if method_name == :user_created
            target.send(:user_profile_updated_notification_failed, *args).deliver if (method_name == :password_changed || method_name == :password_reset) && args[0] != args[1]
          end
        end
      end

    end
  end
end

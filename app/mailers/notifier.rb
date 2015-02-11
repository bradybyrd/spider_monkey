class Notifier < ActionMailer::Base
  default from: (defined?(DEFAULT_SUPPORT_EMAIL_FROM_ADDRESS) ? DEFAULT_SUPPORT_EMAIL_FROM_ADDRESS : "no-reply@#{Notifier.default_url_options[:host]}")

  def self.supported_events
    %w[exception_raised request_message request_planned request_started request_in_problem request_resolved
      request_on_hold request_completed request_cancelled step_notify_mail step_started step_ready step_completed
      step_blocked step_problem user_created password_reset password_changed login user_admin_created
      event_with_requests_suspend series_with_requests_update request_failed_to_start_of_deployment_window
      new_user_email_verification_failed].sort
  end

  def self.supported_formats
    return [ "text/plain", "text/enriched", "text/html" ].sort
  end


  ################################  User Management #############################################

  # the application sends out these notifications on user events
  # such as lost logins, password changes, and new account
  # creation

  #
  # FOR user_created, password_changed, password_reset methods
  # admin parameter is used to get administrator email when delivering failed
  #
  def user_created(user, admin)
    @user = user
    get_template
    @params = get_params(@user)
    html_code = render_message_to_string('user_created', params: @params)
    mail(to: @user.email, subject: get_subject(@params, "Welcome to BMC Release Process Management - #{@user.name}")) do | format |
      format.html { html_code }
    end
  end

  def new_user_email_verification_failed(user, admin)
    @admin = admin
    @new_user = user
    get_template
    @params = get_params(@new_user)
    html_code = render_message_to_string('new_user_email_verification_failed', params: @params)
    mail(to: @admin.email, subject: get_subject(@params, 'New user email notification failed')) do | format |
      format.html { html_code }
    end
  end

  def user_profile_updated_notification_failed(user, admin)
    @admin = admin
    @new_user = user
    get_template
    @params = get_params(@new_user)
    html_code = render_message_to_string('user_profile_updated_notification_failed', params: @params)
    mail(to: @admin.email, subject: get_subject(@params, "User profile updated email notification failed'")) do | format |
      format.html { html_code }
    end
  end

  # `admin` argument is later used in torquebox_mailer_hack.rb if email notification failed
  def password_changed(user, admin)
    @user = user
    get_template
    @params = get_params(@user)
    html_code = render_message_to_string('password_changed', params: @params)
    mail(to: @user.email, subject: get_subject(@params, 'You have recently changed your password')) do | format |
      format.html { html_code }
    end
  end

  # `admin` argument is later used in torquebox_mailer_hack.rb if email notification failed
  def password_reset(user, admin)
    @user = user
    get_template
    @params = get_params(@user)
    html_code = render_message_to_string('password_reset', params: @params)
    mail(to: @user.email, subject: get_subject(@params, 'You have recently requested to reset your account password')) do | format |
      format.html { html_code }
    end
  end

  def user_admin_created(user, more_params = {})
    @user = user
    get_template
    @params = more_params.merge(get_params(@user))
    root_user = User.find_by_root(true) rescue nil
    html_code = render_message_to_string('user_admin_created', params: @params)
    mail(to: root_user.try(:email) || DEFAULT_SUPPORT_EMAIL_ADDRESS, subject: get_subject(@params, "New remote user account added - #{@user.login}")) do | format |
      format.html { html_code }
    end
  end

  ################################  Request/Step Management #############################################

  def step_status_mail(step, template, mail_subject, note = nil)
    get_template template
    @params = get_params(step)
    @note = note
    html_code = render_message_to_string(template, {params: @params, note: @note} )
    subject_txt = get_subject(@params, "Step #{step.number} on Request #{step.request.number} #{mail_subject}")
    mail(
        to: step.mailing_list,
        subject: subject_txt
    ) do | format |
      format.html { html_code }
    end
  end

  #used for simple REST call, message body passed as a param
  def step_notify_mail(step_id, notify)
    @step = Step.find(step_id)
    recipients = notify[:recipients] && notify[:recipients].split(',').map(&:strip) || @step.mailing_list
    @message_body = notify[:body]
    @message_subject = notify[:subject] || "Notification from Request ID: #{@step.request_id}, Step: #{@step.position}:#{@step.name}"
    mail(to: recipients, subject: @message_subject) do | format |
      format.html
    end
  end

  def request_send_mail(request, template, mail_subject, message = nil)
    get_template template

    message ||= request.messages.first.body if (request.aasm_state.in?(%w[started hold]) && request.messages.present?)
    @params   = get_params request, message
    html_code = render_message_to_string template, params: @params

    mail(to: request.mailing_list, subject: get_subject(@params, "Request #{request.number} #{mail_subject}")) do | format |
      format.html { html_code }
    end
  end


  # special case of a system error being sent to support
  # at streamstep.com for analysis and logging
  def exception_raised(exception)
    get_template
    @params = get_params(exception)
    html_code = render_message_to_string('exception_raised', params: @params)
    mail(to: DEFAULT_SUPPORT_EMAIL_ADDRESS, subject: get_subject(@params, "Exception raised at #{GlobalSettings[:company_name]}")) do | format |
      format.html { html_code }
    end
  end

  # special case of sending messages directly to the mailing list of a request
  # so standard template needs to have an arbitrary message added to it
  # this template is left for old messages
  # old method. not used?
  def request_message(request, msg)
    get_template
    @params = get_params(request)
    @message = msg.body
    html_code = render_message_to_string('request_message', {params: @params, message: @message})
    mail(to: request.mailing_list, subject: get_subject(@params, msg.subject)) do | format |
      format.html { html_code }
    end
  end

  def series_with_requests_update(request, dws)
    @request = request
    @user = request.user
    @dws = dws
    get_template
    mail(to: @user.email, subject: 'Deployment Window Series updating.') { |format| format.html }
  end

  def event_with_requests_suspend(request, event)
    @request = request
    @user = request.user
    @event = event
    @dws = event.series
    get_template
    mail(to: @user.email, subject: 'Deployment Window Event suspending.') { |format| format.html }
  end

  ###########################  Helper routines ##############################################

protected

  # routine for inspecting the
  def get_subject(params = {}, alternate_text = '')

    # set the subject to the default if nothing else better comes along
    subject = alternate_text

    # we have to guard against templates not being loaded
    if @notification_template && @notification_template.subject
      subj_template = Liquid::Template.parse(@notification_template.subject) rescue nil
      subject = subj_template.render({'params' => params})
    end
    subject
  end

  # pass some environmental variables into a class method
  def get_params(passed_object = nil,message = nil)
    passed_urls = Hash.new
    passed_urls[:login_url] = login_url(host: Notifier.default_url_options[:host])
    if passed_object.is_a?(Request)
      passed_urls[:edit_request_url] = edit_request_url(passed_object, host: Notifier.default_url_options[:host])
      passed_urls[:request_url] = request_url(passed_object, host: Notifier.default_url_options[:host])
    elsif passed_object.is_a?(Step) && passed_object.request.present?
      passed_urls[:edit_request_url] = edit_request_url(passed_object.request, host: Notifier.default_url_options[:host])
      passed_urls[:request_url] = request_url(passed_object.request, host: Notifier.default_url_options[:host])
    end
    Notifier.get_notification_parameters(passed_object, passed_urls,message)
  end

  def get_template(method=nil)
    # see if there is a custom template for this method
    # this regex gets the current method name
    caller[0]=~/`(.*?)'/
    method ||= $1
    @notification_template = NotificationTemplate.where('event LIKE ? AND active = ?', method, true).first
    # hack to avoid private attribute error on format call
    # (https://rails.lighthouseapp.com/projects/8994/tickets/2808-ar-attribute-collides-with-private-method-results-in-nomethoderror)
    throw_me_away = @notification_template.try(:subject)
  end

  def render_message_to_string(method_name, body)
    retval = ''
    begin
      # test that a notification template was found, otherwise application errors are raised, especially with new
      # subject gsubs; otherwise, just run the normal mailer routine
      if @notification_template && @notification_template.body
        template_body = @notification_template.body
        # use the template variable on the model to retrieve an already parsed template
        template = Liquid::Template.parse(template_body)
        retval = template.render body.stringify_keys!
      else
        retval = render template: "notifier/#{method_name}"
      end
    rescue Exception => e
      logger.warn "Could not render notification using custom notification template: #{e.message}, \n Backtrace:\n #{e.backtrace.join("\n")}"
      logger.warn 'Rendering using default template'
      retval = render template: "notifier/#{method_name}"
    end
    retval
  end

  def self.get_notification_parameters(passed_object = nil, passed_urls = {}, message = nil)
    # set common defaults
    params = Hash.new
    # basic company information for labels, headers, etc.
    params[:SS_company_name] = GlobalSettings[:company_name] ||= 'BRPM Application'
    params[:default_support_email_address] = DEFAULT_SUPPORT_EMAIL_ADDRESS
    params[:default_support_email] = DEFAULT_SUPPORT_EMAIL_FOOTER
    # adding a commonly needed login url for emails
    params[:SS_login_url] = passed_urls[:login_url]
    params[:SS_message] = message || ''
    case
    when passed_object.is_a?(Step)
      # by using automation_common, we include the full set of parameters that
      # users are familiar with from the automation and scripting module,
      # including request headers.
      params.merge!(AutomationCommon.build_params(params, passed_object))
      params.merge!(AutomationCommon.build_server_params(passed_object))
      # a liquid template is not a mailer_view so we build our urls here
      params[:SS_edit_request_url] = passed_urls[:edit_request_url]
      params[:SS_request_url] = passed_urls[:request_url]

    when passed_object.is_a?(Request)
      # request and the other objects do not have a params builder like step
      # so we call there headers convenience methods and manually merge them
      params.merge!(passed_object.headers_for_request)
      # a liquid template is not a mailer_view so we build our urls here
      params[:SS_edit_request_url] = passed_urls[:edit_request_url]
      params[:SS_request_url] = passed_urls[:request_url]
    when passed_object.is_a?(User)
      params.merge!(passed_object.headers_for_user)
    when passed_object.is_a?(Exception)
      params.merge!(SS_exception_message: passed_object.message)
      params.merge!(SS_exception_backtrace: passed_object.backtrace)
    end

    # without stringifying the keys, you get nothing because symbols are not supported by Liquid (memory leaks)
    return params.stringify_keys!

  end

end

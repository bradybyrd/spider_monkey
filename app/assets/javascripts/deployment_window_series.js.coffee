#= require moment
#= require jquery.placeholder
#= require filters_form

Datepicker =
  disabledFields: ->
    Datepicker.BindEvents.date_field_ids.filter((el) -> if $("#" + el).is(':disabled') then el)
  startDisabled: ->
    included = 'deployment_window_series_start_at' in Datepicker.disabledFields()
  BindEvents:
    # start and finish date&time
    date_field_ids: ["deployment_window_series_start_at", "deployment_window_series_finish_at", "deployment_window_series_start_at_4i",
                     "deployment_window_series_start_at_5i", "deployment_window_series_finish_at_4i", "deployment_window_series_finish_at_5i",
                     "deployment_window_series_duration_in_days"
    ]

    kinds: start:'start', finish:'finish'

    # jquery selector scoped to `body.deployment_window_series`
    selector_date_field_ids: ->
      $(Datepicker.BindEvents.date_field_ids).map((i, el) -> "body.deployment_window_series #" + el).join(",")

    calcDurationHandlerFor: (selector) ->
      this.initDatetimes selector
      datetimes = $ selector
      datetimes.on 'change', (e) =>
        element   = e.target
        datetime  = this.buildDatetime element
        duration  = this.calcDurationResult()
        result    = this.appendDurationResult duration
      duration  = this.calcDurationResult()
      result    = this.appendDurationResult duration

    initDatetimes: (selector) ->
      datetimes = $ selector
      datetimes.each (index, element) =>
        this.buildDatetime element


    buildDatetime: (element) ->
      kind          = Datepicker.Datetime.getKind element.id
      datetimePart  = Datepicker.Datetime.getDatetimePart element.id
      datetime      = Datepicker.Datetime.getInstance kind
      datetime.set datetimePart, element.value

    appendDurationResult: (duration = {})->
      valid             = duration.valid
      duration          = Datepicker.Datetime.durationHashHumanize duration
      durationResultDiv = $ 'body.deployment_window_series #duration_result'
      durationResultDiv.text duration
      if valid
        durationResultDiv.show()
      else
        durationResultDiv.hide()

    calcDuration: ->
      startDatetime   = Datepicker.Datetime.getInstance this.kinds.start
      finishDatetime  = Datepicker.Datetime.getInstance this.kinds.finish
      if this.canCalculateDate startDatetime, finishDatetime
        finishDatetime.toNumber() - startDatetime.toNumber()

    calcDurationResult: ->
      startDatetime   = Datepicker.Datetime.getInstance this.kinds.start
      finishDatetime  = Datepicker.Datetime.getInstance this.kinds.finish
      if this.canCalculateTime startDatetime, finishDatetime
        msDiff      = Datepicker.Datetime.timeDifference startDatetime, finishDatetime
        msDiff     += this.additionalDuration() * Datepicker.Datetime.MILISECONDS_IN_DAY
        duration    = Datepicker.Datetime.milisecondsToHash msDiff # {days, hours, minutes}

    canCalculateDate: (startDatetime, finishDatetime) ->
      startDatetime.isSufficient() and finishDatetime.isSufficient()

    canCalculateTime: (startDatetime, finishDatetime) ->
      startDatetime.isTimeSufficient() and finishDatetime.isTimeSufficient()

    additionalDuration: ->
      try
        parseInt($('body.deployment_window_series #deployment_window_series_duration_in_days option:selected').val());
      catch error
        console.log 'duration in days could not be parsed. Error:', error

  Datetime: class
    constructor: (kind) ->
      @date     = null
      @hours    = null
      @minutes  = null
      @seconds  = '00'

      @kind     = kind

    startInstance:  null
    finishInstance: null

    @MILISECONDS_IN_SECOND:  1000
    @MILISECONDS_IN_MINUTE:  60 * (1000) #this.MILISECONDS_IN_SECOND
    @MILISECONDS_IN_HOUR:    60 * (60 * 1000) #this.MILISECONDS_IN_MINUTE
    @MILISECONDS_IN_DAY:     24 * (60 * 60 * 1000) #this.MILISECONDS_IN_HOUR

    set: (datetimePart, value) ->
      @[datetimePart] = value if value
      return this

    isSufficient: ->
      @date? and @hours? and @minutes? and @seconds?

    isTimeSufficient: ->
      @hours? and @minutes? and @seconds?

    toString: ->
      "#{@date} #{@hours}:#{@minutes}:#{@seconds}"

    toDate: =>
      new Date(this.toString()) if this.isSufficient

    toNumber: (opts={format: 'datetime'}) ->
      self = Datepicker.Datetime
      if this.isSufficient() and opts.format == 'datetime'
        dates = @date.split('/')
        Date.UTC(dates[0], dates[1], dates[2], @hours, @minutes)
      else if this.isTimeSufficient() and opts.format == 'time'
        try
          sum  = parseInt(@hours) * self.MILISECONDS_IN_HOUR
          sum += parseInt(@minutes) * self.MILISECONDS_IN_MINUTE
          sum += parseInt(@seconds) * self.MILISECONDS_IN_SECOND
        catch error
          0

    @durationHashHumanize: (duration = {}) ->
      "#{duration.days}d #{duration.hours}h #{duration.minutes}m"

    @milisecondsToHash: (ms) =>
      days    = Math.floor( ms / this.MILISECONDS_IN_DAY)
      hours   = Math.floor((ms % this.MILISECONDS_IN_DAY ) / this.MILISECONDS_IN_HOUR)
      minutes = Math.floor((ms % this.MILISECONDS_IN_HOUR) / this.MILISECONDS_IN_MINUTE)
      seconds = Math.floor((ms % this.MILISECONDS_IN_MINUTE) / this.MILISECONDS_IN_SECOND)
      return days: days, hours: hours, minutes: minutes, seconds: seconds, valid: ms >= 0

    @difference: (datetime1, datetime2) ->
      msDatetime1   = datetime1.toDate()
      msDatetime2   = datetime2.toDate()
      diff          = msDatetime2 - msDatetime1

    @timeDifference: (time1, time2) ->
      msTime1   = time1.toNumber format:'time'
      msTime2   = time2.toNumber format:'time'
      diff      = msTime2 - msTime1

    @getDatetimePart: (str) ->
      date    = "date"    if str.match /date/
      hours   = "hours"   if str.match /4i/
      minutes = "minutes" if str.match /5i/
      return "#{date or hours or minutes}"

    # returns `start` or `finish`
    @getKind: (str) ->
      start  = str.match /start/
      finish = str.match /finish/
      return "#{start or finish}"

    @getInstance: (kind) =>
      instance = if kind == "start" then this.startInstance else this.finishInstance

      if instance?
        return instance
      else if kind == "start"
        this.startInstance   = new this(kind)
      else if kind == "finish"
        this.finishInstance  = new this(kind)

  Validation:
    turnOn: (selector, errorsViewer) ->
      $datepickers = $ selector
      $datepickers.on 'change', (e) =>
        for callback in @callbacks
          callback.call(new @Context(e.target, callback.msg)).execute(errorsViewer)
      this

    addCallback: (callback) ->
      @callbacks ||= new @CallbacksCollection
      @callbacks.push new @Callback(callback)

    Callback: class
      constructor: (funktion) ->
        @funktion = funktion

      call: (context) ->
        @funktion.call context

      withMessage: (msg) ->
        @msg = msg

    CallbacksCollection: class extends Array
      last: ->
        @[@.length - 1]

    Context: class
      datetimePicker = (tag) ->
        h = @form.elements["deployment_window_series[#{tag}(4i)]"].value
        m = @form.elements["deployment_window_series[#{tag}(5i)]"].value
        date = @form.elements["deployment_window_series[#{tag}]"].value
        datetime = "#{date} #{h}:#{m}"
        (@values ||= []).push moment(datetime)
        this

      constructor: (element, msg) ->
        @form = element.form or element
        @msg = msg

      start: ->
        datetimePicker.call this, 'start_at'

      finish: ->
        datetimePicker.call this, 'finish_at'

      now: ->
        new Date
        this

      isBefore: ->
        (@actions ||= []).push 'isBefore'
        this

      isAfter: ->
        (@actions ||= []).push 'isAfter'
        this

      execute: (errorsViewer) ->
        minLength = if (@values.length - 1) < @actions.length then @values.length else @actions.length
        result = @values[0]
        result = result[@actions[i - 1]](@values[i]) for i in [1..minLength]
        if result then errorsViewer.remove(@msg) else errorsViewer.add(@msg)
        this

  validates: (callback) ->
    @Validation.addCallback callback
    @Validation.callbacks.last()

  validateDate: ->
    date_input_ids = ["deployment_window_series_start_at", "deployment_window_series_finish_at"]
    date_input_ids.forEach((selector)->
      $('#' + selector).on('change', (e) -> Datepicker.validateDateFormat(e.target))
    )

  validateDateFormat: (input)->
    id = input.getAttribute('id')
    label = $('#' + id).siblings('label').text().toLowerCase()
    date = input.value
    message = 'Invalid ' + label + ' date format. Please correct and enter valid date again.'

    if !moment(date, 'MM/DD/YYYY').isValid()
      ErrorsViewer.add(message)
    else
      ErrorsViewer.remove(message)


ErrorsViewer =
  add: (msg) ->
    @messages ||= {}
    @messages[msg] = true
    @updateView()

  remove: (msg) ->
    @messages ||= {}
    delete @messages[msg]
    @updateView()

  updateView: ->
    keys = Object.keys(@messages)
    if keys.length > 0
      $('.dws_form_submit').disable()
      @showErrors(keys)
    else
      $('.dws_form_submit').enable()
      @hideErrors()

  showErrors: (msgs) ->
    message = (msg for msg in msgs)
    $('#error_explanation_js').html('<ul></ul>')
    errorList = $('#error_explanation_js ul')
    $.each message, (i) ->
      $('<li/>').text(message[i]).appendTo(errorList)
      return
    $('#error_explanation_js').show()

  hideErrors: ->
    $('#error_explanation_js').hide()

Manipulation =
  bindEvents: ->
    $(@formSelectors).on 'ajax:success', @updateTables

  formSelectors:
    'form.searchform, form.filters'

  updateTables: (event, responseText) ->
    html = $(responseText)
    if $(html[0]).is('.list')
      $('#archived_deployment_window_series_list').remove()
      $('#deployment_window_series_list').replaceWith(html)
    else
      $('#deployment_window_series_list').html(html)

  enable_dates: ->
    button = '.field input.dws_form_submit'
    check = '#deployment_window_series_recurrent'
    fields = ['#deployment_window_series_start_at_4i', '#deployment_window_series_start_at_5i']

    if ( $('input#deployment_window_series_start_at[type="text"]').prop('disabled') )
      $(button).on('click', (e)->
        fields.forEach((el) ->
          $(el).prop('disabled', false)
        )
      )

      $(check).on('change', ->
        fields.forEach((el) ->
          $(el).prop('disabled', !$(el).prop('disabled'))
        )
      )

CheckboxRecurringChecker =
  BindEvents:
    onChangeFor: (selector) ->
      checkboxButtons = $ selector
      CheckboxRecurringChecker.Render.prepareAppearance checkboxButton for checkboxButton in checkboxButtons

      checkboxButtons.on 'change', (e) ->
        element = e.target
        CheckboxRecurringChecker.Render.prepareAppearance element

  Render:
    recurrentFieldIds: ['#deployment_window_series_duration', '#deployment_window_series_schedule', '#deployment_window_series_recurrent_time']

    prepareAppearance: (element) ->
      if this.recurring_checked_in element
        this.renderForRecurrent()
      else if !this.recurring_checked_in element
        this.renderForNonrecurrent()

    recurring_checked_in: (element) ->
      $(element).attr 'checked'

    renderForRecurrent: ->
      times             = $('.stitched_date .time')
      toRecurrenceZone  = $('#deployment_window_series_recurrent_time')

      this.moveToRecurrentArea(times, toRecurrenceZone)
      this.changeTextLabels('recurrent')
      this.get(this.recurrentFieldIds.join(', ')).parent().show()

    renderForNonrecurrent: ->
      times             = $('#deployment_window_series_recurrent_time .time')
      toDateZone        = $('.stitched_date')

      this.moveToNonRecurrentArea(times, toDateZone)
      this.changeTextLabels('nonrecurrent')
      this.get(this.recurrentFieldIds.join(', ')).parent().hide()

    moveToRecurrentArea: (targets, placeholder) ->
      $.each targets, (index, target) ->
        $(placeholder).append(target)

    moveToNonRecurrentArea: (targets, placeholders) ->
      $.each placeholders, (index, placeholder) ->
        $(placeholder).append(targets[index])

    get: (selector) ->
      $(".deployment_window_series #{selector}")

    dateDiv: (point) ->
      this.get("#deployment_window_series_#{point}").parents('.stitched_date')

    startDateDiv: ->
      this.dateDiv 'start'

    finishDateDiv: ->
      this.dateDiv 'finish'

    recurrenceDiv: ->
      this.get '.recurrence'

    timeDiv: (point) ->
      target    = "[id*=#{point}]"
      selectors = ['.stitched_date', '.recurrence']
      selectors = $(selectors).each (i, selector) ->
        [selector, target].join ' '

      selector  = selectors.join ', '
      this.get(selector).parents('.time')

    startTimeDiv: ->
      this.timeDiv 'start'

    finishTimeDiv: ->
      this.timeDiv 'finish'

    changeTextLabels: (type) ->
      labels = $('.prefix')
      if type == 'recurrent'
        label_text = ['From:', 'To:']
      else if type == 'nonrecurrent'
        label_text = ['at:', 'at:']
      $.each labels, (index, label) ->
          $(label).text(label_text[index])

#### #### #### #### ####

SeriesForm =
  observeFrequencyChanges: ->
    if @editForm().length
      @saveFrequencyData()

    @editForm().on 'submit', (e) ->
      message = "Deployment Window occurrences will be recreated. Are you sure you want to update?"
      if SeriesForm.frequencyModified() && !confirm(message)
        e.preventDefault()

  editForm: -> $('#edit_deployment_window_series')

  saveFrequencyData: ->
    @_data = @frequencyData()

  frequencyData: ->
    @frequencyFields().serialize()

  frequencyFields: ->
    @editForm().find(':input:visible').not('#deployment_window_series_name')

  frequencyModified: ->
    @_data != @frequencyData()

$ ->
  RPM.Helpers.InitSearch('#series-lists')
  Manipulation.bindEvents()
  $filters_form = $('body.deployment_window_series form.filters')
  new FiltersForm $filters_form if $filters_form.length > 0

  CheckboxRecurringChecker.BindEvents.onChangeFor('#deployment_window_series_recurrent')
  Datepicker.BindEvents.calcDurationHandlerFor Datepicker.BindEvents.selector_date_field_ids()

  $('#deployment_window_series_list').tooltip()

  $('body.deployment_window_series')
    .on 'click', '.environments a.more-links', ->
      $(@parentNode.parentNode.children).toggleClass('hidden')

  Occurrences.ContextMenu.init 'body.deployment_window_series #deployment_window_series_list',
                               'td:nth-child(6) a:not(.more-links)'
  RPM.Helpers.AjaxPagination('body.deployment_window_series, body.deployment_window_occurrences')
  $('#rs_frequency').livequery -> $(this).find('option[value="Yearly"]').remove()
  $(".rs_save").livequery 'click', ->
    $('#deployment_window_series_frequency').attr("title", $('#deployment_window_series_frequency').find('option:selected').html())
  $.fn.recurring_select.texts = {
    repeat: "Frequency"
    last_day: "Last Day"
    frequency: "Type"
    daily: "Daily"
    weekly: "Weekly"
    monthly: "Monthly"
    yearly: "Yearly"
    every: "Every"
    days: "day(s)"
    weeks_on: "week(s) on"
    months: "month(s)"
    years: "year(s)"
    first_day_of_week: 0
    day_of_month: "Day of month"
    day_of_week: "Day of week"
    cancel: "Cancel"
    ok: "Set"
    summary: "Summary"
    days_first_letter: ["S", "M", "T", "W", "T", "F", "S" ]
    order: ["1st", "2nd", "3rd", "4th"]
  }
  Manipulation.enable_dates()
  SeriesForm.observeFrequencyChanges()

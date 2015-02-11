##= require moment
##= require filters
#
#Datepicker =
#  BindEvents:
#    # start and finish date&time
#    date_field_ids: ["deployment_window_start_date", "deployment_window_finish_date", "deployment_window_start_4i",
#                     "deployment_window_start_5i", "deployment_window_finish_4i", "deployment_window_finish_5i",
#                     "deployment_window_duration"
#    ]
#
#    kinds: start:'start', finish:'finish'
#
#    # jquery selector scoped to `body.deployment_windows`
#    selector_date_field_ids: ->
#      Datepicker.BindEvents.date_field_ids.map((el)-> "body.deployment_windows #" + el).join(",")
#
#    calcDurationHandlerFor: (selector) ->
#      this.initDatetimes selector
#      datetimes = $ selector
#      datetimes.on 'change', (e) =>
#        element   = e.target
#        datetime  = this.buildDatetime element
#        duration  = this.calcDurationResult()
#        result    = this.appendDurationResult duration
#
#    initDatetimes: (selector) ->
#      datetimes = $ selector
#      datetimes.each (index, element) =>
#        this.buildDatetime element
#
#
#    buildDatetime: (element) ->
#      kind          = Datepicker.Datetime.getKind element.id
#      datetimePart  = Datepicker.Datetime.getDatetimePart element.id
#      datetime      = Datepicker.Datetime.getInstance kind
#      datetime.set datetimePart, element.value
#
#    appendDurationResult: (duration = {})->
#      valid             = duration.valid
#      duration          = Datepicker.Datetime.durationHashHumanize duration
#      durationResultDiv = $ 'body.deployment_windows #duration_result'
#      durationResultDiv.text duration
#      if valid
#        durationResultDiv.show()
#      else
#        durationResultDiv.hide()
#
#    calcDuration: ->
#      startDatetime   = Datepicker.Datetime.getInstance this.kinds.start
#      finishDatetime  = Datepicker.Datetime.getInstance this.kinds.finish
#      if this.canCalculateDate startDatetime, finishDatetime
#        finishDatetime.toNumber() - startDatetime.toNumber()
#
#    calcDurationResult: ->
#      startDatetime   = Datepicker.Datetime.getInstance this.kinds.start
#      finishDatetime  = Datepicker.Datetime.getInstance this.kinds.finish
#      if this.canCalculateTime startDatetime, finishDatetime
#        msDiff      = Datepicker.Datetime.timeDifference startDatetime, finishDatetime
#        msDiff     += this.additionalDuration() * Datepicker.Datetime.MILISECONDS_IN_DAY
#        duration    = Datepicker.Datetime.milisecondsToHash msDiff # {days, hours, minutes}
#
#    canCalculateDate: (startDatetime, finishDatetime) ->
#      startDatetime.isSufficient() and finishDatetime.isSufficient()
#
#    canCalculateTime: (startDatetime, finishDatetime) ->
#      startDatetime.isTimeSufficient() and finishDatetime.isTimeSufficient()
#
#    additionalDuration: ->
#      parseInt $('body.deployment_windows #deployment_window_duration option:selected').val()
#
#  Datetime: class
#    constructor: (kind) ->
#      @date     = null
#      @hours    = null
#      @minutes  = null
#      @seconds  = '00'
#
#      @kind     = kind
#
#    startInstance:  null
#    finishInstance: null
#
#    @MILISECONDS_IN_SECOND:  1000
#    @MILISECONDS_IN_MINUTE:  60 * (1000) #this.MILISECONDS_IN_SECOND
#    @MILISECONDS_IN_HOUR:    60 * (60 * 1000) #this.MILISECONDS_IN_MINUTE
#    @MILISECONDS_IN_DAY:     24 * (60 * 60 * 1000) #this.MILISECONDS_IN_HOUR
#
#    set: (datetimePart, value) ->
#      @[datetimePart] = value if value
#      return this
#
#    isSufficient: ->
#      @date? and @hours? and @minutes? and @seconds?
#
#    isTimeSufficient: ->
#      @hours? and @minutes? and @seconds?
#
#    toString: ->
#      "#{@date} #{@hours}:#{@minutes}:#{@seconds}"
#
#    toDate: =>
#      new Date(this.toString()) if this.isSufficient
#
#    toNumber: (opts={format: 'datetime'}) ->
#      self = Datepicker.Datetime
#      if this.isSufficient() and opts.format == 'datetime'
#        dates = @date.split('/')
#        Date.UTC(dates[0], dates[1], dates[2], @hours, @minutes)
#      else if this.isTimeSufficient() and opts.format == 'time'
#        try
#          sum  = parseInt(@hours) * self.MILISECONDS_IN_HOUR
#          sum += parseInt(@minutes) * self.MILISECONDS_IN_MINUTE
#          sum += parseInt(@seconds) * self.MILISECONDS_IN_SECOND
#        catch error
#          0
#
#    @durationHashHumanize: (duration = {}) ->
#      "#{duration.days}d #{duration.hours}h #{duration.minutes}m"
#
#    @milisecondsToHash: (ms) =>
#      days    = Math.floor( ms / this.MILISECONDS_IN_DAY)
#      hours   = Math.floor((ms % this.MILISECONDS_IN_DAY ) / this.MILISECONDS_IN_HOUR)
#      minutes = Math.floor((ms % this.MILISECONDS_IN_HOUR) / this.MILISECONDS_IN_MINUTE)
#      seconds = Math.floor((ms % this.MILISECONDS_IN_MINUTE) / this.MILISECONDS_IN_SECOND)
#      return days: days, hours: hours, minutes: minutes, seconds: seconds, valid: ms >= 0
#
#    @difference: (datetime1, datetime2) ->
#      msDatetime1   = datetime1.toDate()
#      msDatetime2   = datetime2.toDate()
#      diff          = msDatetime2 - msDatetime1
#
#    @timeDifference: (time1, time2) ->
#      msTime1   = time1.toNumber format:'time'
#      msTime2   = time2.toNumber format:'time'
#      diff      = msTime2 - msTime1
#
#    @getDatetimePart: (str) ->
#      date    = "date"    if str.match /date/
#      hours   = "hours"   if str.match /4i/
#      minutes = "minutes" if str.match /5i/
#      return "#{date or hours or minutes}"
#
#    # returns `start` or `finish`
#    @getKind: (str) ->
#      start  = str.match /start/
#      finish = str.match /finish/
#      return "#{start or finish}"
#
#    @getInstance: (kind) =>
#      instance = if kind == "start" then this.startInstance else this.finishInstance
#
#      if instance?
#        return instance
#      else if kind == "start"
#        this.startInstance   = new this(kind)
#      else if kind == "finish"
#        this.finishInstance  = new this(kind)
#
#  Validation:
#    turnOn: (selector, errorsViewer) ->
#      $datepickers = $ selector
#      $datepickers.on 'change', (e) =>
#        for callback in @callbacks
#          callback.call(new @Context(e.target, callback.msg)).execute(errorsViewer)
#      this
#
#    addCallback: (callback) ->
#      @callbacks ||= new @CallbacksCollection
#      @callbacks.push new @Callback(callback)
#
#    Callback: class
#      constructor: (funktion) ->
#        @funktion = funktion
#
#      call: (context) ->
#        @funktion.call context
#
#      withMessage: (msg) ->
#        @msg = msg
#
#    CallbacksCollection: class extends Array
#      last: ->
#        @[@.length - 1]
#
#    Context: class
#      datetimePicker = (tag) ->
#        h = @form.elements["deployment_window_series[#{tag}(4i)]"].value
#        m = @form.elements["deployment_window_series[#{tag}(5i)]"].value
#        date = @form.elements["deployment_window_series[#{tag}_date]"].value
#        datetime = "#{date} #{h}:#{m}"
#        (@values ||= []).push moment(datetime)
#        this
#
#      constructor: (element, msg) ->
#        @form = element.form or element
#        @msg = msg
#
#      start: ->
#        datetimePicker.call this, 'start'
#
#      finish: ->
#        datetimePicker.call this, 'finish'
#
#      now: ->
#        new Date
#        this
#
#      isBefore: ->
#        (@actions ||= []).push 'isBefore'
#        this
#
#      isAfter: ->
#        (@actions ||= []).push 'isAfter'
#        this
#
#      execute: (errorsViewer) ->
#        minLength = if (@values.length - 1) < @actions.length then @values.length else @actions.length
#        result = @values[0]
#        result = result[@actions[i - 1]](@values[i]) for i in [1..minLength]
#        if result then errorsViewer.remove(@msg) else errorsViewer.add(@msg)
#        this
#
#  validates: (callback) ->
#    @Validation.addCallback callback
#    @Validation.callbacks.last()
#
#ErrorsViewer =
#  add: (msg) ->
#    (@messages ||= {})[msg] = true
#    @updateView()
#
#  remove: (msg) ->
#    delete @messages[msg]
#    @updateView()
#
#  updateView: ->
#    keys = Object.keys(@messages)
#    if keys.length > 0
#      @showErrors(keys)
#    else
#      @hideErrors()
#
#  showErrors: (msgs) ->
#    message = (msg for msg in msgs)
#    $('.early_due_date_error').show().html(message.join(' '))
#
#  hideErrors: ->
#    $('.early_due_date_error').hide()
#
##### #### #### #### ####
#
#class FiltersForm
#  constructor: (@form) ->
#    @enableToggling()
#    @form.find('.clear_request_filters').on 'click', @clear
#    @filters = []
#    $('.selected_values').each (i, element) =>
#      @filters.push new Filter $(element.parentNode), @form
#
#  enableToggling: ->
#    @form.parents('#filterSection').prev().find('a').on 'click', (event) ->
#      $('#filterSection').toggle =>
#        newText = $(@).data 'placeholder'
#        $(@).data 'placeholder', @innerHTML
#        @innerHTML = newText
#      false
#
#  clear: =>
#    for filter in @filters
#      filter.clear()
#      filter.showSelected()
#      filter.renameAdd()
#    @form.submit()
#    false
#
#
#class Filter
#  constructor: (@tdContainer, @form) ->
#    @addLink = @tdContainer.find '.selected a'
#    @doneLink = @tdContainer.find '.values_to_select a:nth-of-type(1)'
#    @cancelLink = @tdContainer.find '.values_to_select a:nth-of-type(2)'
#    @clearLink = @tdContainer.find '.values_to_select a:nth-of-type(3)'
#    @select = @tdContainer.find '.values_to_select select'
#    @valuesToSelect = @tdContainer.find '.values_to_select'
#    @selectedValues = @tdContainer.find '.selected'
#
#    @addLink.on 'click', @show
#    @doneLink.on 'click', @done
#    @cancelLink.on 'click', @cancel
#    @clearLink.on 'click', @clear
#    @select.on 'change', @changed
#
#  show: =>
#    @showSelect()
#    if @selected?()
#      @showDone()
#      @showClear()
#    else
#      @hideClear()
#    @showCancel()
#    @hideAdd()
#    false
#
#  done: =>
#    @form.submit()
#    @showSelected @select.find('option:selected')
#    @cancel()
#    @renameAdd()
#    false
#
#  cancel: =>
#    @hideSelect()
#    @hideDone()
#    @hideCancel()
#    @showAdd()
#    @hideClear()
#    false
#
#  clear: =>
#    @select.val []
#    @hideClear()
#    false
#
#  selected: ->
#    @select.val?() and @select.val().length > 0
#
#  showSelect: ->
#    @valuesToSelect.show()
#    @select.show()
#
#  showDone: ->
#    @doneLink.show()
#
#  showCancel: ->
#    @cancelLink.show()
#
#  hideAdd: ->
#    @addLink.hide()
#
#  showClear: ->
#    @clearLink.show()
#
#  hideClear: ->
#    @clearLink.hide()
#
#  hideSelect: ->
#    @select.hide()
#    @select.val @select.data('values')
#
#  hideDone: ->
#    @doneLink.hide()
#
#  hideCancel: ->
#    @cancelLink.hide()
#
#  showAdd: ->
#    @addLink.show()
#
#  renameAdd: ->
#    if @selected?()
#      @addLink.html 'edit'
#    else
#      @addLink.html 'add'
#
#  showSelected: (selected = []) ->
#    values = (option.value for option in selected)
#    selectedStrings = (option.innerHTML for option in selected)
#    @select.data('values', values)
#    @selectedValues.find('span').remove()
#    @selectedValues.prepend $("<span class='multivalues'>#{selectedStrings.join(', ')}</span>")
#
#  changed: =>
#    if @selected?()
#      @showDone()
#      @showClear()
#    false
#
#Manipulation =
#  bindEvents: ->
#    $(@formSelectors).on 'ajax:success', @updateTable
#
#  formSelectors:
#    'form.searchform, form.filters'
#
#  updateTable: (event, responseText, status, jqXhr) ->
#    $('#deployment_windows_list').html(responseText)
#
#Pagination =
#  ajaxify: ->
#    $('body.deployment_window_series').on 'click', '.server_side_tablesorter_pagination a', ->
#      $.ajax
#        type: "GET"
#        url: $(this).attr("href")
#      .done (responseText, status, jqXhr) ->
#        Manipulation.updateTable(null, responseText)
#      false
#
#SearchForm =
#  init: ->
#    @setPlaceholder()
#    @bindClearEvent()
#
#  $form: ->
#    $ @formSelector
#
#  formSelector:
#    'form.searchform'
#
#  inputSelector:
#    'input.searchbox'
#
#  clearLinkSelector:
#    'a'
#
#  setPlaceholder: ->
#    @$form().find(@inputSelector).placeholder()
#
#  bindClearEvent: ->
#    @$form().find(@clearLinkSelector).on 'click', @clear
#
#  clear: ->
#    SearchForm.$form().find(SearchForm.inputSelector).val ''
#    SearchForm.$form().submit()
#    false
#
#
#RadioButtonChecker =
#  BindEvents:
#    onChangeFor: (selector) ->
#      radioButtons = $ selector
#      RadioButtonChecker.Render.prepareAppearance radioButton for radioButton in radioButtons
#
#      radioButtons.on 'change', (e) ->
#        element = e.target
#        RadioButtonChecker.Render.prepareAppearance element
#
#  Render:
#    recurrentFieldIds: ['#deployment_window_duration', '#deployment_window_recurring_rules']
#
#    prepareAppearance: (element) ->
#      if element.value == 'recurrent' and $(element).attr 'checked'
#        this.renderForRecurrent()
#      else if element.value == 'nonrecurrent' and $(element).attr 'checked'
#        this.renderForNonrecurrent()
#
#    renderForRecurrent: ->
#      times             = [this.startTimeDiv(), this.finishTimeDiv()]
#      toRecurrenceZone  = this.recurrenceDiv().find('#time_holder')
#
#      this.changeTextLabels('recurrent')
#      this.changePosition times, toRecurrenceZone
#      this.get(this.recurrentFieldIds.join(', ')).parent().show()
#
#    renderForNonrecurrent: ->
#      times             = [this.startTimeDiv(), this.finishTimeDiv()]
#      toDateZone        = [this.startDateDiv(), this.finishDateDiv()]
#
#      this.changeTextLabels('nonrecurrent')
#      this.changePosition times, toDateZone, parallel:true
#      this.get(this.recurrentFieldIds.join(', ')).parent().hide()
#
#    changePosition: (targets, whereTos, opts = {prepend: false, parallel: false}) ->
#      $.each targets, (index, target) ->
#        whereTo = if opts.parallel then whereTos[index] else whereTos
#        # if not appended yet
#        if $(whereTo).find(target)[0] != targets[index][0]
#          if opts.prepend
#            target.prependTo whereTo
#          else
#            target.appendTo whereTo
#
#  # scoped to .deployment_windows
#    get: (selector) ->
#      $(".deployment_windows #{selector}")
#
#    dateDiv: (point) ->
#      this.get("#deployment_window_#{point}_date").parents('.stitched_date')
#
#    startDateDiv: ->
#      this.dateDiv 'start'
#
#    finishDateDiv: ->
#      this.dateDiv 'finish'
#
#    recurrenceDiv: ->
#      this.get '.recurrence'
#
#    timeDiv: (point) ->
#      target    = "[id*=#{point}]"
#      selectors = ['.stitched_date', '.recurrence']
#      selectors = selectors.map (selector, i) ->
#        [selector, target].join ' '
#
#      selector  = selectors.join ', '
#      this.get(selector).parents('.time')
#
#    startTimeDiv: ->
#      this.timeDiv 'start'
#
#    finishTimeDiv: ->
#      this.timeDiv 'finish'
#
#    changeTextLabels: (type) ->
#      if type == 'recurrent'
#        this.startTimeDiv().find('span.prefix').text('From:')
#        this.finishTimeDiv().find('span.prefix').text('To:')
#      else if type == 'nonrecurrent'
#        this.startTimeDiv().find('span.prefix').text('at')
#        this.finishTimeDiv().find('span.prefix').text('at')
#
##### #### #### #### ####
#
#
#$ ->
#  Datepicker.Validation
#    .turnOn('body.deployment_window_series .date, body.deployment_window_series .date + nobr select',
#            ErrorsViewer)
#  Datepicker.validates( -> @start().isBefore().finish())
#    .withMessage('Start date is after Finish date.')
#  Datepicker.validates( -> @start().isAfter().now())
#    .withMessage('Start date is before current date.')
#
##  SearchForm.init()
#  Manipulation.bindEvents()
#  Pagination.ajaxify()
#  new FiltersForm $('body.deployment_window_series form.filters')
#
#  RadioButtonChecker.BindEvents.onChangeFor('[name = "deployment_window_series[type]"]')
#  Datepicker.BindEvents.calcDurationHandlerFor Datepicker.BindEvents.selector_date_field_ids()

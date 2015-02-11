function StompClientMock() {
  this.channels = {};

  this.connect = function (callback) {
    setTimeout(callback, 1);
  },

  this.disconnect = function () {
  },

  this.subscribe = function (channel, callback) {
    if (!this.channels[channel]) {
      this.channels[channel] = [];
    }
    this.channels[channel].push(callback);
  },

  this.trigger = function (channel, message) {
    if (!this.channels[channel]) {
      return;
    }
    this.channels[channel].forEach(function (callback) {
      callback.call(this, message);
    });
  }
}

function ServerMessages(options) {
  this.connected = false;
  this.client = options.client || new Stomp.Client(options.url);

  this.eventsListener = options.eventsListener || {};
  this.subscriptions = options.subscriptions || [];
  this.headers = $.extend(this._getAuthTokenHash(), options.headers || {});

  this.pausedMessages = [];
  if (options.pause) {
    this.pause();
  }
  this._fixStompLogger();

  $(window).on('beforeunload', $.proxy(this.onUnload, this));
}

ServerMessages.prototype = {
  on : function (event, callback) {
    $(this.eventsListener).on(event, callback);
  },

  _fixStompLogger : function () {
    /**
     *  Fixing stomp.js logger method in IE. Logger uses logger.debug() method during connection
     *  but IE does not have such method. Linking it to logger.log()
     **/
    if (window.console && !window.console.debug && window.console.log) {
      window.console.debug = window.console.log;
    }
  },

  _getAuthTokenHash : function () {
    data = {};
    var tokenFieldName = $('meta[name=csrf-param]').attr('content');
    var tokenValue = $('meta[name=csrf-token]').attr('content');
    data[tokenFieldName] = tokenValue;
    return data;
  },

  connect : function () {
    this.client.connect($.proxy(this.onConnect, this));
  },

  onConnect : function () {
    this.connected = true;
    this._bindSubscriptions();
    $(this.eventsListener).trigger('connected', [this]);
  },

  onUnload : function () {
      if (this.connected) {
          this.client.disconnect();
          this.connected = false;
      }
  },

  _bindSubscriptions : function () {
    var _this = this;
    $.each(this.subscriptions, function (i, subscription) {
      _this._subscribe(subscription);
    });
  },

  _subscribe : function (subscription) {
    this.client.subscribe(subscription.channel, $.proxy(function (message) {
      if (!this.connected) {
        return false;
      }
      if (this._paused) {
        this._addMessageToQueue(subscription, message);
        return;
      }
      this._handleMessage(subscription, message);
    }, this), this.headers);

    if (subscription.on_subscribe) {
      subscription.on_subscribe.call(this, subscription, this);
    }
  },

  _handleMessage : function (subscription, message) {
    // if channel sends updated html for some element on page, not sure it's very useful
    if (subscription.update_html && this.isHtml(message)) {
      this._updateHtml(message, subscription);
    }

    // you may trigger custom event with message as argument, userful to interact with page components
    if (subscription.event && this.eventsListener) {
      $(this.eventsListener).trigger(subscription.event, [message]);
    }

    if (subscription.callback) {
      subscription.callback.call(this, message, subscription);
    }
  },

  isHtml : function (message) {
    return this._getContentType(message) == 'text/html';
  },

  getContentType : function (message) {
    return message.headers['Content-Type'];
  },

  getDomId : function (message) {
    return message.headers['X-Dom-Id'];
  },

  _updateHtml : function (message, subscription) {
    $('#' + this.getDomId(message)).html(message.body);
  },

  send : function (channel, message, headers) {
    if (this.connected) {
      this.client.send(channel, headers, message);
      return true;
    }
    return false;
  },

  _addMessageToQueue : function (subscription, message) {
    this.pausedMessages.push({subscription: subscription, message: message});
  },

  pause : function () {
    this._paused = true;
  },

  resume : function () {
    var _this = this;
    this._paused = false;
    $.each(this.pausedMessages, function (i, item) {
      _this._handleMessage(item.subscription, item.message);
    });
    this.pausedMessages = [];
  }
};
////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

Array.prototype.first = function() {
  return jQuery(this)[0];
}

Array.prototype.last = function() {
  return jQuery(this)[jQuery(this).length - 1];
}

String.prototype.insertAt = function(idx, str) {
  return this.slice(0, idx) + str + this.slice(idx);
}

jQuery.fn.join = function(thing) {
  return jQuery.makeArray(this).join(thing);
}

jQuery.fn.bindFirst = function(eventType, callback) {
  this.each(function() {
    var elem = jQuery(this);
    var currentCallbacks = elem.data('events') && elem.data('events')[eventType];
    var newCallbacks = [callback];
    if (currentCallbacks) {
      for (id in currentCallbacks) {
        newCallbacks.push(currentCallbacks[id]);
        elem.unbind(eventType, currentCallbacks[id]);
      }
    }
    jQuery(newCallbacks).each(function(i, fun) {
      elem.bind(eventType, fun);
    });
  });

  return this;
}


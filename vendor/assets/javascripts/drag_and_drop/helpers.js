// This file is the property of StreamStep, Inc.
// The contents of this file are covered by Copyright by StreamStep, Inc.
// Any unauthorized and unlicensed use is strictly prohibited.
// The software source code can be used only with a valid software license from StreamStep, Inc.
// In NO WAY is this software open source, free, or in the public domain.

// Drag and drop helpers

function removeDropGroupIfEmpty(moved_object, object_type) {
  if (moved_object.prevAll('.' + object_type).length == 0 && moved_object.nextAll('.' + object_type).length == 0)
    moved_object.parent().next().andSelf().remove(); // Remove the container and the divider below it
}

function draggableObjectsOfSameComponentClass(comparand, object_type) {
  return $('.' + object_type).filter(
           function() { 
             if ($(this).attr('id') == comparand.attr('id')) return false;

             return $(this).attr('data-color-id') == comparand.attr('data-color-id');
           }
         );
}

function usedComponentColorClassNumbers(container_selector) {
  var class_numbers = [];

  $(container_selector).each(
    function() { 
      var match_data = $(this).attr('class').match(/component_color_(\d+)/);

      if (match_data)
        class_numbers.push(match_data[1]);
    }
  );

  return class_numbers;
}

function rgbToHex(rgb_string) {
  var match_data = rgb_string.match(/rgb\((\d+),\s(\d+),\s(\d+)\)/);

  if (match_data) {
    var r = parseInt(match_data[1]);
    var g = parseInt(match_data[2]);
    var b = parseInt(match_data[3]);

    return '#' + toHex(r) + toHex(g) + toHex(b);
  } else {
    return rgb_string;
  }
}

// Only works on numbers 0-255
function toHex(num) {
  var hex_digits = "0123456789ABCDEF";
  var hex_str = hex_digits[Math.floor(num / 16)] + hex_digits[num % 16];

  return hex_str;
}



window.RPM.Helpers.Utils =
  doWithEnabled: ($element, context, handler) ->
    if $element[0] && $element[0].disabled
      $element.enable()
      result = handler.apply(context)
      $element.disable()
    else
      result = handler.apply(context)
    result

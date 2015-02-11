this.module = (name) ->
  this[name] = this[name] or {}

module 'RPM'
module.apply(RPM, ['Helpers'])

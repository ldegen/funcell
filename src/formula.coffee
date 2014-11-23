module.exports = (body,props)->
  create = (->
    F =  ->
    (proto)->
      F.prototype = proto
      new F()
  )()

  expr = ()->
    cx = create this
    cx.__funcell__ ?= {}
    cx.ref=(fn)->
      # since this may be in an inner loop
      # we do not slice arguments
      len = arguments.length
      args = new Array(len - 1)
      i = 1
      while i < len
        args[i - 1] = arguments[i]
        i++
      fn.apply cx, args
    cx.from =(receiver)->
      cx2=create receiver
      cx2.__funcell__= cx.__funcell__
      cx2
    cx.self = cx
    body.apply(cx,arguments)

  constExpr = () -> body

  if typeof body == "function" then expr else constExpr


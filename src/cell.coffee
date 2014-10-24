module.exports = (expr0)->
  Formula = require("./formula")
  dirty=true
  value = undefined
  expr =()->undefined
  callbacks = []

  create = (->
    F =  ->
    (proto)->
      F.prototype = proto
      new F()
  )()

  invalidate = ->
    dirty=true
    i = callbacks.length
    while i--
      callbacks[i]()
    callbacks = []

  set = (newExpr)->
    if newExpr.length > 0
      throw new Error("Formulas in Cells must not contain free variables")
    expr=Formula(newExpr)
    invalidate()

  set expr0 if expr0

  cell = ()->
    self=this
    funcell = this.__funcell__
    if funcell?.invalidate?
      callbacks.push funcell.invalidate
    if dirty
      dirty=false
      cx = create self
      cx.__funcell__ =
        invalidate: invalidate
      value=expr.call(cx)
    else
      value
  cell.invalidate = invalidate
  cell.set = set

  cell

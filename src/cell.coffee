module.exports = (expr0)->
  Formula = require("./formula")
  dirty=true
  constant = false
  value = undefined
  expr =()->undefined
  debug=false
  cellName=undefined
  callbacks = []
  listeners = []

  create = (->
    F =  ->
    (proto)->
      F.prototype = proto
      new F()
  )()

  info = ->
    obj=
      name: cellName
      value: value
      constant: constant
      dirty: dirty
      callbacks: callbacks.map (f)->f.callingCell
      listeners: listeners.length
    JSON.stringify obj

  debugMsg =(msg)->
    return if !debug
    msg = "Cell #{cellName}: #{msg}"
    padding = Array(Math.max(30-msg.length,0)).join(" ")
    console.log msg,padding,info()


  invalidate = ->
    debugMsg "BEGIN invalidate"
    dirty=true
    oldVal=value
    i = callbacks.length
    copy =callbacks.concat()
    callbacks=[]
    while i--
      debugMsg "propagate #{copy[i].callingCell}"
      copy[i]()
    debugMsg "END invalidate"
    j = listeners.length
    debugMsg "checking listeners"
    if j>0 && cell() != oldVal
      while j--
        listeners[j](cell,oldVal)

  set = (newExpr)->
    if typeof newExpr == "function"
      constant = false
      if newExpr.length > 0
        throw new Error("Formulas in Cells must not contain free variables")
      expr=Formula(newExpr)
      debugMsg "reset (formula)"
    else
      expr = newExpr
      constant = true
      debugMsg "reset (constant)"
    invalidate()

  set expr0 if expr0

  cell = ()->
    self=this
    funcell = this.__funcell__
    if funcell?.invalidate? and callbacks.indexOf(funcell.invalidate) == -1
      callbacks.push funcell.invalidate
      debugMsg "registered callback #{funcell.invalidate.callingCell}"
    if dirty
      debugMsg "BEGIN evaluate"
      dirty=false
      if constant
        debugMsg "END evaluate (const)"
        value=expr
      else
        cx = create self
        invalidate.callingCell = cellName if debug
        cx.__funcell__ =
          invalidate: invalidate
        value=expr.call(cx)
        debugMsg "END evaluate"
        value
    else
      value
  cell.invalidate = invalidate
  cell.set = set
  cell.debug = (name)->
    debug=true
    cellName=name
    debugMsg "debug on"

  cell.changed = (listener)->
    cell()
    listeners.push listener
  cell

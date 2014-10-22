module.exports = (expr)->
  dirty=true
  value = undefined
  expr ?= ()->undefined
  callbacks = []

  invalidate = ->
    dirty=true
    i = callbacks.length
    while i--
      callbacks[i]()
    callbacks = []

  set = (newExpr)->
    expr=newExpr
    invalidate()

  ref = (other)->
    other(invalidate)

  cell = (cb)->
    if cb?
      callbacks.push cb
    if dirty
      dirty=false
      value=expr(ref)
    else
      value
  
  cell.invalidate = invalidate
  cell.set = set

  cell

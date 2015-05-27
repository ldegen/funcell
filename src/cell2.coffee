module.exports = ( ()->
  stack = []
  _cid = 0
  _push_stack = stack.push.bind stack
  _pop_stack = stack.pop.bind stack
  _peek_stack = ()->
    len =stack.length
    if len>0
      stack[len-1]


  _paddingLength = 30

  (self0,body0)->
    cid = _cid = _cid + 1
    formula = undefined
    constant = undefined
    cachedValue = undefined
    dirty = true
    dependentCells = {}
    listeners = []
    debug = false
    cellName = undefined

    info = ->
      obj=
        cid: cid
        name: cellName
        value: cachedValue
        constant: constant?
        dirty: dirty
        dependent: Object.keys(dependentCells)
        listeners: listeners.length
      JSON.stringify obj

    debugMsg =(msg0)->
      return if !debug
      msg0 = msg0() if typeof msg0 == "function"
      msg = "Cell #{cellName}: #{msg0}"
      _paddingLength = Math.max(_paddingLength,msg.length+1)
      padding = Array(_paddingLength-msg.length).join(" ")
      console.log msg,padding,info()

    _values = (obj)-> (val for key,val of obj)

    _invalidateAll = (cells)->
      cell.invalidate() for cell in cells

    invalidate = ()->
      # debugMsg "invalidate"
      dirty=true
      oldValue = cachedValue
      copy=_values(dependentCells)
      dependentCells={}
      _invalidateAll(copy)
      j = listeners.length
      if j>0 #&& getValue() != oldValue
        while j--
          listeners[j](cell,oldValue)

    setF = (v)->
     # if v != cachedValue
        if v.length > 0
          throw new Error("Formulas in Cells must not contain free variables")
        constant = undefined
        formula = if self? then v.bind self else v
        invalidate()
    setC = (v)->
      # if v != cachedValue
        formula = undefined
        constant = v
        invalidate()
    set = (v)->
      if typeof v == "function"
        setF v
      else
        setC v


    cell = ()->
      ## debugMsg "requested"
      caller = _peek_stack()
      if caller && not dependentCells[caller.cid]?
        # debugMsg -> "push caller #{caller.cellName()}"
        dependentCells[caller.cid] = caller
      getValue()

    getValue = ()->
      if dirty
        dirty = false
        cachedValue = evaluate()
      cachedValue

    evaluate = ()->
      if formula?
        # debugMsg "BEGIN evaluate (formula)"
        _push_stack cell
        result = formula()
        _pop_stack()
        # debugMsg "END evaluate (formula)"
        result
      else
        # debugMsg "evaluate (constant)"
        constant


    addListener = (l)->
      # debugMsg "register listener"
      listeners.push(l)

    cell.cid = cid
    cell.set = set
    cell.setF = setF
    cell.setC = setC
    cell.invalidate = invalidate
    cell.addListener = addListener
    cell.debug = (name)->
      cellName=name
      debug=true
      # debugMsg "debug on"

    cell.cellName = ()->cellName

    if arguments.length == 1
      body=self0
      self=undefined
    else if arguments.length == 2
      body = body0
      self = self0

    set body

    cell
  )()

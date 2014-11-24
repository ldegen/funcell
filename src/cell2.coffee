module.exports = ( ()->
  stack = []
  _push_stack = stack.push.bind stack
  _pop_stack = stack.pop.bind stack
  _peek_stack = ()->
    len =stack.length
    if len>0
      stack[len-1]


  _paddingLength = 30

  (self,body)->
    formula = undefined
    constant = undefined
    cachedValue = undefined
    dirty = true
    dependentCells = []
    listeners = []
    debug = false
    cellName = undefined

    info = ->
      obj=
        name: cellName
        value: cachedValue
        constant: constant?
        dirty: dirty
        dependent: dependentCells.map (f)->f.cellName()
        listeners: listeners.length
      JSON.stringify obj

    debugMsg =(msg0)->
      return if !debug
      msg0 = msg0() if typeof msg0 == "function"
      msg = "Cell #{cellName}: #{msg0}"
      _paddingLength = Math.max(_paddingLength,msg.length+1)
      padding = Array(_paddingLength-msg.length).join(" ")
      console.log msg,padding,info()

    invalidate = ()->
      debugMsg "invalidate"
      dirty=true
      oldValue = cachedValue
      i = dependentCells.length
      copy = dependentCells.concat()
      dependentCells=[]
      while i--
        debugMsg -> "propagate #{copy[i].cellName()}"
        copy[i].invalidate()
      j = listeners.length
      if j>0 && getValue() != oldValue
        while j--
          listeners[j](cell,oldValue)

    set = (v)->
      if v != cachedValue
        if typeof v == "function"
          if v.length > 0
            throw new Error("Formulas in Cells must not contain free variables")
          constant = undefined
          formula = v.bind self
        else
          formula = undefined
          constant = v
        invalidate()


    cell = ()->
      debugMsg "requested"
      caller = _peek_stack()
      if caller && dependentCells.indexOf(caller)==-1
        debugMsg -> "push caller #{caller.cellName()}"
        dependentCells.push caller
      getValue()
      
    getValue = ()->
      if dirty
        dirty = false
        cachedValue = evaluate()
      cachedValue

    evaluate = ()->
      if formula?
        debugMsg "BEGIN evaluate (formula)"
        _push_stack cell
        result = formula()
        _pop_stack()
        debugMsg "END evaluate (formula)"
        result
      else
        debugMsg "evaluate (constant)"
        constant


    addListener = (l)->
      debugMsg "register listener"
      listeners.push(l)


    cell.set = set
    cell.invalidate = invalidate
    cell.addListener = addListener
    cell.debug = (name)->
      cellName=name
      debug=true
      debugMsg "debug on"

    cell.cellName = ()->cellName
    
    if arguments.length==1
      body=self
      self=cell

    set body

    cell
  )()

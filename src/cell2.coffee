_stack = []
_top = -1
_cid = 0
_requests = 0
_misses = 0
_invalidated = 0
_push_stack = (v)->_stack.push v
_pop_stack = ()-> _stack.pop()
_peek_stack = ()-> _stack[_stack.length - 1]

# for mysterious reasons it seems much more performant to move this in
# a separate function
_insertCaller = (callerIds,id)->
  callerIds[id]=true

_info = (()->
  _infos = new Array(1000)
  _len = 0
  (cid0)->
    if (typeof cid0) == "undefined"
      inf = _infos[_len] =
        cid:_len
        dependentCellInfos:{}
        listeners:[]
        cachedValue: undefined
        cellName: undefined
        debug:false
        dirty:true
      _len++
      inf
    else
      _infos[cid0]
)()


_paddingLength = 30
_values = (obj)-> (val for key,val of obj)
##_debug = (cellInfo)->
  #if(cellInfo.cellName?)
  #  args = Array.prototype.slice.call(arguments)
  #  args[0] = "#{cellInfo.cellName ? 'anon'}(#{cellInfo.cid})"
  #  console.log.apply console,args

_invalidate = (cellInfo)->
  return if not cellInfo
  #_debug(cellInfo,"_invalidate")
  cellInfo.dirty=true
  oldValue = cellInfo.cachedValue
  copy=Object.keys cellInfo.dependentCellInfos
  cellInfo.dependentCellInfos={}
  _invalidateAll(copy)
  j = cellInfo.listeners.length
  if j>0 #&& getValue() != oldValue
    while j--
      cellInfo.listeners[j](cellInfo,oldValue)

_invalidateAll = (cids)->
    _invalidated++
    _invalidate(_info cid) for cid in cids


Cell=(self0,body0)->
  cellInfo = _info()
  cid = cellInfo.cid
  formula = undefined
  constant = undefined

  setF = (v)->
    if v.length > 0
      throw new Error("Formulas in Cells must not contain free variables")
    #_debug(cellInfo,"setF",v)
    constant = undefined
    formula = if self? then v.bind self else v
    _invalidate(cellInfo)
  setC = (v)->
    #_debug(cellInfo,"setC",v)
    formula = undefined
    constant = v
    _invalidate(cellInfo)
  set = (v)->
    if typeof v == "function"
      setF v
    else
      setC v



  getValue = ()->
    _requests++
    if cellInfo.dirty
      cellInfo.dirty = false
      _misses++
      cellInfo.cachedValue = evaluate()
    cellInfo.cachedValue

  cell = ()->
    callerId = _peek_stack()
    #_debug cellInfo, "req",callerId
    _insertCaller cellInfo.dependentCellInfos, callerId
    getValue()

  evaluate = ()->
    #_debug cellInfo, "eval"
    if formula?
      _push_stack cid
      result = formula()
      _pop_stack()
      result
    else
      constant


  addListener = (l)->
    cellInfo.listeners.push(l)

  cell.cid = cid
  cell.info = cellInfo
  cell.set = set
  cell.setF = setF
  cell.setC = setC
  cell.invalidate = ()->_invalidate cellInfo
  cell.addListener = addListener
  cell.debug = (name)->
    cellInfo.cellName=name
  cell.cellName = ()->cellInfo.cellName

  if arguments.length == 1
    body=self0
    self=undefined
  else if arguments.length == 2
    body = body0
    self = self0

  set body

  cell
Cell._stats=()->
  misses: _misses
  requests:_requests
  invalidated:_invalidated

module.exports=Cell

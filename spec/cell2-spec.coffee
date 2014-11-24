describe "The (2nd Generation)-Cell", ->
  Cell = require "../src/cell2"

  it "can be evaluated just as any other function", ->
    c = Cell -> 42
    expect(c()).toBe 42

  it "will bind this to the cell itself by default ", ->
    c = Cell -> this
    o = {}
    expect(c.call(o)).toBe c #... and not o!

  it "can optionaly bind this to custom object given to the constructor", ->
    o = {a:21}
    c = Cell o, -> this.a*2
    expect(c.call({})).toBe 42

  it "can not contain formulas with free variables",->
    expect( -> Cell (a,b)->a+b ).toThrow new Error("Formulas in Cells must not contain free variables")


  it "can be updated with a formula", ->
    c = Cell -> 42
    expect(c()).toBe 42
    c.set -> 43
    expect(c()).toBe 43

  it "can be updated with a constant", ->
    c = Cell 42
    expect(c()).toBe 42
    c.set 43
    expect(c()).toBe 43

  it "does not evaluate the same expression twice",->
    expr = createSpy "expr"
    c = Cell expr
    c()
    c()
    c()
    expect(expr.calls.length).toBe 1

  it "automatically propagates changes to dependent cells" , ->
    a = Cell 21
    b = (x) -> 2*x
    c = Cell -> b(a())
    expect(c()).toBe(42)
    a.set 32
    expect(c()).toBe(64)

  it "informs registered listeners when its value actually changes", ->
    a= Cell 42
    b= Cell -> 2*a()
    a.debug "a"
    b.debug "b"
    listener = createSpy("listener")
    expect(b()).toBe 84
    b.addListener listener
    a.set -> 6*7
    expect(listener).not.toHaveBeenCalled()
    a.set -> 21
    expect(listener).toHaveBeenCalledWith(b,84)
    

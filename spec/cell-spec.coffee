describe "A Cell", ->
  Cell = require "../src/cell"
  Formula = require "../src/formula"
  it "can be evaluated just as any other function", ->
    c = Cell -> 42
    expect(c()).toBe 42

  it "can not contain formulas with free variables",->
    expect( -> Cell (a,b)->a+b ).toThrow new Error("Formulas in Cells must not contain free variables")


  it "can be referenced from within a formula", ->
    c = Cell -> 42
    f = Formula -> 2+@ref(c)/2

    expect(f()).toBe 23

  it "can be referenced from a formula in a different scope",->
    a =
      cell:Cell -> @val
      val:42
    b =
      formula: Formula -> @val+@from(a).cell()/@val
      val:2

    expect(b.formula()).toBe 23


  it "does not evaluate the same expression twice",->
    expr = createSpy "expr"
    c = Cell expr
    c()
    c()
    c()
    expect(expr.calls.length).toBe 1

  it "can replace the expression with a new expression",->
    c = Cell -> 42
    expect(c()).toBe 42
    c.set -> 23
    expect(c()).toBe 23

  it "can be passed a callback that is to be executed when the cell value changes",->
    c = Cell -> 42
    l1 = createSpy "l1"
    l2 = createSpy "l2"
    expect(c.call({__funcell__:{invalidate:l1}})).toBe 42
    expect(c.call({__funcell__:{invalidate:l2}})).toBe 42
    expect(l1).not.toHaveBeenCalled()
    expect(l2).not.toHaveBeenCalled()
    c.set -> 23
    expect(l1).toHaveBeenCalled()
    expect(l2).toHaveBeenCalled()

  it "drops callbacks once having called them",->
    c = Cell -> 42
    l = createSpy "l"
    expect(c.call({__funcell__:{invalidate:l}})).toBe 42
    c.set -> 23
    c.set -> 24
    expect(l.calls.length).toBe(1)


  it "automatically watches referenced cells and invalidates the own value if they change",->
    a = Cell -> 42
    b = Cell -> 2+@ref(a)/2
    expect(b()).toBe(23)
    a.set -> 6
    expect(b()).toBe(5)
  
  it "change propagation works with indirectly referenced cells",->
    a = Cell -> 42
    b = Formula -> 2+@ref(a)/2
    c = Cell -> @ref(b)+2
    expect(c()).toBe(25)
    a.set -> 6
    expect(c()).toBe(7)
  
  it "change propagation works with cells and formulas living in different scopes",->
    a =
      cell: Cell -> @self.val()
      val: Cell -> 42
    b =
      formula: Formula (divisor)-> @self.val()+@from(a).cell()/divisor
      val: Cell -> 2
    c = Cell -> @from(b).formula(2)+2
    expect(c()).toBe(25)
    a.val.set -> 6
    expect(c()).toBe(7)

  it "can call a callback whenever its value changes",->
    a= Cell -> 42
    b= Cell -> 2*@ref(a)
    a.debug("a")
    b.debug("b")
    listener = createSpy("listener")
    console.log "before"
    b.changed listener
    a.set -> 6*7
    console.log "after"
    expect(listener).not.toHaveBeenCalled()
    a.set -> 21
    expect(listener).toHaveBeenCalledWith(b,84)



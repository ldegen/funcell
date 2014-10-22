describe "A Cell", ->
  Cell = require "../src/cell"
  it "holds an expression which is evaluated on demand", ->
    c = Cell -> 42
    expect(c()).toBe 42

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

  it "can be given a callback that is to be executed when the cell value changes",->
    c = Cell -> 42
    l1 = createSpy "l1"
    l2 = createSpy "l2"
    expect(c(l1)).toBe 42
    expect(c(l2)).toBe 42
    expect(l1).not.toHaveBeenCalled()
    expect(l2).not.toHaveBeenCalled()
    c.set -> 23
    expect(l1).toHaveBeenCalled()
    expect(l2).toHaveBeenCalled()

  it "drops callbacks once having called them",->
    c = Cell -> 42
    l = createSpy "l"
    expect(c(l)).toBe 42
    c.set -> 23
    c.set -> 24
    expect(l.calls.length).toBe(1)

  it "allows expressions to reference another cell",->
    a = Cell -> 42
    b = Cell (ref)-> 2+ref(a)/2
    expect(b()).toBe(23)

  it "automatically watches referenced cells and invalidates the own value if they change",->
    a = Cell -> 42
    b = Cell (ref)-> 2+ref(a)/2
    expect(b()).toBe(23)
    a.set -> 6
    expect(b()).toBe(5)

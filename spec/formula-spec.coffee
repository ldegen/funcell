describe "A Formula", ->
  Formula = require "../src/formula"
  it "can be evaluated just as any other function",->
    a =
      sum: Formula (a,b)->a+b+@val
      val: 5
    expect(a.sum(3,4)).toBe 12

 
  it "can reference a formula in the local scope via 'this.ref(formula, args...)'",->
    sum=Formula (a,b)->a+b
    exp=Formula (a,b,c)->c*@ref(sum,a,b)
    expect(exp(2,3,4)).toBe 20

  it "passes the __funcell__ context along to all nested formulas",->
    cx={}
    cell = {cell:"cell"}

    sum=Formula (a,b)->
      cx.sum=@__funcell__
      a+b
    exp=Formula (a,b,c)->
      cx.exp=@__funcell__
      c*@ref(sum,a,b)

    result = exp.call({__funcell__:cell},2,3,4)
    expect(result).toBe 20
    expect(cx.sum.cell).toBe "cell"
    expect(cx.exp.cell).toBe "cell"

  it "can reference member formulas via 'this.from(object).formula(args...)'",->
    cx={}
    cell = {cell:"cell"}
    
    sum=
      formula:Formula (a,b)->
        cx.sum=@__funcell__
        a+b+@c
      c:3/4
    exp=
      formula:Formula (a,b,c)->
        cx.exp=@__funcell__
        c*@from(sum).formula(a,b)
      __funcell__:cell

    result = exp.formula(2,3,4)
    expect(result).toBe 23
    expect(cx.sum).toBe cell
    expect(cx.exp).toBe cell
  it "offsers 'this.self' as a shortcut for 'this.from(this)'",->
    cx={}
    cell = {cell:"cell"}

    
    scope=
      sum:Formula (a,b)->
        cx.sum=@__funcell__
        a+b+@c
      c:3/4
      mult:Formula (a,b,c)->
        cx.exp=@__funcell__
        c*@self.sum(a,b)
      __funcell__:cell

    result = scope.mult(2,3,4)
    expect(result).toBe 23
    expect(cx.sum).toBe cell
    expect(cx.exp).toBe cell


import pdba/types
import pdba/utils


proc toQCond(c: QCond): QCond = c
proc toQCond(c: QCol): QCond = QCond(kind: QCondKind.ckCol, col: c)
proc toQCond[T](c: T): QCond = QCond(kind: QCondKind.ckOne, exp: $c)
# proc toQCond(c: int|float|string): QCond = QCond(exp: fmt"'{c}'", op: "")


proc infix*[T1: QCond, T2: QCond](op: string, lhs: T1, rhs: T2): QCond =
  QCond(kind: QCondKind.ckBin, lhs: lhs.toQCond, op: op, rhs: rhs.toQCond)

proc infix*[T1: QCol|DbValue, T2: QCol|DbValue](op: string, lhs: T1, rhs: T2): QCond =
  QCond(kind: QCondKind.ckBin, lhs: lhs.toQCond, op: op, rhs: rhs.toQCond)

# Comparison operator with QCol
# QCol == int  --> QCond 
# int  == QCol --> QCond
# QCol == QCol --> QCond
proc `==`*[T: int|float|string|DateTime](lhs: QCol, rhs: T): QCond = infix("=", lhs, rhs.dbValue)
proc `==`*(lhs: QCol, rhs: DbValue): QCond = infix("=", lhs, rhs)
proc `==`*(lhs: QCol, rhs: QCol): QCond = infix("=", lhs, rhs)
proc `<`*[T: int|float|string|DateTime](lhs: QCol, rhs: T): QCond = infix("<", lhs, rhs.dbValue)
proc `<`*[T: int|float|string|DateTime](lhs: T, rhs: QCol): QCond = infix(">", rhs, lhs.dbValue)
proc `<`*(lhs: QCol, rhs: DbValue): QCond = infix("<", lhs, rhs)
proc `<`*(lhs: DbValue, rhs: QCol): QCond = infix(">", rhs, lhs)
proc `<`*(lhs: QCol, rhs: QCol): QCond = infix("<", lhs, rhs)
proc `<=`*[T: int|float|string|DateTime](lhs: QCol, rhs: T): QCond = infix("<=", lhs, rhs.dbValue)
proc `<=`*[T: int|float|string|DateTime](lhs: T, rhs: QCol): QCond = infix(">=", rhs, lhs.dbValue)
proc `<=`*(lhs: QCol, rhs: QCol): QCond = infix("<=", lhs, rhs)

# Comparison operator with QCond
proc `not`*(c: QCond): QCond =
  QCond(kind: QCondKind.ckNot, cond: c)

proc `and`*(lhs: QCond, rhs: QCond): QCond =
  infix("and", lhs, rhs)

proc `or`*(lhs: QCond, rhs: QCond): QCond =
  infix("or", lhs, rhs)

proc `$`*(c: QCond): string =
  case c.kind
  of QCondKind.ckNone:
    ""
  of QCondKind.ckNot:
    fmt"not ({c.cond})"
  of QCondKind.ckCol:
    c.col.name
  of QCondKind.ckOne:
    c.exp
  of QCondKind.ckBin:
    let
      lh = if c.lhs.kind == ckBin: fmt"({c.lhs})" else: $(c.lhs)
      rh = if c.rhs.kind == ckBin: fmt"({c.rhs})" else: $(c.rhs)
    fmt"{lh} {c.op} {rh}"


import pdba/types
import pdba/condition
import pdba/utils

export types

## INSERT STATEMENT
proc insert*(t: QTbl): QInsertOne =
  QInsertOne(
    table: t,
    data: initOrderedTable[string, DbValue]()
  )

proc `[]=`*[T](qi: var QInsertOne, k: string, v: T) =
  qi.data[k] = dbValue(v)

proc `$`*(qi: QInsertOne): string =
  if qi.data.len == 0:
    return ""
  let s = @[
    "INSERT INTO",
    qi.table.table_name,
    "(" & toSeq(qi.data.keys).mapIt(qi.table.cols[it].name).join(", ") & ")",
    "VALUES",
    "(" & toSeq(qi.data.values).join(", ") & ")",
  ]
  s.join(" ") & ";"

proc toSql*(s: QInsertOne): SqlQuery =
  SqlQuery($s)

proc getRow*(conn: QConn; qi: QInsertOne): Option[QRow] =
  if qi.data.len == 0:
    return none(QRow)
  let ph = (1..(qi.data.len)).mapIt("$" & $it).join(", ")
  let keys = toSeq(qi.data.keys)
  let retKeys = toSeq(qi.table.cols.values).mapIt(it.name)
  let s = @[
    "INSERT INTO",
    qi.table.table_name,
    "(" & keys.mapIt(qi.table.cols[it].name).join(", ") & ")",
    "VALUES",
    "(" & ph & ")",
    "RETURNING " & retKeys.join(", "),
    # "RETURNING (" & qi.table.primary_keys.join(", ") & ")",
  ]
  var sq = SqlQuery(s.join(" ") & ";")
  var res = conn.dbconn.getRow(sq, toSeq(qi.data.values))
  if res.isSome:
    var fields = initOrderedTable[string, DbValue]()
    var row = res.get
    for i, v in row:
      fields[retKeys[i]] = v
    QRow(fields: fields).some
  else:
    none(QRow)

## UPDATE STATEMENT
proc update*(t: QTbl): QUpdate =
  QUpdate(
    table: t,
    data: initOrderedTable[string, DbValue](),
    cond: QCond()
  )

template c*(qu: QUpdate, c: untyped): QCol =
  qu.cols[astToStr(c)]

proc `[]=`*[T](qu: var QUpdate, k: string, v: T) =
  qu.data[k] = dbValue(v)

proc where*(qu: QUpdate, c: QCond): QUpdate =
  result = qu
  result.cond = c

proc `$`*(qu: QUpdate): string =
  if qu.data.len == 0 or qu.cond.kind == QCondKind.ckNone:
    return ""
  var s = @[
    "UPDATE",
    qu.table.table_name,
    "SET",
    toSeq(qu.data.pairs).mapIt(fmt"{qu.table.cols[it[0]].name} = {it[1]}").join(", "),
    "WHERE",
    $(qu.cond),
  ]
  s.join(" ") & ";"

proc toSql*(s: QUpdate): SqlQuery =
  SqlQuery($s)

## DELETE STATEMENT
proc delete*(t: QTbl): QDelete =
  QDelete(
    table: t,
    cond: QCond()
  )

template c*(qu: QDelete, c: untyped): QCol =
  qu.cols[astToStr(c)]

proc where*(qu: QDelete, c: QCond): QDelete =
  result = qu
  result.cond = c

proc `$`*(qu: QDelete): string =
  if qu.cond.kind == QCondKind.ckNone:
    return ""
  var s = @[
    "DELETE FROM",
    qu.table.table_name,
    "WHERE",
    $(qu.cond),
  ]
  s.join(" ") & ";"

proc toSql*(s: QDelete): SqlQuery =
  SqlQuery($s)

import pdba/types
import pdba/condition
import pdba/utils

proc query*(t: QTbl): QSelect =
  result.db = t.db
  result.cond = QCond(kind: QCondKind.ckNone)
  result.tbl = t
  result.selectCols = t.allCols

# QSelect
proc `$`*(q: QSelect): string =
  var s = @[
    "SELECT " & q.selectCols.mapIt(it.name).join(", "),
    "FROM " & q.tbl.table_name,
  ]
  if q.cond.kind != QCondKind.ckNone:
    s.add("WHERE")
    s.add($(q.cond))
  s.join(" ")

proc toSql*(s: QSelect): SqlQuery =
  SqlQuery($s)

proc table*(q: QSelect, tname: string): QSelect =
  var t = q.db.tbl[tname]
  result = q
  result.tbl = t
  if q.selectCols.len == 0:
    result.selectCols = t.allCols

proc select*(q: QSelect, cols: seq[string]): QSelect =
  result = q
  result.selectCols = cols.mapIt q.db.tbl[q.tbl.name].cols[it]

proc where*(q: QSelect, c: QCond): QSelect =
  result = q
  result.cond = c

# Shorthand method
proc byId*(t: QTbl, id: int): QSelect =
  t.query.where t.cols["id"] == id

proc where*(t: QTbl, cond: QCond): QSelect =
  t.query.where cond

proc toQRow*(row: Row, query: QSelect): QRow =
  var fields = initOrderedTable[string, DbValue]()
  for i, c in query.selectCols:
    fields[c.name] = row[i]
  QRow(fields: fields)

proc getRow*(conn: QConn; query: QSelect; args: varargs[DbValue, dbValue]): Option[QRow] =
  logger.log(lvlDebug, "SQL: " & $query)
  var s = SqlQuery($query)
  var res = conn.dbconn.getRow(s, args)
  if res.isSome:
    var values = res.get()
    some(toQRow(values, query))
  else:
    none(QRow)

proc getAllRows*(conn: QConn, query: QSelect, args: varargs[DbValue, dbValue]): QResultSet =
  logger.log(lvlDebug, "SQL: " & $query)
  var res = conn.dbconn.getAllRows(query.toSql, args)
  var rows: seq[QRow] = @[]
  for r in res:
    rows.add(toQRow(r, query))
  QResultSet(rows: rows)

iterator items*(rs: QResultSet): QRow =
  for row in rs.rows:
    yield row

iterator pairs*(row: QRow): (string, DbValue) =
  for k, v in row.fields.pairs:
    yield (k, v)

iterator items*(row: QRow): DbValue =
  for v in row.fields.values:
    yield v

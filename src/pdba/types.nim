import pdba/utils

type
  QOnDelKind* = enum
    okNoAction = "NO ACTION"
    okRestrict = "RESTRICT"
    okCascade = "CASCADE"
    okSetNull = "SET NULL"
    okSetDefault = "SET DEFAULT"

  QCol* = ref object
    name*: string
    dbtype*: string
    table_name*: string
    default*: string
    nullable*: bool

  QForeignKey* = ref object
    reftable*: string
    cols*: seq[string]
    refcols*: seq[string]
    ondelete*: QOnDelKind

  QTbl* = ref object
    name*: string
    table_name*: string
    primary_keys*: seq[string]
    unique*: seq[seq[string]]

    db*: QDB
    schema_name*: string
    cols*: OrderedTable[string, QCol]
    foreign_keys*: seq[QForeignKey]

  QConn* = ref object
    dbconn*: DbConn

  QDB* = ref object
    dbname*: string
    host*: string
    port*: string
    user*: string
    pass*: string
    tbl*: OrderedTable[string, QTbl]
    pool*: seq[QConn]
    poolSize*: int
    timeout*: int
    poolCursor*: Natural

  QCondKind* = enum
    ckNone,
    ckNot,
    ckCol,
    ckOne,
    ckBin

  QCond* = ref object
    case kind*: QCondKind
    of ckNone: dummy: string
    of ckNot: cond*: QCond
    of ckCol: col*: QCol
    of ckOne: exp*: string
    of ckBin:
      op*: string
      lhs*, rhs*: QCond

  QLimit* = ref object

  QSelect* = object
    db*: QDB
    selectCols*: seq[QCol]
    tbl*: QTbl
    cond*: QCond
    limit*:  QLimit

template t*(q: QDB, tname: untyped): QTbl =
  ## QDB.t table_name -> QTbl
  q.tbl[astToStr(tname)]

# QTbl
proc allCols*(t: QTbl): seq[QCol] =
  for c in t.cols.values:
    result.add(c)

template c*(t: QTbl, c: untyped): QCol =
  ## QTbl.c column_name -> QCol
  t.cols[astToStr(c)]

## conversion DbValue and JsonNode
proc dbValue*(j: JsonNode): DbValue =
  case j.kind:
  of JString:
    dbValue(j.str)
  of JInt:
    dbValue(int(j.num))
  of JFloat:
    dbValue(j.fnum)
  of JNull:
    dbValue(nil)
  of JBool:
    dbValue(j.bval)
  of JObject:
    dbValue(nil)
  of JArray:
    dbValue(nil)

proc dbValue(v: DateTime): DbValue =
  dbValue(v.utc.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"))

## DML object
type
  QInsertOne* = object
    table*: QTbl
    data*: OrderedTable[string, DbValue]

  QUpdate* = object
    table*: QTbl
    data*: OrderedTable[string, DbValue]
    cond*: QCond

  QDelete* = object
    table*: QTbl
    cond*: QCond

type
  QResultSet* = object
    rows*: seq[QRow]

  QRow* = object
    fields*: OrderedTable[string, DbValue]

proc toJsonNode*(v: DbValue): JsonNode=
  case v.kind:
  of dvkBool:
    newJBool v.b
  of dvkInt:
    newJInt v.i
  of dvkFloat:
    newJFloat v.f
  of dvkString:
    newJString v.s
  of dvkTimestamptz:
    newJString $(v.t)
  of dvkOther:
    newJString $v
  of dvkNull:
    newJNull()

proc toJsonNode*[T: Table[string, DbValue]|OrderedTable[string, DbValue]](t: T): JsonNode =
  result = newJObject()
  result.fields = toSeq(t.pairs).mapIt((it[0], it[1].toJsonNode)).toOrderedTable

proc toJsonNode*(row: QRow): JsonNode =
  toJsonNode(row.fields)

proc toJsonNode*[T](v: seq[T]): JsonNode =
  result = newJArray()
  result.elems = v.mapIt(it.toJsonNode)

proc toJsonNode*(rs: QResultSet): JsonNode =
  rs.rows.toJsonNode

proc toSql*(s: string): SqlQuery =
  SqlQuery($s)

proc `$`*(s: SqlQuery): string =
  string(s)

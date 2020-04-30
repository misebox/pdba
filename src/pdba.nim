import os
import strformat
import db_common
import yaml/serialization
import ndb/postgres
import tables
import options
import pdba/types
import pdba/loadyaml
import pdba/query
import pdba/ddl
import pdba/dml
import pdba/condition
import pdba/utils

export tables
export options
export postgres.DbConn
export postgres.open
export db_common.SqlQuery
export db_common.DbError

export types
export query
export ddl
export dml
export condition
export loadyaml


proc initQDB*(host="127.0.0.1", port="1111",
              dbname="dbtest", user="dbuser", pass="secret",
              poolSize=3, timeout=10000): QDB =
  QDB(
    host: host,
    port: port,
    dbname: dbname,
    user: user,
    pass: pass,
    pool: initDeque[QConn](),
    poolSize: poolSize,
    timeout: timeout
  )

proc connect*(q: QDB, host: string, port: string,
              dbname: string, user: string, pass: string): QConn=
  let startTime = epochTime()
  var conn: DbConn = nil
  while true:
    try:
      conn = open(fmt"{host}:{port}", user, pass, dbname)
      break
    except DbError:
      discard
    if (epochTime() - startTime) <= (q.timeout / 1000):
      os.sleep(100)
      debug("Retry to connect")
      continue
  if conn == nil:
    var e: ref DbError
    new(e)
    e.msg = "Connection timeout"
    raise e
  QConn(dbconn: conn)

proc connect*(q: QDB): QConn =
  # Use pool
  if q.pool.len >= q.poolSize:
    while q.pool.len > 0:
      try:
        # Ping to DB
        var opt = q.pool.peekFirst.dbconn.getRow SqlQuery("SELECT 1")
        if opt.isSome and opt.get[0].i == 1:
          return q.pool.peekFirst
      except DbError:
        discard q.pool.popFirst
  # New Connection
  let conn = q.connect(host=q.host, port=q.port,
                       dbname=q.dbname, user=q.user, pass=q.pass)
  if q.poolSize > 0:
    q.pool.addLast(conn)
  conn

proc exec*(conn: QConn, s: SqlQuery, args: varargs[DbValue, dbValue]) =
  logger.log(lvlDebug, "exec: " & $s & ", " & $args)
  conn.dbconn.exec(s, args)

proc exec*[T: QSelect|QInsertOne|QUpdate|QDelete](conn: QConn, q: T) =
  conn.exec q.toSql

proc close*(c: QConn) =
  c.close

proc begin*(c: QConn) =
  c.exec "begin;".toSql

proc commit*(c: QConn) =
  c.exec "commit;".toSql

proc rollback*(c: QConn) =
  c.exec "rollback;".toSql

template withTransaction*(c: QConn, body: untyped): untyped =
  c.begin
  try:
    body
    c.commit
  except:
    c.rollback

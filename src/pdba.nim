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

export types
export query
export ddl
export dml
export condition
export loadyaml


proc initQDB*(host="127.0.0.1", port="1111", dbname="dbtest", user="dbuser", pass="secret"): QDB =
  QDB(
    host: host,
    port: port,
    dbname: dbname,
    user: user,
    pass: pass,
  )

proc connect*(q: QDB, host: string, port: string, dbname: string, user: string, pass: string): QConn=
  let conn = open(fmt"{host}:{port}", user, pass, dbname)
  QConn(dbconn: conn)

proc connect*(q: QDB): QConn=
  q.connect(host=q.host, port=q.port, dbname=q.dbname, user=q.user, pass=q.pass)

proc exec*(conn: QConn, s: SqlQuery, args: varargs[DbValue, dbValue]) =
  logger.log(lvlDebug, "exec: " & $s & ", " & $args)
  conn.dbconn.exec(s, args)

proc exec*[T: QSelect|QInsertOne|QUpdate|QDelete](conn: QConn, q: T) =
  conn.exec q.toSql


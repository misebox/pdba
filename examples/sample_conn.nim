import os
import pdba

block:
  var
    q = initQDB(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")
    conn: QConn
  conn = q.connect
  q.loadDBYaml("examples/short.yaml")
  let
    tCat = q.tbl["category"]
    tTask = q.tbl["task"]
  conn.exec tCat.sqlDropTable
  conn.exec tCat.sqlCreateTable

block:
  var
    q = pdba.loadDBYaml("examples/short.yaml")
    tCat = q.tbl["category"]
    tTask = q.tbl["task"]
    conn = q.connect(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")
  conn.exec tCat.sqlDropTable
  conn.exec tCat.sqlCreateTable

block:
  var
    q = initQDB(host="localhost", port="15432",
                dbname="dbexample", user="dbuser", pass="dbpass",
                poolSize=2)
    conns: seq[QConn]
  for i in 0..<3:
    let conn = q.connect
    echo repr(conn)
    conns.add(conn)
  # Pool size is 2
  assert addr(conns[0].dbconn) != addr(conns[1].dbconn)
  assert addr(conns[0].dbconn) == addr(conns[2].dbconn)
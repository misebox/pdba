import pdba

block:
  var
    q = initQDB(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")
    conn: QConn
  # wait 10 sec for connection
  for i in 1..10: 
    try:
      conn = q.connect
      break
    except DbError:
      os.sleep(1000)
      continue
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

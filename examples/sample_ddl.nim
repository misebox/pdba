import sequtils
import pdba

var
  # Load schema
  q = loadDBYaml("examples/short.yaml")
  # QConn
  conn = q.connect(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")
  tCat = q.tbl["category"]
  tTask = q.tbl["task"]

echo toSeq(q.tbl.keys)

## DDL
conn.exec tTask.sqlDropTable
conn.exec tCat.sqlDropTable
conn.exec tCat.sqlCreateTable
conn.exec tTask.sqlCreateTable
conn.exec tTask.sqlDropTable
conn.exec tCat.sqlDropTable
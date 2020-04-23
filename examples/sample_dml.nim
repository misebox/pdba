import strformat
import tables
import sequtils
import db_common
import options
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

## DML
block:
  ## just insert
  var qi = tCat.insert
  qi["name"] = "programming"
  qi["memo"] = "Implement something"
  conn.exec qi

  ## insert and get row
  qi["name"] = "find job"
  qi["memo"] = "finding job"
  var row = conn.getRow qi
  echo row.type
  if row.isSome:
    echo row.get

block:
  var qi = tTask.insert
  qi["category_id"] = 1
  qi["name"] = "taskA"
  qi["description"] = "desc1"
  conn.exec qi

  qi["category_id"] = 1  # foreign key
  qi["name"] = "taskB"
  qi["description"] = "desc2"
  conn.exec qi

  var qu = tTask.update
  qu = qu.where qu.table.cols["name"] == "taskB"
  qu["category_id"] = 2
  qu["name"] = "taskBBBB"
  qu["description"] = "desc2222"
  conn.exec qu

## Select
echo tTask.query
var rows = conn.getAllRows tTask.query
for row in rows:
  echo row

for row in conn.getAllRows tCat.query:
  echo row

## Delete
conn.exec tCat.delete.where(tCat.cols["id"] == 1)
for row in conn.getAllRows(tCat.query):
  echo row

## drop table
conn.exec tTask.sqlDropTable
conn.exec tCat.sqlDropTable

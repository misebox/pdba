import pdba

var
  ## Load schema
  q = loadDBYaml("examples/short.yaml")

  ## Connect to DB
  conn = q.connect(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")

  ## Table objects (QTbl)
  tCat = q.tbl["category"]
  tTask = q.tbl["task"]

## Create tables
conn.exec tCat.sqlCreateTable
conn.exec tTask.sqlCreateTable

## Just insert
conn.withTransaction:
  for i in 1..3:
    var qi = tCat.insert
    qi["name"] = "category " & $i
    qi["memo"] = "memo " & $i
    conn.exec qi
  block:
    var qi = tTask.insert
    qi["category_id"] = 1
    qi["name"] = "taskA"
    qi["description"] = "desc1"
    conn.exec qi
  block:
    var qi = tTask.insert
    qi["category_id"] = 1
    qi["name"] = "taskB"
    qi["description"] = "desc2"
    conn.exec qi

## Insert and get data
block:
  var qi = tCat.insert
  qi["name"] = "dummy name"
  qi["memo"] = "dummy memo"
  var row = conn.getRow qi
  echo row.type
  if row.isSome:
      echo row.get

## Update
block:
  var qu = tCat.update.where tCat.cols["name"] == "category_3"
  qu["memo"] = "updated memo"
  conn.exec qu

## Select
echo tTask.query
var rows = conn.getAllRows tTask.query
for row in rows:
  echo row

for row in conn.getAllRows tCat.query:
  echo row

## Delete
conn.begin
conn.exec tTask.delete.where(tTask.cols["id"] == 1)
var opt = conn.getRow(tTask.query.where(tTask.cols["id"] == 1))
echo opt.isSome
conn.rollback
opt = conn.getRow(tTask.query.where(tTask.cols["id"] == 1))
if opt.isSome:
  echo opt.get

## drop table
conn.exec tTask.sqlDropTable
conn.exec tCat.sqlDropTable

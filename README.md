# pdba
A postgres DB adapter for nim.

## Schema definition

examples/short.yaml

```
tables:
  - name: category
    table_name: categories
    columns:
      - {name: id, dbtype: serial}
      - {name: name, dbtype: varchar(30)}
      - {name: memo, dbtype: varchar(100), nullable: true}
    primary_keys:
      - id
    unique:
      - ["name"]
  - name: task
    table_name: tasks
    columns:
      - {name: id, dbtype: serial}
      - {name: category_id, dbtype: integer, nullable: true}
      - {name: name, dbtype: varchar(30)}
      - {name: description, dbtype: varchar(200)}
    primary_keys:
      - id
    unique:
      - ["name"]
    foreign_keys:
      - reftable: category
        cols: ["category_id"]
        refcols: ["id"]
        ondelete: set null
```

## DB Access

examples/sample_dml.nim

```
import pdba

var
  ## QDB Object
  q = initQDB(host="localhost", port="15432", dbname="dbexample", user="dbuser", pass="dbpass")

  ## Load schema
  q.loadDBYaml("examples/short.yaml")

  ## Connect to DB
  conn = q.connect

  ## Table objects (QTbl)
  tCat = q.tbl["category"]
  tTask = q.tbl["task"]

## Create tables
conn.exec tCat.sqlCreateTable
conn.exec tTask.sqlCreateTable

## Just insert
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
conn.exec tTask.delete.where(tTask.cols["id"] == 1)
for row in conn.getAllRows(tTask.query):
  echo row

## drop table
conn.exec tTask.sqlDropTable
conn.exec tCat.sqlDropTable
```

## Examples

Execute some simple examples

(See `examples/*.nim`)

```
nimble examples
```

## Test

```
nimble test
```
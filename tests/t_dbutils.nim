import unittest
import pdba

suite "test dbutils":
  setup:
    var
      q = initQDB(host="localhost", port="1111", dbname="dbtest", user="dbuser", pass="dbpass")
    q.loadDBYaml("./tests/testdb.yaml")
    let
      t1: QTbl = q.tbl["category"]
      t2: QTbl = q.tbl["task"]

  test "QDB":
    assert typeof(q) is QDB
    assert q.host == "localhost"
    assert q.port == "1111"
    assert q.dbname == "dbtest"
    assert q.user == "dbuser"
    assert q.pass == "dbpass"
    assert q.tbl.len == 2
    assert q.tbl["category"] is QTbl
    assert q.t(category) is QTbl
    var t = q.t category
    assert t is QTbl

  test "QTbl":
    var 
      qt1 = q.t category
      qt2 = q.t task
    assert typeof(qt1) is QTbl
    assert qt1.name == "category"
    assert qt1.table_name == "categories"
    assert typeof(qt1.cols) is OrderedTable[string, QCol]
    assert qt1.cols.len == 3
    assert qt1.cols["id"].name == "id"
    assert qt1.cols["id"].dbtype == "integer"
    assert qt1.cols["name"].name == "name"
    assert qt1.cols["name"].dbtype == "varchar(30)"
    assert qt1.cols["memo"].name == "memo"
    assert qt1.cols["memo"].dbtype == "varchar(100)"
    assert qt1.cols["memo"].nullable == true

    assert typeof(qt2) is QTbl
    assert qt2.name == "task"
    assert qt2.table_name == "tasks"
    assert typeof(qt2.cols) is OrderedTable[string, QCol]
    assert qt2.cols.len == 4
    assert qt2.cols["id"].name == "id"
    assert qt2.cols["id"].dbtype == "serial"
    assert qt2.cols["category_id"].name == "category_id"
    assert qt2.cols["category_id"].dbtype == "integer"
    assert qt2.cols["name"].name == "name"
    assert qt2.cols["name"].dbtype == "varchar(30)"
    assert qt2.cols["description"].name == "description"
    assert qt2.cols["description"].dbtype == "varchar(200)"

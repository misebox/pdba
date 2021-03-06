import unittest
import pdba


suite "dbcore/dml":
  setup:
    let
      q = loadDBYaml("./tests/testdb.yaml")
      t1: QTbl = q.t category
      t2: QTbl = q.t task
  test "QInsert":
    var qi = t1.insert
    assert $qi == ""
    qi["id"] = 2
    qi["name"] = "Category2"
    assert $qi == "INSERT INTO categories (id, name) VALUES (2, 'Category2');"

  test "QUpdate":
    var qu = t1.update
    echo $qu
    assert $qu == ""
    qu["name"] = "Category2"
    var quw = qu.where(t1.cols["id"] == 2)
    echo $quw
    assert $quw == "UPDATE categories SET name = 'Category2' WHERE id = 2;"
    assert $quw == $qu.byId(2)

  test "QDelete":
    var qd = t1.delete
    echo $qd
    assert $qd == ""
    var qdw = qd.where(t1.cols["id"] == 2)
    echo $qdw
    assert $qdw == "DELETE FROM categories WHERE id = 2;"
    assert $qdw == $qd.byId(2)

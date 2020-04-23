import unittest
import pdba

suite "test query":
  setup:
    let
      qdb = pdba.loadDBYaml("tests/testdb.yaml")

  test "Generating SQL that select all columns":
    var s = qdb.tbl["category"].query
    assert $s == "SELECT id, name, memo FROM categories"

  test "Generating SQL that select only id column":
    var s = qdb.tbl["category"].query.select(@["id"])
    assert $s == "SELECT id FROM categories"

  test "QSelect from QTbl":
    var s: QSelect
    let
      t = qdb.t category
      cId = t.c id
      cName = t.c name
    s = t.query.where(cId == 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id = 1"

    s = t.query.where(cId == 0.1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id = 0.1"

    s = t.query.where(cName == "abc")
    assert $s == "SELECT id, name, memo FROM categories WHERE name = 'abc'"

    s = t.query.where(cId == 1 and cName == "abc")
    assert $s == "SELECT id, name, memo FROM categories WHERE (id = 1) and (name = 'abc')"

    s = t.query.where(cId > 1 and cName == "abc")
    assert $s == "SELECT id, name, memo FROM categories WHERE (id > 1) and (name = 'abc')"

    s = t.query.where(cId != 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE not (id = 1)"
    s = t.query.where(cId > 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id > 1"
    s = t.query.where(cId < 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id < 1"
    s = t.query.where(cId >= 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id >= 1"
    s = t.query.where(cId <= 1)
    assert $s == "SELECT id, name, memo FROM categories WHERE id <= 1"



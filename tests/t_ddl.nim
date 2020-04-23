import unittest
import strutils
import pdba

suite "test dbutils":
  setup:
    let
      q = loadDBYaml("./tests/testdb.yaml")
      t1: QTbl = q.tbl["category"]
      t2: QTbl = q.tbl["task"]

  test "test sqlCreateTable":
    let
      s = t1.sqlCreateTable
      ex = @[
        "CREATE TABLE IF NOT EXISTS categories (",
        "  id integer DEFAULT nextval('categories_id_seq'),",
        "  name varchar(30),",
        "  memo varchar(100),",
        "  PRIMARY KEY (id)",
        ")",
      ].join("\n")
    assert $s == ex

  test "test sqlCreateTable 2":
    let
      s = t2.sqlCreateTable
      ex = @[
        "CREATE TABLE IF NOT EXISTS tasks (",
        "  id serial,",
        "  category_id integer,",
        "  name varchar(30),",
        "  description varchar(200),",
        "  PRIMARY KEY (id),",
        "  UNIQUE (name, description),",
        "  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL",
        ")",
      ].join("\n")
    assert $s == ex

  test "test sqlDropTable":
    let
      s = t1.sqlDropTable
      ex = "DROP TABLE IF EXISTS categories"
    assert $s == ex

  test "test sqlSequence":
    var s, ex: string
    s = q.sqlSequence("categories_id_seq")
    ex = "CREATE SEQUENCE categories_id_seq START 1;"
    assert $s == ex

    s = q.sqlSequence("categories_id_seq", 100)
    ex = "CREATE SEQUENCE categories_id_seq START 100;"
    assert $s == ex

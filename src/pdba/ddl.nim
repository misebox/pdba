import pdba/types
import pdba/utils

proc sqlSequence*(q: QDB, name: string, start: int = 1): string =
  fmt"CREATE SEQUENCE {name} START {start};"

proc sqlCreateTable*(t: QTbl): SqlQuery =
  var rows: seq[string] = @[]
  for c in toSeq(t.cols.values):
    let default = if c.default.len > 0: " DEFAULT " & c.default else: ""
    rows.add(fmt"{c.name} {c.dbtype}{default}")
  if t.primary_keys.len > 0:
    rows.add("PRIMARY KEY (" & t.primary_keys.join(", ") & ")")
  if t.unique.len > 0:
    for u in t.unique:
      rows.add("UNIQUE (" & u.join(", ") & ")")
  if t.foreign_keys.len > 0:
    for f in t.foreign_keys:
      rows.add(@[
        "FOREIGN KEY",
        "(" & f.cols.join(", ") & ")",
        "REFERENCES",
        t.db.tbl[f.reftable].table_name,
        "(" & f.refcols.join(", ") & ")",
        "ON DELETE",
        $(f.ondelete),
      ].join(" "))
  @[
    fmt"CREATE TABLE IF NOT EXISTS {t.table_name} (",
    rows.mapIt("  " & it).join(",\n"),
    ")",
  ].join("\n").toSql

proc sqlDropTable*(t: QTbl): SqlQuery =
  fmt"DROP TABLE IF EXISTS {t.table_name}".toSql

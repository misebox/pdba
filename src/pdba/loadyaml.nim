import yaml, streams
import pdba/types
import pdba/utils


proc strKeys(y: YamlNode): seq[string] =
  toSeq(y.fields.keys).filterIt(it.kind == yScalar).mapIt(it.content)

proc loadQColwithYamlNode(c: YamlNode, tbl: QTbl): QCol =
  assert c["name"].kind == yScalar and c["name"].content is string
  assert c["dbtype"].kind == yScalar and c["dbtype"].content is string

  var qc = QCol(
    table_name: tbl.name,
    name: c["name"].content,
    dbtype: c["dbtype"].content,
    default: "",
    nullable: false
  )

  let colKeys = c.strKeys
  if "default" in colKeys:
    assert c["default"].content is string
    qc.default = c["default"].content
  if "nullable" in colKeys:
    # nullable: true --> I think it should be bool, but it's string
    assert c["nullable"].content is string
    qc.nullable = c["nullable"].content == "true"
  qc

proc loadQTblwithYamlNode(t: YamlNode, q: QDB): QTbl =
  assert t["name"].kind == yScalar and t["name"].content is string
  assert t["table_name"].kind == yScalar and t["table_name"].content is string
  assert t["columns"].kind == ySequence

  let tblKeys = t.strKeys
  var qt = QTbl(
    db: q,
    name: t["name"].content,
    table_name: t["table_name"].content,
    cols: initOrderedTable[string, QCol](),
    foreign_keys: @[]
  )
  if "primary_keys" in tblKeys:
    assert t["primary_keys"].kind == ySequence
    qt.primary_keys = t["primary_keys"].toSeq.mapIt it.content
  if "unique" in tblKeys:
    assert t["unique"].kind == ySequence
    for u in t["unique"].toSeq:
      assert u.kind == ySequence
      qt.unique.add(u.toSeq.mapIt it.content)
  for c in t["columns"]:
    var qc = loadQColwithYamlNode(c, qt)
    qt.cols[qc.name] = qc
  if "foreign_keys" in tblKeys:
    assert t["foreign_keys"].kind == ySequence
    for f in t["foreign_keys"].toSeq:
      assert f.kind == yMapping
      let fKeys = f.strKeys
      for k in ["reftable", "ondelete", "cols", "refcols"]:
        assert k in fKeys
      assert f["reftable"].kind == yScalar and f["reftable"].content is string
      assert f["ondelete"].kind == yScalar and f["ondelete"].content is string
      assert f["cols"].kind == ySequence
      assert f["refcols"].kind == ySequence
      var odstr = f["ondelete"].content
      let
        odkSeq = toSeq(QOnDelKind.items).filterIt($it == toUpper(odstr))
        odk = if odkSeq.len > 0: odkSeq[0] else: QOnDelKind.okNoAction
        fk = QForeignKey(
          reftable: f["reftable"].content,
          ondelete: odk,
          cols: f["cols"].toSeq.mapIt(it.content),
          refcols: f["refcols"].toSeq.mapIt(it.content)
        )
      qt.foreign_keys.add(fk)
  qt

proc loadQDBwithYamlNode(q: QDB, root: YamlNode) =
  assert root["tables"].kind == ySequence
  for t in root["tables"]:
    var qt = loadQTblwithYamlNode(t, q)
    q.tbl[qt.name] = qt

proc loadDBYaml*(q: QDB, filename: string) =
  var s = newFileStream(filename, fmRead)
  var y = loadDom(s)
  var root: YamlNode = y.root
  s.close()

  assert root.kind == YamlNodeKind.yMapping
  q.loadQDBwithYamlNode(root)

proc loadDBYaml*(filename: string): QDB =
  var q = QDB()
  q.loadDBYaml(filename)
  q
 

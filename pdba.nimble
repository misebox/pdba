# Package

version       = "0.2.1"
author        = "misebox"
description   = "A postgres DB adapter for nim."
license       = "MIT"
srcDir        = "src"
skipdirs      = @["tests"]

# Dependencies

requires "nim >= 1.1.1"
requires "yaml >= 0.13.1"
requires "ndb >= 0.19.8"

task examples, "compile and run examples":
  exec "cd examples && docker-compose up -d"
  exec "nim c -r examples/sample_conn.nim"
  exec "nim c -r examples/sample_ddl.nim"
  exec "nim c -r examples/sample_dml.nim"
  exec "cd examples && docker-compose down"

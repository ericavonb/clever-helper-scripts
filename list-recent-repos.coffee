moment = require 'moment'
fs = require 'fs'
{exec} = require 'child_process'



ls = (dir, cb) ->
  dir ?= __dirname
  exec "ls -to | head -n 10 | awk '{print $5, $6, $7, $8}'", (err, stdout, stderr) ->
    return cb err if err?



files = fs.readdirSync __dirname

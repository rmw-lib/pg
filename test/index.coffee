#!/usr/bin/env coffee
import pg from '@rmw/pg'
# import {pg as Xxx} from '@rmw/pg'
import test from 'tape-catch'

test 'pg', (t)=>
  t.equal pg(1,2),3
  # t.deepEqual Xxx([1],[2]),[3]
  t.end()

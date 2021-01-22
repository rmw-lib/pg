#!/usr/bin/env coffee

import '@rmw/console/global'

export default (a,b)=>
  a + b

export pg = (a,b)=>
  c = []
  for i, pos in a
    c.push i+b[pos]
  c

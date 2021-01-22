#!/usr/bin/env coffee
import PG from '@rmw/pg'
import pgInit from '@rmw/pg/init'
do =>
  await pgInit(
    PG
    (pg)=>
      console.log "!!! setup"
  )

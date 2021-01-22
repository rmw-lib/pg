import QueryBuilder from 'knex/lib/query/builder'
import Pg from './pg'

_FUNC_LIST = do =>
  r = []
  for k,v of QueryBuilder.prototype
   if typeof(v)=='function'
     r.push k
  return r

_warp = (self, name, func)->
  get : ->
    o = self(name)
    return o[func].bind(o)

_table = (knex, name)->
  table = new Function()
  for func in _FUNC_LIST
    Object.defineProperty(
      table.prototype
      func
      _warp(knex, name, func)
    )
  r = new table()
  return r

init = (proxy)=>
  pg = proxy.$
  for {schema_name} in await pg.exec(
    "select schema_name from information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog')"
  )
    # console.log "schema_name", schema_name
    schema = {}
    table_li = await pg.li1(
      "SELECT table_name as name FROM information_schema.tables WHERE table_schema='#{schema_name}' AND table_type='BASE TABLE'"
      # "SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' UNION ALL SELECT name FROM sqlite_temp_master WHERE type IN ('table','view') ORDER BY 1"
    )
    # 不能创建为name的表名， 会被function的name覆盖
    for name in table_li
      schema[name] = _table(pg, schema_name+"."+name)
    proxy[schema_name] = schema

export default (proxy, setup)=>
  try
    await init(proxy)
  catch err
    if err.code == '3D000'
      console.log err.toString()
      config = proxy.$.client.connectionSettings
      {database} = config
      connection = {
        ...config
        database:"postgres"
      }
      pg = Pg({connection})
      await pg.$exec("create database #{database}")
      setup(
        await init(proxy)
      )
      return
    throw err

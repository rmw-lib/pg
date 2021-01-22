_pg = require('pg')
require('pg-parse-float')(_pg)
_pg.types.setTypeParser(20, parseInt)
_pg.types.setTypeParser(1016, (v)->
    if v=="{}"
        return []
    v = v.replace(/{/g,"[").replace(/}/g,"]")
    return JSON.parse(v)
)
knex_pg = require('./knex')
QueryBuilder = require('knex/lib/query/builder')

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


module.exports = (config)->
  uri = config.uri
  delete config.uri
  pg = knex_pg({
    client: 'pg',
    connection: "postgres://"+uri
    useNullAsDefault: true
    pool: { min: 1, max: 7 }
    acquireConnectionTimeout: 60000
    ...config
    #searchPath: CONFIG.SCHEMA
    # debug:config.debug
    # searchPath: ["app", 'public'],
  })

  proxy = ->
    pg.apply @, arguments
  li = []

  for obj in [pg,pg.context]
    for k,v of obj
      if typeof(v) == 'function'
        proxy["$"+k]=v.bind(obj)

  pre = undefined
  # 这个$函数本身不能是异步的，否则不能实现顺序的require，也就不能用来从数据库读取定义常量到字典被require
  proxy.$ = (func)=>
    proxy.$ = (func)=>
      new Promise(
        (resolve)=>
          await pre
          pre = func()
          resolve(await pre)
      )
    pre = new Promise(
      (resolve)=>
        do =>
          for {schema_name} in await pg.exec("select schema_name from information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog')")
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
          r = await func()
          resolve(r)
    )
  # exports['$transaction']=pg.transaction.bind(pg)
  #
  # console.log li.join ' '
  # console.log pg.transaction, typeof(pg.transaction) == 'function'
  # console.log exports.$transaction, "!!!!"
  return proxy

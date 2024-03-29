import QueryBuilder from 'knex/lib/query/querybuilder'
import Pg from './index'


defineProperty = (pg, schema, n, name)=>
  Object.defineProperty(
    schema
    name
    {
      configurable: false
      get:=>
        pg n
    }
  )

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
      defineProperty pg, schema, schema_name+"."+name, name

    proxy[schema_name] = schema
  return proxy

export default (proxy, setup)=>
  try
    return await init(proxy)
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
      try
        await setup(
          await init(proxy)
        )
      catch err
        console.trace err
        # await pg.$exec("drop database #{database}")
      return
    throw err

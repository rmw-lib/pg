import _pg from 'pg'
import knex_pg from './knex'
import pgParseFloat from 'pg-parse-float'

pgParseFloat _pg

_pg.types.setTypeParser(20, parseInt)
_pg.types.setTypeParser(1016, (v)->
    if v=="{}"
        return []
    v = v.replace(/{/g,"[").replace(/}/g,"]")
    return JSON.parse(v)
)

export default (config)->
  uri = config.uri
  delete config.uri
  pg = knex_pg({
    client: 'pg',
    useNullAsDefault: true
    pool: { min: 1, max: 8 }
    acquireConnectionTimeout: 60000
    ...config
    debug:process.env.NODE_ENV == "development"
    # searchPath: CONFIG.SCHEMA
    # searchPath: ["app", 'public'],
  })
  proxy = ->
    pg.apply @, arguments

  li = []

  # for obj in [pg,pg.context]
  #   for k,v of obj
  #     if typeof(v) == 'function'
  #       proxy["$"+k]=v.bind(obj)

  proxy.$ = pg

  proxy

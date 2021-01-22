import Knex from 'knex'

import knexTinyLogger from './log'

import QueryBuilder from 'knex/lib/query/builder'

_transaction = Knex.Client::transaction
Knex.Client::transaction = (container, config)->
    _transaction.call(
        @
        (trx)->
            Object.assign(trx,extend)
            container.apply @,arguments
        config
    )


Object.assign(
  QueryBuilder.prototype
  {
  dict:->
    li = await @select(
      ["id","val"]
    )
    r = {}
    for {id,val} in li
      r[id]=val
    r

  iter:(option={})->
    {id,limit,select,begin,where} = {
      begin:0
      id : 'id'
      limit : 1000
      select : "*"
      where: {}
      ...option
    }
    while 1
      q = @clone()
      li = await q.select(select).where(where).where(id,">", begin).limit(limit).orderBy(id)
      for i in li
        yield i
      if li.length
        begin = li[li.length-1][id]
      else
        break

  total:(where)->
    if where
        q = @where(where)
    else
        q = @
    return Object.values((await q.count())[0])[0]

  set:(id, val)->
    if val == undefined
      return @where({id}).delete()
    await @upsert({val},{id})

  val:(id)->
      r = await @get({id}, 'val')
      if r
          return r.val

  val_id: (val)->
    return await @upsert(
        {val}
    )

  get: (dict, column)->
    if parseInt(dict)
        dict = {id:dict}
    return (
      (
        await @where(dict).select(column).limit(1)
      )[0]
    )

  upsert: (column_val, where_val)->
    table = @_single.table
    where= []
    column_li = []
    holder = []
    val_li = []

    update_li = []
    update_val_li = []
    for column,val of column_val
      update_li.push("""\"#{column}"=?""")
      update_val_li.push val
    update_li = update_li.join ','

    if where_val
      column_val = Object.assign(column_val, where_val)
    else
      where_val = column_val

    for column,val of where_val
      where.push """#{column}=?"""
      val_li.push val

    for column,val of column_val
      column = '"'+column+'"'
      column_li.push column
      holder.push "?"
      val_li.push val

    key = "(#{column_li.join(',')})"

    sql = """WITH S AS (SELECT id FROM #{table} WHERE #{where.join(' AND ')}),I AS (INSERT INTO #{table} #{key} SELECT #{holder.join(",")} WHERE NOT EXISTS (SELECT 1 FROM S) RETURNING id),U AS (UPDATE #{table} SET #{update_li} WHERE id=(SELECT id FROM S)) SELECT id FROM I UNION ALL SELECT id FROM S"""
    r = await @client.raw(
        sql
        val_li.concat(update_val_li)
    )
    return r.rows[0].id

    # upsert:(dict, conflict)->
    #     table = @_single.table
    #     kli = Object.keys(dict)
    #     vli = Object.values(dict)

    #     ks = kli.join(',')
    #     if conflict
    #         skli = []
    #         svli = []
    #         for i in conflict.split(",")
    #             skli.push i
    #             svli.push dict[i]
    #     else
    #         conflict = ks
    #         skli = kli
    #         svli = vli

    #     if skli.length < kli.length
    #         to_update = []
    #         for i in kli
    #             if not (skli.indexOf(i)+1)
    #                 to_update.push "#{i}=?"
    #                 vli.push dict[i]
    #         DO = "UPDATE SET "+to_update.join(",")
    #     else
    #         DO = "NOTHING"

    #     await @client.raw(
    #         "INSERT INTO #{table} (#{ks}) VALUES (#{Array(kli.length).fill("?").join(',')}) ON CONFLICT(#{conflict}) DO #{DO}"
    #         vli
    #     )

    #     query_li = ["#i=?" for i in skli]
    #     return (await @client.raw(
    #         """SELECT id FROM #{table} WHERE #{query_li.join(' AND ')} LIMIT 1""", svli
    #     )).rows[0].id
  }
)



extend = {
_raw:->
  args = []
  for i in arguments
      args.push i
  sql = args.shift()
  return @raw.call(
      @
      sql
      args
  )

one: ->
  return (await (@exec.apply(@,arguments)))[0]

dict:->
  r = {}
  for [k,v] in await @li.apply @,arguments
    r[k] = v
  r

li1:->
  r = []
  for i in await @li.apply(@,arguments)
    r.push i[0]
  return r

li: ->
  {rows} = await @_raw.apply(@, arguments).options({rowMode:'array'})
  return rows

exec : ->
  {rows} = await @_raw.apply(@, arguments)
  return rows
}


export default ->
  pg = Knex.apply @,arguments
  Object.assign(pg, extend)
  pg.on(
      'query-error'
      (error, obj)->
        console.error obj.sql
        console.error obj.bindings
        console.error error.toString()
  )
  if process.env.NODE_ENV == "development"
    pg = knexTinyLogger pg
  return pg

import _chalk from 'chalk'

PS1 = "🔸 "

COLORIZE =
  primary: _chalk.gray
  error: _chalk.red
  success: _chalk.greenBright

export default (knex) ->
  options = if arguments.length <= 1 or arguments[1] == undefined then {} else arguments[1]
  _options$logger = options.logger

  if _options$logger
    logger = _options$logger
  else
    logger = (cost, sql, colorize)=>
      sql = colorize sql
      cost = COLORIZE.primary(cost/1000+"s")
      process.stdout.write [PS1, sql, cost].join(" ")
      return

  _options$bindings = options.bindings
  withBindings = if _options$bindings == undefined then true else _options$bindings
  queries = new Map
  print = makeQueryPrinter(knex,
    logger: logger
    withBindings: withBindings)

  handleQuery = (_ref) ->
    queryId = _ref.__knexQueryUid
    sql = _ref.sql
    bindings = _ref.bindings
    startTime = measureStartTime()
    queries.set queryId,
      sql: sql
      bindings: bindings
      startTime: startTime
    return

  handleQueryError = (_error, _ref2) ->
    queryId = _ref2.__knexQueryUid
    withQuery queryId, (_ref3) ->
      sql = _ref3.sql
      bindings = _ref3.bindings
      duration = _ref3.duration
      print {
        sql: sql
        bindings: bindings
        duration: duration
      }, COLORIZE.error
      return
    return

  handleQueryResponse = (_response, _ref4) ->
    queryId = _ref4.__knexQueryUid
    withQuery queryId, (_ref5) ->
      sql = _ref5.sql
      bindings = _ref5.bindings
      duration = _ref5.duration
      print {
        sql: sql
        bindings: bindings
        duration: duration
      }, COLORIZE.success
      return
    return

  withQuery = (queryId, fn) ->
    query = queries.get(queryId)
    queries.delete queryId
    if !query
      throw new TypeError('Query disappeared')
    sql = query.sql
    bindings = query.bindings
    startTime = query.startTime
    duration = measureDuration(startTime)
    fn
      sql: sql
      bindings: bindings
      duration: duration
    return

  knex.on('query', handleQuery).on('query-error', handleQueryError).on 'query-response', handleQueryResponse

makeQueryPrinter = (knex, _ref6) ->
  logger = _ref6.logger
  withBindings = _ref6.withBindings
  (_ref7, colorize) ->
    sql = _ref7.sql
    bindings = _ref7.bindings
    duration = _ref7.duration
    sqlRequest = knex.client._formatQuery(sql, if withBindings then bindings else null)
    logger duration, sqlRequest, colorize
    return

measureStartTime = ->
  process.hrtime()

measureDuration = (startTime) ->
  diff = process.hrtime(startTime)
  duration = diff[0] * 1e3 + diff[1] * 1e-6
  duration


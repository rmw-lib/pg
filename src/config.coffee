import CONFIG from "@rmw/config"

export default config = {}

do =>
  Object.assign(
    config , CONFIG.pg or {}
  )
  connection = config.connection = config.connection or {}

  for k,v of {
    host : "127.0.0.1"
    port : 14102
    database : "rmw"
  }
    if k not of connection
      connection[k] = v

  return


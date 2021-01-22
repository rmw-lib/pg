import CONFIG from "@rmw/config"
import {randomBytes} from 'crypto'

export default config = {}

do =>
  Object.assign(
    config , CONFIG.pg or {}
  )
  connection = config.connection = config.connection or {}

  if not config.password
    config.password = randomBytes(16).toString('base64')
    CONFIG.pg = {...config}

  rmw = "rmw"
  for k,v of {
    host : "127.0.0.1"
    port : 49102
    database : rmw
    user: rmw
  }
    if k not of connection
      connection[k] = v

  return


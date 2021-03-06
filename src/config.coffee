import CONFIG from "@rmw/config"
import {randomBytes} from 'crypto'
import BASE64 from 'urlsafe-base64'
export default config = {}

do =>
  Object.assign(
    config , CONFIG.pg or {}
  )
  connection = config.connection = config.connection or {}

  if not connection.password
    config.connection.password = BASE64.encode randomBytes(
      16
    )
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


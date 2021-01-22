import CONFIG from "@rmw/config"

export default config = {}

do =>
  Object.assign(
    config , CONFIG.pg or {}
  )

  for k,v of {
    host : "127.0.0.1"
    port : 14102
  }
    if k not of config
      config[k] = v

  return


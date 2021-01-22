import config from './config'
import Pg from './pg'
# PG = {
#   USER : "xvc"
#   # HOST : "pgm-m5ew8ommau8sjkb814830.pg.rds.aliyuncs.com" # 内网
#   # PORT : 3433
#   HOST: "pgm-m5ew8ommau8sjkb8no.pg.rds.aliyuncs.com" # 外网
#   PORT : 3432
#   PASSWORD : "Jsq7umPM"
#   DB : "xvc"
# }

uri = undefined

do =>
  {user,password,host,port,db} = config
  li = [user]
  if password
    li.push ":"+password
  li.push "@#{host}:#{port}/#{db}"
  uri = li.join('')

export default Pg {
  uri
}

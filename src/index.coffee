#!/usr/bin/env coffee

import config from './config'
import Pg from './pg'

export default Pg {
  uri: do =>
    {user,password,host,port,db} = config
    li = [user]
    if password
      li.push ":"+password
    li.push "@#{host}:#{port}/#{db}"
    li.join('')
}

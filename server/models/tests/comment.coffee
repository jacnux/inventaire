CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
{ pass, userId, itemId, transactionId } = require './common-tests'

module.exports =
  pass: pass
  userId: userId
  itemId: itemId
  transactionId: transactionId
  message: (message)->
    return 0 < message.length < 5000

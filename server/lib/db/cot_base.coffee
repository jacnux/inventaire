CONFIG = require 'config'
cot = require 'cot'

params =
  hostname: CONFIG.db.host
  port: CONFIG.db.port

module.exports.users = new cot(params).db(CONFIG.db.users)

module.exports.inventory = new cot(params).db(CONFIG.db.inventory)
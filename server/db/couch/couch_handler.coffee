CONFIG = require('config')
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
host = CONFIG.db.fullHost()
nano = require('nano') host
dbInit = __.require 'couch', 'couch_init'
Radio = __.require 'lib', 'radio'
dbsList = require('inv-dbs-list').default

module.exports =
  checkDbsExistanceOrCreate: ->
    for dbBaseName, designDocsNames of dbsList
      assertValidDbName(dbBaseName)
      checkExistanceOrCreate(dbBaseName)

  reloadDesignDocs: ->
    for dbBaseName, designDocsNames of dbsList
      for designDocName in designDocsNames
        dbInit.designDoc.update dbBaseName, designDocName

checkExistanceOrCreate = (dbBaseName)->
  dbName = CONFIG.db.name(dbBaseName)
  nano.db.get dbName, (err, body)->
    unless err?
      _.info "#{dbBaseName}DB ready!"
    else
      _.info "#{dbName} not found: creating"
      createDb(dbBaseName)
    Radio.emit 'db:ready'

createDb = (dbBaseName)->
  dbName = CONFIG.db.name(dbBaseName)
  nano.db.create dbName, (err, body)->
    if err then _.error err, "couldn't create #{dbName} CouchDB at #{host}"
    else
      _.success body, "#{dbName} CouchDB created"
      loadConfigurationDocs(dbBaseName)

assertValidDbName = (str)->
  unless _.isString(str) and /^[a-z_$()+-\/]+$/.test str
    throw new Error "invalid db name: #{str}.
    only lowercase strings are accepted in an array of DBs"

loadConfigurationDocs = (dbBaseName)->
  designDocsNames = dbsList[dbBaseName]
  for designDocName in designDocsNames
    dbInit.designDoc.load dbBaseName, designDocName

  if CONFIG.db.restricted
    dbName = CONFIG.db.name(dbBaseName)
    dbInit.putSecurityDoc dbName

  if dbBaseName is 'users' and CONFIG.db.fakeUsers
    dbInit.loadFakeUsers()
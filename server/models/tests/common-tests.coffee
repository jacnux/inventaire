CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
regex_ = require './regex'
error_ = __.require 'lib', 'error/error'

{ CouchUuid, Email, Username, EntityUri, Lang, LocalImg } = regex_

# regex need to their context
bindedTest = (regex)-> regex.test.bind regex

module.exports = tests =
  userId: bindedTest CouchUuid
  itemId: bindedTest CouchUuid
  transactionId: bindedTest CouchUuid
  groupId: bindedTest CouchUuid
  username: bindedTest Username
  email: bindedTest Email
  entityUri: bindedTest EntityUri
  lang: bindedTest Lang
  localImg: bindedTest LocalImg
  boolean: _.isBoolean
  position: (latLng)->
    # allow the user or group to delete its position by passing a null value
    if latLng is null then return true
    _.isArray(latLng) and latLng.length is 2 and _.all latLng, _.isNumber

tests.nonEmptyString = (str, maxLength=100)->
  _.isString str
  return 0 < str.length <= maxLength

# no item of this app could have a timestamp before june 2014
June2014 = 1402351200000
tests.EpochMs =
  test: (time)-> June2014 < time <= _.now()

tests.imgUrl = (url)-> tests.localImg(url) or _.isUrl(url)

tests.valid = (attribute, value, option)->
  test = @[attribute]
  # if no test are set at this attribute for this context
  # default to common tests
  test ?= tests[attribute]
  test value, option

tests.pass = (attribute, value, option)->
  unless tests.valid.call @, attribute, value, option
    throw error_.new "invalid #{attribute}: #{value}", 400

tests.type = (attribute, typeArgs...)->
  try _.type.apply _, typeArgs
  catch err
    throw error_.complete err, "invalid #{attribute}", 400, typeArgs

tests.types = (attribute, typesArgs...)->
  try _.types.apply _, typesArgs
  catch err
    throw error_.complete err, "invalid #{attribute}", 400, typesArgs

__ = require('config').universalPath
_ = __.require 'builders', 'utils'
cache_ = __.require 'lib', 'cache'
error_ = __.require 'lib', 'error/error'
promises_ = __.require 'lib', 'promises'
xml_ = __.require 'lib', 'xml'
qs = require 'querystring'

module.exports = (req, res)->
  { file, width } = req.query

  unless file? then return error_.bundle res, 'missing file parameter', 400

  timespan = cache_.solveExpirationTime 'commons'

  key = "commons:#{file}:#{width}"
  cache_.get key, requestThumb.bind(null, file, width), timespan
  .then res.json.bind(res)
  .catch error_.Handler(res)

requestThumb = (fileName, width)->
  options = requestOptions fileName, width

  promises_.get options
  .then xml_.parse
  .then (res)->
    { file, licenses, error } = res.response
    return data =
      thumbnail: file?[0]?.urls?[0]?.thumbnail?[0]
      license: licenses?[0]?.license?[0]?.name?.toString()
      author: file?[0]?.author?.toString()
      error: error?[0]
  .then parseData.bind(null, fileName, options.url)
  .error _.Error("requestThumb: #{options.url}")

requestOptions = (file, width)->
  file = qs.escape file
  url: "http://tools.wmflabs.org/magnus-toolserver/commonsapi.php?image=#{file}&thumbwidth=#{width}"
  headers:
    'Content-Type': 'application/xml'
    # the commonsapi requires a User-Agent
    'User-Agent': 'Inventaire server'

parseData = (file, url, data)->
  { thumbnail, error, author } = data
  data.author = removeMarkups author

  unless thumbnail?
    err = new Error error
    if error.match('File does not exist') then err.status = 404
    throw err

  return data


textInMarkups = /<.+>(.*)<\/\w+>/
removeMarkups = (text)->
  unless text? then return
  # avoiding very long credits
  # including whole html documents
  # cf: http://tools.wmflabs.org/magnus-toolserver/commonsapi.php?image=F%C3%A9lix_Nadar_1820-1910_portraits_Jules_Verne.jpg&thumbwidth=1000
  if text.length > 100
    _.warn 'discarding photo author credits: too long'
    return

  text = text.replace textInMarkups, '$1'
  if text is '' then return
  else return text


validWmCommonsThumbnail = (file, url, thumbnail)->
  fileParts = extractWords file
  thumbnailParts = extractWords unescape(lastPart(thumbnail))
  ratio = _.matchesCount(fileParts, thumbnailParts) / fileParts.length
  valid = ratio > 0.5
  unless valid
    _.log arguments, 'not validWmCommonsThumbnail'
    _.log [fileParts, thumbnailParts], 'parts'
    _.log ratio, 'certitude ratio'
  return valid

lastPart = (url)-> url.split('/').slice(-1)[0]
extractWords = (str)-> str.split /\W|_/

__ = require('config').root
_ = __.require 'builders', 'utils'
cache_ = __.require 'lib', 'cache'
error_ = __.require 'lib', 'error/error'
promises_ = __.require 'lib', 'promises'
wd_ = __.require 'lib', 'wikidata'

module.exports = (req, res)->
  { query, pid, qid } = req.query
  try _.types [query, pid, qid], 'strings...'
  catch err
    return error_.bundle res, 'bad parameters', 400, err

  key = "wdq:#{query}:#{pid}:#{qid}"
  cache_.get key, requestWdq.bind(null, query, pid, qid)
  .then res.json.bind(res)
  .catch error_.Handler(res)

requestWdq = (query, P, Q)->
  switch query
    when 'claim' then return claim(P,Q)
    else throw error_.new "#{query} requestWdq isnt implemented", 400, arguments

claim = (P, Q)->
  url = wd_.API.wmflabs.claim(P, Q)
  promises_.get url
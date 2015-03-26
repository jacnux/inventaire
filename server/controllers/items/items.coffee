__ = require('config').root
_ = __.require 'builders', 'utils'
items_ = __.require 'lib', 'items'
user_ = __.require 'lib', 'user/user'
couch_ = __.require 'lib', 'couch'
error_ = __.require 'lib', 'error/error'
Item = __.require 'models', 'item'
Promise = require 'bluebird'

publicActions = require './public_actions'

module.exports = _.extend publicActions,
  fetch: (req, res, next) ->
    # only fetch for session email
    # = only way to fetch private data on items
    user_.getUserId(req)
    .then items_.byOwner.bind(items_)
    .then res.json.bind(res)
    .catch error_.Handler(res)

  put: (req, res, next) ->
    _.log req.params.id, 'Put Item ID'
    user_.getUserId(req)
    .then (userId)->
      item = req.body
      if item._id is 'new' then Item.create(userId, item)
      else Item.update(userId, item)
    .then couch_.getObjIfSuccess.bind(null, items_.db)
    .then (body)-> res.status(201).json body
    .catch error_.Handler(res)

  del: (req, res, next) ->
    _.info req.params, 'del'
    {id, rev} = req.params
    getUserIdAndItem(req, id)
    .spread (userId, item)->
      unless userId is item?.owner
        throw error_.new 'user isnt item.owner', 403, userId, item.owner
      _.log id, 'deleting!'
      items_.db.delete(id, rev)
      .then res.json.bind(res)
    .catch error_.Handler(res)

  publicActions: (req, res, next)->
    {action} = req.query
    switch action
      when 'public-by-entity'
        publicActions.publicByEntity(req, res, next)
      when 'public-by-username-and-entity'
        publicActions.publicByUsernameAndEntity(req, res, next)
      when 'last-public-items'
        publicActions.lastPublicItems(req, res, next)
      when 'user-public-items'
        publicActions.userPublicItems(req, res, next)
      else error_.bundle res, 'unknown items public action', 400


getUserIdAndItem = (req, itemId)->
  return Promise.all [
    user_.getUserId(req)
    items_.db.get(itemId)
  ]

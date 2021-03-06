__ = require('config').universalPath
_ = __.require 'builders', 'utils'
user_ = __.require 'lib', 'user/user'
items_ = __.require 'controllers', 'items/lib/items'
comments_ = __.require 'controllers', 'comments/lib/comments'
error_ = __.require 'lib', 'error/error'

publik =
  get: (req, res, next)->
    { item } = req.query
    userId = req.user?._id

    items_.byId item
    .then comments_.verifyRightToWriteOrReadComment.bind(null, userId)
    .then comments_.byItemId.bind(null, item)
    .then res.json.bind(res)
    .catch error_.Handler(res)

privat =
  create: (req, res, next)->
    { item, message } = req.body
    userId = req.user._id

    unless item? then return error_.bundle res, 'missing item id', 400
    unless message? then return error_.bundle res, 'missing message', 400


    _.log [item, message], 'item, message'

    items_.byId item
    .then _.partial(comments_.verifyRightToWriteOrReadComment, userId)
    .then _.partial(comments_.addItemComment, userId, message)
    .then res.json.bind(res)
    .catch error_.Handler(res)

  update: (req, res, next)->
    { id, message } = req.body
    userId = req.user._id

    unless id? then return error_.bundle res, 'missing comment id', 400
    unless message? then return error_.bundle res, 'missing message id', 400


    _.log [id, message], 'comment id, message'

    comments_.byId id
    .then _.partial(comments_.verifyEditRight, userId)
    .then _.partial(comments_.update, message)
    .then res.json.bind(res)
    .catch error_.Handler(res)

  delete: (req, res, next)->
    { id } = req.query
    userId = req.user._id

    comments_.byId id
    .then (comment)->
      items_.byId(comment.item)
      .then _.partial(comments_.verifyDeleteRight, userId, comment)
    .then comments_.delete
    .then _.Ok(res)
    .catch error_.Handler(res)

module.exports =
  public: publik
  private: privat

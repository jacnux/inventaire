__ = require('config').root
_ = __.require 'builders', 'utils'
Radio = __.require 'lib', 'radio'

db = __.require('couch', 'base')('notifications')

notifs_ =
  getUserNotifications: (userId)->
    _.type userId, 'string'
    db.viewCustom 'byUserAndTime',
      startkey: [userId, 0]
      endkey: [userId, {}]
      include_docs: true
    .catch _.Error('getUserNotifications')

  add: (userId, type, data)->
    _.types arguments, ['string', 'string', 'object']
    db.post
      user: userId
      type: type
      data: data
      status: 'unread'
      time: Date.now()

  updateReadStatus: (userId, time)->
    time = Number(time)
    db.viewFindOneByKey 'byUserAndTime', [userId, time]
    .then (doc)->
      db.update doc._id, (doc)->
        doc.status = 'read'
        return doc

callbacks =
  acceptedRequest: (userToNotify, newFriend)->
    _.types arguments, ['string', 'string']
    data = {user: newFriend}
    notifs_.add userToNotify, 'friendAcceptedRequest', data

Radio.on 'notify:friend:request:accepted', callbacks.acceptedRequest


module.exports = notifs_
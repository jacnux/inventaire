books = require '../helpers/books'
wikidata = require '../helpers/wikidata'
Q = require 'q'

module.exports =
  search: (req, res, next) ->
    _.logBlue req.query, "Entities:Search"

    if req.query.search? and req.query.language?

      if books.isIsbn(req.query.search)
        _.logYellow req.query.search, 'searchByIsbn'
        searchByIsbn(req.query, res)

      else
        _.logYellow req.query.search, 'searchByText'
        searchByText(req.query, res)

    else  _.errorHandler res, 'empty query or no language specified', 400


searchByIsbn = (query, res)->
  isbn = query.search
  isbnType = books.isIsbn(isbn)

  promises = [
    wikidata.getBookEntityByISBN(isbn, isbnType, query.language)
    .fail (err)-> _.logRed err, 'wikidata getBookEntityByISBN err'

    booksPromise = books.getGoogleBooksDataFromISBN(isbn)
    .then((res)-> {items:[res], source: 'google'})
    .fail (err)-> _.logRed err, 'getGoogleBooksDataFromISBN err'
  ]

  spreadRequests(res, promises, 'searchByIsbn')

searchByText = (query, res)->

  promises = [
    wikidata.getBookEntities(query)
    .then (filteredAndBrushed)-> {items: filteredAndBrushed, source: 'wd'}
    .fail (err)-> _.logRed err, 'wikidata getBookEntities err'

    books.getGoogleBooksDataFromText(query.search)
    .then (res)-> {items: res, source: 'google'}
    .fail (err)-> _.logRed err, 'getGoogleBooksDataFromISBN err'
  ]

  spreadRequests(res, promises, 'searchByText')


spreadRequests = (res, promises, label)->

  Q.spread promises, (results...)->
    _.logBlue results, "api results for #{label}"
    selected = null
    results.forEach (result)->
      if result.items?.length > 0 and not selected?
        selected = result
    selected.source.logIt('selected source')
    return selected

  .then (selected)->
    if selected?
      _.sendJSON res, selected
    else
      _.sendJSON res, { status: 'not found', details: results}, 404

  .fail (err)->
    _.logRed err, "#{label} err"
    _.errorHandler res, err
  .done()
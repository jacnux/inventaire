module.exports =
  env: 'default'
  protocol: 'http'
  name: "inventaire"
  host: 'localhost'
  hostAlt: '0.0.0.0' #problem with Persona Audience for local ip anyway
  hostTer: '192.168.1.49' #problem with Persona Audience for local ip anyway
  port: 3008
  fullHost: -> "#{@protocol}://#{@host}:#{@port}"
  fullHostTer: -> "#{@protocol}://#{@hostTer}:#{@port}"
  secret: "yoursecrethere"
  db:
    protocol: 'http'
    host: 'localhost'
    port: 5984
    fullHost: -> "#{@protocol}://#{@host}:#{@port}"
    users: 'users'
    inv: 'inventory'
  whitelistedRouteRegExp: /^\/api\/auth\//
  noCache: true
  staticMaxAge: 0
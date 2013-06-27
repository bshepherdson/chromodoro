'use strict'

angular.module('chromodoroApp', [])
  .config ['$routeProvider', ($routeProvider) ->
    # Chrome shims
    if not window.chrome.storage?
      changeHandlers = []

      set = (base, key, value, cb) ->
        localStorage[base + '___' + key] = JSON.stringify(value)
        window.setTimeout((() ->
          o = {}
          o[key] = value
          for h in changeHandlers
            h(o, base)
          cb()
        ), 0)

      get = (base, key, cb) ->
        window.setTimeout () ->
          v = localStorage[base + '___' + key]
          if v?
            cb(JSON.parse(v))
          else cb()
        , 0

      window.chrome.storage =
        local:
          get: (key, cb) -> get('local', key, cb)
          set: (key, value, cb) -> set('local', key, value, cb)
        sync:
          get: (key, cb) -> get('sync', key, cb)
          set: (key, value, cb) -> set('sync', key, value, cb)

        onChanged:
          addListener: (cb) ->
            changeHandlers.push(cb)

    if not window.chrome.runtime?
      window.chrome.runtime =
        lastError: undefined

    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .otherwise
        redirectTo: '/'
  ]

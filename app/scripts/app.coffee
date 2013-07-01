'use strict'

angular.module('chromodoroApp', [])
  .config ['$routeProvider', ($routeProvider) ->
    # Chrome shims
    if not window.chrome.storage?
      changeHandlers = []

      set = (base, changes, cb) ->
        for key, value of changes
          localStorage[base + '___' + key] = JSON.stringify(value)

        window.setTimeout((() ->
          for h in changeHandlers
            h(changes, base)
          cb()
        ), 0)

      get = (base, keys, cb) ->
        window.setTimeout () ->
          obj = keys
          if keys instanceof Array
            obj = {}
            for key in keys
              obj[key] = null
          if typeof keys is 'string'
            obj = {}
            obj[keys] = null

          for key, def of obj
            v = localStorage[base + '___' + key]
            if v?
              obj[key] = JSON.parse(v)

          cb(obj)
        , 0

      window.chrome.storage =
        local:
          get: (key, cb) -> get('local', key, cb)
          set: (changes, cb) -> set('local', changes, cb)
        sync:
          get: (key, cb) -> get('sync', key, cb)
          set: (changes, cb) -> set('sync', changes, cb)

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

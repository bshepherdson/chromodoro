'use strict';

angular.module('chromodoroApp')
  .factory 'config', [($q) ->
    config = {}
    lastUpdatedTime = 0

    chrome.storage.sync.get 'config', (value) -> config = value

    # Set up a listener for changes to sync and update the config cache.
    chrome.storage.onChanged.addListener (changes, area) ->
      if area is 'storage' and changes.config?
        config = changes.config
        lastUpdatedTime = Date.now()


    {
      get: (key) ->
        return config.key
      set: (key, value) ->
        config.key = value
        chrome.storage.sync.set 'config', config

    }
  ]

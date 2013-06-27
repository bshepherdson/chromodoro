'use strict';

angular.module('chromodoroApp')
  .filter 'subtaskSort', () ->
    (input) ->
      return input unless input?
      # Split into completed and not.
      completed = []
      open = []
      for t in input
        if t.completed
          completed.push t
        else
          open.push t

      # Sort each into most-recently-touched-first order.
      order = (a, b) -> if a.lastUpdatedTime >= b.lastUpdatedTime then 1 else -1
      completed.sort(order)
      open.sort(order)

      return open.concat(completed)


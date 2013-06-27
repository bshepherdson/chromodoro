'use strict'

angular.module('chromodoroApp')
  .controller 'MainCtrl', ['$scope', 'config', 'storage', ($scope, config, storage) ->
    # Fetch the root node first.
    storage.fetch 'tasks', (value) ->
      if not value?
        # Prepare the default value:
        value =
          name: 'Work'
          estimated: 0
          elapsed: 0
          children: []

      $scope.rootTask = value
      $scope.task = value
      $scope.hierarchy = [value]

    # Recursive helper function for finding the totals of children.
    totals = (task) ->
      estimated = task.estimated
      elapsed = task.elapsed
      if task.children?
        for c in task.children
          t = totals(c)
          estimated += t.estimated
          elapsed += t.elapsed
      return { estimated: estimated, elapsed: elapsed }

    $scope.showTotals = (task) ->
      totals = totals(task)
      return totals.elapsed + ' / ' + totals.estimated

    $scope.showMine = (task) ->
      return task.elapsed + ' / ' + task.estimated

    # Move up the hierarchy
    $scope.up = (index) ->
      return if index == $scope.hierarchy.length-1 # Do nothing if he clicked the bottommost.

      $scope.task = $scope.hierarchy[index]
      $scope.hierarchy = $scope.hierarchy.splice(index+1, 1000) # Remove all later elements

    $scope.showChild = (index) ->
      $scope.task = $scope.task.children[index]
      $scope.hierarchy.push $scope.task
  ]

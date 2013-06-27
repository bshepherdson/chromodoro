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
          lastUpdatedTime: 0

      $scope.rootTask = value
      $scope.task = value
      $scope.hierarchy = [value]
      $scope.$apply()

    timer = undefined

    # Recursive helper function for finding the totals of children.
    totals = (task) ->
      return unless task?
      estimated = +task.estimated
      elapsed = +task.elapsed
      if task.children?
        for c in task.children
          t = totals(c)
          estimated += +t.estimated
          elapsed += +t.elapsed
      return { estimated: estimated, elapsed: elapsed }

    $scope.showTotals = (task) ->
      return unless task?
      result = totals(task)
      return result.elapsed + ' / ' + result.estimated

    $scope.showMine = (task) ->
      return unless task?
      return task.elapsed + ' / ' + task.estimated

    # Move up the hierarchy
    $scope.up = (index) ->
      return if index == $scope.hierarchy.length-1 # Do nothing if he clicked the bottommost.

      $scope.task = $scope.hierarchy[index]
      $scope.hierarchy.splice(index+1, 1000) # Remove all later elements

    $scope.showChild = (index) ->
      $scope.task = $scope.task.children[index]
      $scope.hierarchy.push $scope.task

    # Performs a pomodoro on this task.
    $scope.doPomodoro = () ->
      if $scope.pomodoro?.active
        alert('Another Pomodoro is already active')
      else
        $scope.task.lastUpdatedTime = Date.now()
        timer = window.setInterval () ->
          updateDelta()
          $scope.$apply()
        , 10000
        $scope.pomodoro =
          task: $scope.task
          type: 'task'
          start: Date.now()
          end: Date.now() + 25*60*1000
          delta: 25
          active: true

    $scope.newChild = () ->
      $scope.showCreate = true
      $scope.editing = false
      $scope.commitLabel = 'Create'
      $scope.editTask =
        name: undefined
        estimated: 1
        elapsed: 0
        children: []

    $scope.edit = () ->
      $scope.showCreate = true
      $scope.editing = true
      $scope.commitLabel = 'Edit'
      $scope.editTask = $scope.task

    $scope.delete = () ->
      if window.confirm('This will permanently delete this task and all subtasks. It will be removed from the stats. You probably want to mark it complete instead.')
        if $scope.hierarchy.length == 1
          alert('Cannot delete root node')
        else
          parent = $scope.hierarchy[$scope.hierarchy.length - 2]
          for c, i in parent.children
            if c is $scope.task
              parent.children.splice(i, 1)
              save()

    # Saves the editing or newly created button
    $scope.commit = () ->
      $scope.editTask.lastUpdatedTime = Date.now()
      t = $scope.editTask
      if t.name? and t.estimated? and t.elapsed?
        # If editing, it's already done being updated.
        if not $scope.editing
          # If newly created, it needs to be added to the parent.
          $scope.task.children.push $scope.editTask

        $scope.showCreate = false
        save()

    updateDelta = () ->
      if $scope.pomodoro? and $scope.pomodoro.active
        $scope.pomodoro.delta = Math.ceil(($scope.pomodoro.end - Date.now()) / 60000)
        if $scope.pomodoro.delta <= 0
          if $scope.pomodoro.type is 'task'
            $scope.pomodoro =
              type: 'break'
              delta: 5
              start: Date.now()
              end: Date.now() + 5 * 60 * 1000
          else
            $scope.pomodoro.active = false

    save = () ->
      storage.store('tasks', $scope.rootTask)

  ]

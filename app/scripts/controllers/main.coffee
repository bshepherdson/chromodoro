'use strict'

angular.module('chromodoroApp')
  .controller 'MainCtrl', ($scope, config, storage) ->
    # Fetch the root node first.
    storage.fetch ['tasks', 'pomodoro'], (value) ->
      root = value?.tasks
      if not root?
        # Prepare the default value:
        root =
          id: 'WORK'
          name: 'Work'
          estimated: 0
          elapsed: 0
          children: []
          lastUpdatedTime: 0

      $scope.rootTask = root
      $scope.task = root
      $scope.hierarchy = [root]
      $scope.$apply()

      if value?.pomodoro?
        task = findTask(value.pomodoro.task, root)
        if task?
          $scope.pomodoro =
            active: true
            type: 'task'
            task: task
            delta: value.pomodoro.delta
            start: Date.now()
            end: Date.now() + value.pomodoro.delta * 60 * 1000
          $scope.$apply()
          startTimer()

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
        startTimer()
        $scope.pomodoro =
          task: $scope.task
          type: 'task'
          start: Date.now()
          end: Date.now() + 25*60*1000
          delta: 25
          active: true
        save()

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
              break

          # If the deleted task is in the ancestor chain of the active pomodoro, the pomodoro task will be gone.
          # Detect that by failing to find it in the modified tree, and delete the active pomodoro if it's gone.
          if $scope.pomodoro? and $scope.pomodoro.active and not findPath($scope.pomodoro.task.id, $scope.rootTask)?
            $scope.pomodoro = undefined

          save()
          $scope.up($scope.hierarchy.length - 2);

    # Saves the editing or newly created button
    $scope.commit = () ->
      $scope.editTask.lastUpdatedTime = Date.now()
      t = $scope.editTask
      if t.name? and t.estimated? and t.elapsed?
        # If editing, it's already done being updated.
        if not $scope.editing
          # If newly created, it needs to be added to the parent and to have an ID made.
          $scope.task.children.push $scope.editTask
          makeId($scope.editTask)

        $scope.showCreate = false
        save()

    updateDelta = () ->
      if $scope.pomodoro? and $scope.pomodoro.active
        $scope.pomodoro.delta = Math.ceil(($scope.pomodoro.end - Date.now()) / 60000)
        if $scope.pomodoro.delta <= 0
          if $scope.pomodoro.type is 'task'
            $scope.pomodoro.task.elapsed += 1
            $scope.pomodoro.task.lastUpdatedTime = Date.now()
            $scope.pomodoro =
              task: $scope.pomodoro.task
              active: true
              type: 'break'
              delta: 5
              start: Date.now()
              end: Date.now() + 5 * 60 * 1000
          else
            $scope.pomodoro.active = false
        save()

    save = () ->
      obj =
        tasks: $scope.rootTask

      if $scope.pomodoro and $scope.pomodoro.task and $scope.pomodoro.active
        obj.pomodoro =
          task: $scope.pomodoro.task.id
          delta: $scope.pomodoro.delta

      storage.store(obj)

    startTimer = () ->
      if not timer?
        timer = window.setInterval () ->
          updateDelta()
          $scope.$apply()
        , 10000

    # Takes an almost-completed task and creates a (hopefully) unique ID for it.
    makeId = (task) ->
      id = Date.now() + '-'
      for i in [1..10]
        x = (i * 30) % task.name.length
        id += task.name.charAt(x)
      task.id = id

    # Preorder traverses the task tree, looking for the given ID.
    findTask = (id, task) ->
      arr = findPath(id, task)
      if arr? and arr.length > 0
        return arr[0]


    # Preorder traversal of the task tree, looking for the ID.
    # Returns an array of ancestors, with the target at [0] and the root at [n-1].
    findPath = (id, task) ->
      if not task?
        task = $scope.rootTask

      if task.id == id
        return [task]

      if task.children?.length
        for c in task.children
          res = findPath(id, c)
          if res?
            res.push(task)
            return res


'use strict'

describe 'Filter: subtaskSort', () ->

  # load the filter's module
  beforeEach module 'chromodoroApp'

  # initialize a new instance of the filter before each test
  subtaskSort = {}
  beforeEach inject ($filter) ->
    subtaskSort = $filter 'subtaskSort'

  it 'should return the input prefixed with "subtaskSort filter:"', () ->
    text = 'angularjs'
    expect(subtaskSort text).toBe ('subtaskSort filter: ' + text);

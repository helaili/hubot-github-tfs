chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

Helper = require('hubot-test-helper')
helper = new Helper('./../src/github-tfs.coffee')

expect = chai.expect
assert = chai.assert


describe 'github-tfs', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

  

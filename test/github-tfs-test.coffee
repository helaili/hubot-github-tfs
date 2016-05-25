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

    require('../src/github-tfs')(@robot)

  it 'registers a respond listener', ->
    expect(@robot.respond).to.have.been.calledWith(/tfs-build/)

  it 'registers a hear listener', ->
    expect(@robot.hear).to.have.been.calledWith(/orly/)

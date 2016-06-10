Helper = require 'hubot-test-helper'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
expect = require('chai').expect
nock = require 'nock'



helper = new Helper('./../src/github-tfs.coffee')


describe 'github-tfs', ->
  room = null

  tfsServer = process.env.HUBOT_TFS_SERVER

  beforeEach ->
    room = helper.createRoom()
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
    do nock.disableNetConnect
    nock('http://' + tfsServer)
      .get('/tfs/defaultcollection/SpidersFromMars/_apis/build/builds')
      .replyWithFile(200, __dirname + '/replies/listBuilds.json');

    nock('http://' + tfsServer)
      .get('/tfs/defaultcollection/SpidersFromMars/_apis/build/definitions')
      .replyWithFile(200, __dirname + '/replies/listDefinitions.json');

  afterEach ->
    nock.cleanAll()
    room.destroy()

  context 'user asks hubot for a list of builds', ->
    beforeEach (done) ->
      room.user.say 'alain', 'hubot tfs-build list builds for SpidersFromMars'
      setTimeout done, 100

    it 'should respond with an array of builds', ->
      expect(room.messages).to.eql [
        [ 'alain', 'hubot tfs-build list builds for SpidersFromMars' ]
        [ 'hubot', '@alain I found 2 results for SpidersFromMars' ]
        [ 'hubot', '@alain \n----------------------------------------------------------------------------------------\n| Build       | Status   | Result  | Branch             | Definition                   | \n----------------------------------------------------------------------------------------\n|20160608.1   |completed |succeeded|master              |SpidersFromMars on Octodemo   |\n|20160531.31  |completed |succeeded|refs/heads/testTFS  |SpidersFromMars on Octodemo   |\n----------------------------------------------------------------------------------------' ]
      ]

  context 'user asks hubot for a list of builds with a collection', ->
    beforeEach (done) ->
      room.user.say 'alain', 'hubot tfs-build list builds for SpidersFromMars from defaultcollection'
      setTimeout done, 100

    it 'should respond with an array of builds', ->
      expect(room.messages).to.eql [
        [ 'alain', 'hubot tfs-build list builds for SpidersFromMars from defaultcollection' ]
        [ 'hubot', '@alain I found 2 results for SpidersFromMars in defaultcollection' ]
        [ 'hubot', '@alain \n----------------------------------------------------------------------------------------\n| Build       | Status   | Result  | Branch             | Definition                   | \n----------------------------------------------------------------------------------------\n|20160608.1   |completed |succeeded|master              |SpidersFromMars on Octodemo   |\n|20160531.31  |completed |succeeded|refs/heads/testTFS  |SpidersFromMars on Octodemo   |\n----------------------------------------------------------------------------------------' ]
      ]

  context 'user asks hubot for a list of definitions', ->
    beforeEach (done) ->
      room.user.say 'alain', 'hubot tfs-build list definitions for SpidersFromMars'
      setTimeout done, 100

    it 'should respond with an array of builds', ->
      expect(room.messages).to.eql [
        [ 'alain', 'hubot tfs-build list definitions for SpidersFromMars' ]
        [ 'hubot', '@alain I found 1 results for SpidersFromMars' ]
        [ 'hubot', '@alain \n--------------------------------------\n| ID  | Name                         | \n--------------------------------------\n|1    |SpidersFromMars on Octodemo   |\n--------------------------------------' ]
      ]

  context 'user asks hubot for a list of definitions with a collection', ->
    beforeEach (done) ->
      room.user.say 'alain', 'hubot tfs-build list definitions for SpidersFromMars from defaultcollection'
      setTimeout done, 100

    it 'should respond with an array of builds', ->
      expect(room.messages).to.eql [
        [ 'alain', 'hubot tfs-build list definitions for SpidersFromMars from defaultcollection' ]
        [ 'hubot', '@alain I found 1 results for SpidersFromMars in defaultcollection' ]
        [ 'hubot', '@alain \n--------------------------------------\n| ID  | Name                         | \n--------------------------------------\n|1    |SpidersFromMars on Octodemo   |\n--------------------------------------' ]
      ]

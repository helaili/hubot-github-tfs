# Description
#   A Hubot script to integrate GitHub and Microsoft Team Foundation Server (TFS)
#
# Configuration:
#    HUBOT_TFS_SERVER - required
#    HUBOT_TFS_USERNAME - required
#    HUBOT_TFS_PASSWORD - required
#    HUBOT_TFS_PROTOCOL - optional, default to `https`
#    HUBOT_TFS_PORT - optional, default to `80` for `http` and `443` for `https`
#    HUBOT_TFS_URL_PREFIX - optional, default to `/`
#    HUBOT_TFS_WORKSTATION - optional, default to `hubot`
#    HUBOT_TFS_DOMAIN - optional, default to blank
#    HUBOT_TFS_DEFAULT_COLLECTION - optional, default to `defaultcollection`
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Alain Hélaïli <helaili@github.com>

httpntlm = require 'httpntlm'

AsciiTable = require './ascii-table'


module.exports = (robot) ->
  commandArray = [
    'tfs-build list builds <project>'
    'tfs-build list builds <project> from <collection>'
    'tfs-build queue <project> with def=<definition id>'
    'tfs-build queue <project> from <collection> with def=<definition id> branch=<branch name>'
    'tfs-build list definitions <project>'
    'tfs-build list definitions <project> from <collection>'
  ]


  # Initialize environment variables
  tfsServer = process.env.HUBOT_TFS_SERVER
  tfsUsername = process.env.HUBOT_TFS_USERNAME
  tfsPassword = process.env.HUBOT_TFS_PASSWORD

  if process.env.HUBOT_TFS_PROTOCOL?
    tfsProtocol = process.env.HUBOT_TFS_PROTOCOL
  else
    tfsProtocol = 'https'

  if process.env.HUBOT_TFS_PORT?
    tfsPort = process.env.HUBOT_TFS_PORT

  if process.env.HUBOT_TFS_URL_PREFIX?
    tfsURLPrefix = process.env.HUBOT_TFS_URL_PREFIX

    # Shall start with a /
    firstSlashIndex = tfsURLPrefix.indexOf '/'
    unless firstSlashIndex is 0
        tfsURLPrefix = "/" + tfsURLPrefix

    # Shall end with a /
    lastChar = tfsURLPrefix.slice -1
    unless lastChar is '/'
      tfsURLPrefix = tfsURLPrefix + "/"

    robot.logger.debug tfsURLPrefix
  else
    tfsURLPrefix = "/"

  if process.env.HUBOT_TFS_WORKSTATION?
    tfsWorkstation = process.env.HUBOT_TFS_WORKSTATION
  else
    tfsWorkstation = "hubot"

  if process.env.HUBOT_TFS_DOMAIN?
    tfsDomain = process.env.HUBOT_TFS_DOMAIN
  else
    tfsDomain = ""

  tfsBuildListAPICall = "_apis/build/builds"
  tfsBuildDefinitionsAPICall = "_apis/build/definitions"
  tfsBuildQueueAPICall = "_apis/build/builds?api-version=2.0  "

  if process.env.HUBOT_TFS_DEFAULT_COLLECTION?
    tfsDefaultCollection = process.env.HUBOT_TFS_DEFAULT_COLLECTION
  else
    tfsDefaultCollection = "defaultcollection"

  # Formatting
  buildListTableDefinition = [
    {
      "label" : "Build",
      "field" : "buildNumber",
      "length" : 13
    },
    {
      "label" : "Status",
      "field" : "status",
      "length" : 10
    },
    {
      "label" : "Result",
      "field" : "result",
      "length" : 9
    },
    {
      "label" : "Branch",
      "field" : "sourceBranch",
      "length" : 20
    },
    {
      "label" : "Definition",
      "field" : "definition.name",
      "length" : 30
    }
  ]

  buildDefinitionsTableDefinition = [
    {
      "label" : "ID",
      "field" : "id",
      "length" : 5
    },
    {
      "label" : "Name",
      "field" : "name",
      "length" : 30
    }
  ]

  buildQueueTableDefinition = [
    {
      "label" : "Build",
      "field" : "buildNumber",
      "length" : 13
    },
    {
      "label" : "Status",
      "field" : "status",
      "length" : 15
    },
    {
      "label" : "Branch",
      "field" : "sourceBranch",
      "length" : 30
    }
  ]

  asciiTable = new AsciiTable()

  # Check for required config
  missingEnvironmentForTFSBuildApi = (res) ->
    missingAnything = false
    unless tfsServer?
      res.send "Don't know how to reach the TFS server. Ensure that HUBOT_TFS_SERVER is set."
      missingAnything |= true
    unless tfsUsername?
      res.send "Missing TFS user name. Ensure that HUBOT_TFS_USERNAME is set."
      missingAnything |= true
    unless tfsPassword?
      res.send "Missing TFS password. Ensure that HUBOT_TFS_PASSWORD is set."
      missingAnything |= true
    missingAnything

  debugRegex = (aRegexArray) ->
     robot.logger.debug aRegexArrayItem for aRegexArrayItem in aRegexArray

  ##########
  # Build the URL to place a call with the TFS API
  #########
  getTfsURL = (apiCallStr, tfsProject, tfsCollection) ->
    if tfsCollection.length is 0  # No collection was provided, using the default one
      tfsCollection = tfsDefaultCollection

    if tfsPort?
      tfsURL = "#{tfsProtocol}://#{tfsServer}:#{tfsPort}#{tfsURLPrefix}#{tfsCollection}/#{tfsProject}/#{apiCallStr}"
    else
      tfsURL = "#{tfsProtocol}://#{tfsServer}#{tfsURLPrefix}#{tfsCollection}/#{tfsProject}/#{apiCallStr}"

    robot.logger.debug tfsURL

    tfsURL



  ########################################
  # GET the response and display a table
  ########################################
  processCommandWithGet = (res, apiCallStr, tableDefinition) ->
    # Don't go further if the required environment variables are missing
    return if missingEnvironmentForTFSBuildApi(res)

    tfsProject = res.match[1]
    tfsCollection = res.match[2]
    tfsURL = getTfsURL(apiCallStr, tfsProject, tfsCollection)

    tfsApiCall = {
      "url": tfsURL,
      "username": tfsUsername,
      "password": tfsPassword,
      "workstation": tfsWorkstation,
      "domain": tfsDomain
    }


    httpntlm.get tfsApiCall, (apiCallErr, apiCallRes) ->
      if apiCallErr
        res.reply "Encountered an error :( #{apiCallErr}"
        return
      else if apiCallRes.statusCode isnt 200
        res.reply "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
        return
      else
        result = JSON.parse apiCallRes.body
        res.reply "Found #{result.count} results for #{tfsProject} in #{tfsCollection}"
        tableResult = asciiTable.buildTable(tableDefinition, result.value)
        res.reply tableResult

  ########################################
  # POST the response and display a table
  ########################################
  processCommandWithPost = (res, apiCallStr, tableDefinition, body) ->
    # Don't go further if the required environment variables are missing
    return if missingEnvironmentForTFSBuildApi(res)

    tfsProject = res.match[1]
    tfsCollection = res.match[2]

    tfsURL = getTfsURL(apiCallStr, tfsProject, tfsCollection)

    tfsApiCall = {
      "url": tfsURL,
      "username": tfsUsername,
      "password": tfsPassword,
      "workstation": tfsWorkstation,
      "domain": tfsDomain,
      "json": body
    }

    httpntlm.post tfsApiCall, (apiCallErr, apiCallRes) ->
      if apiCallErr
        res.reply "Encountered an error :( #{apiCallErr}"
        return
      else if apiCallRes.statusCode isnt 200
        res.reply "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
        return
      else
        #buildTable is expecting an array
        result = []
        result.push JSON.parse apiCallRes.body

        tableResult = asciiTable.buildTable(tableDefinition, result)
        res.reply tableResult

  #######
  #
  #######
  processPushEvent = (tfsProject, tfsCollection, tfsDefinition, repo, branch, pusher, room) ->
    tfsURL = getTfsURL(tfsBuildQueueAPICall, tfsProject, tfsCollection)
    body  = {
      "definition" : {
        "id" : tfsDefinition
      },
      "sourceBranch" : branch
    }
    tfsApiCall = {
      "url": tfsURL,
      "username": tfsUsername,
      "password": tfsPassword,
      "workstation": tfsWorkstation,
      "domain": tfsDomain,
      "json": body
    }

    httpntlm.post tfsApiCall, (apiCallErr, apiCallRes) ->
      if apiCallErr
        robot.messageRoom room, "Encountered an error :( #{apiCallErr} while processing an event"
        return
      else if apiCallRes.statusCode isnt 200
        robot.messageRoom room, "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
        return
      else
        robot.messageRoom room, "@#{pusher} just pushed code on #{repo}/#{branch}. Requesting a TFS build with #{tfsCollection}/#{tfsProject}/#{tfsDefinition}"

  ##########################################################
  # HUBOT COMMAND
  # List the command
  # hubot tfs-build help
  ##########################################################
  robot.respond /tfs-build help/, (res) ->
    response = "Here's what I can do with TFS builds : "
    response += "\n" + command for command in commandArray
    res.reply response

  ##########################################################
  # HUBOT COMMAND
  # Display some environment settings
  # hubot tfs-build env
  ##########################################################
  robot.respond /tfs-build env/, (res) ->
    if tfsPort?
      tfsURL = "#{tfsProtocol}://#{tfsServer}:#{tfsPort}#{tfsURLPrefix}"
    else
      tfsURL = "#{tfsProtocol}://#{tfsServer}#{tfsURLPrefix}"

    res.reply "Here are my TFS settings : \nURL = #{tfsURL}\nDefault collection = #{tfsDefaultCollection}"

  ##########################################################
  # HUBOT COMMAND
  # List the builds for a project
  # hubot tfs-build list builds <project>
  # hubot tfs-build list builds <project> from <collection>
  ##########################################################
  robot.respond /tfs-build list builds (\S*)(?: from )?(\S*)/, (res) ->
    processCommandWithGet(res, tfsBuildListAPICall, buildListTableDefinition)

  ##########################################################
  # HUBOT COMMAND
  # List the build definitions for a project
  # hubot tfs-build list definitions <project>
  # hubot tfs-build list definitions <project> from <collection>
  ##########################################################
  robot.respond /tfs-build list definitions (\S*)(?: from )?(\S*)/, (res) ->
    processCommandWithGet(res, tfsBuildDefinitionsAPICall, buildDefinitionsTableDefinition)

  ##########################################################
  # HUBOT COMMAND
  # Put a new build in the queue
  # hubot tfs-build queue <project> with def=<definition id>'
  # hubot tfs-build queue <project> from <collection> with def=<definition id> branch=<branch name>'
  ##########################################################
  robot.respond /tfs-build queue (\S*)(?: from )?(\S*) with def=(\S*)(?: branch=)?(\S*)/, (res) ->
    tfsDefinition = parseInt(res.match[3], 10)
    tfsBranch = res.match[4]

    body  = {
      "definition" : {
        "id" : tfsDefinition
      }
    }

    unless tfsBranch.length is 0  #A branch was provided
      body.sourceBranch = tfsBranch

    processCommandWithPost(res, tfsBuildQueueAPICall, buildQueueTableDefinition, body)

  ##########################################################
  # HUBOT COMMAND
  # Remembers with definition to use to build a repo
  # hubot tfs-build rem <repo fullname> builds with <project>/<definition id>
  # hubot tfs-build rem <repo fullname> builds with <project>/<definition id> from <collection>
  ##########################################################
  robot.respond /tfs-build rem (\S*) builds with (\S*)\/(\S*)(?: from )?(\S*)/, (res) ->
    repo = res.match[1]

    tfsCollection = res.match[4]
    if tfsCollection.length is 0  # No collection was provided, using the default one
      tfsCollection = tfsDefaultCollection

    tfsData = {
      "project" : res.match[2]
      "definition" : parseInt(res.match[3], 10)
      "collection" : tfsCollection
    }

    tfsRegistrationData = robot.brain.get("tfsRegistrationData") ? {}
    oldSetting = tfsRegistrationData[repo]
    tfsRegistrationData[repo] = tfsData

    # TODO : Test it did save without error
    robot.brain.set "tfsRegistrationData", tfsRegistrationData

    if oldSetting?
      res.reply "Saved build setting for #{repo}. Used to build with #{oldSetting.collection}/#{oldSetting.project}/#{oldSetting.definition}. Now building with #{tfsData.collection}/#{tfsData.project}/#{tfsData.definition}"
    else
      res.reply "Saved build setting for #{repo}. Now building with #{tfsData.collection}/#{tfsData.project}/#{tfsData.definition}"


  ##########################################################
  # HUBOT COMMAND
  # Shows what Hubot remembers about a repo
  # hubot tfs-build rem about <repo fullname>
  ##########################################################
  robot.respond /tfs-build rem about (\S*)/, (res) ->
    repo = res.match[1]
    tfsRegistrationData = robot.brain.get "tfsRegistrationData"
    settings = tfsRegistrationData[repo]
    res.reply "#{repo} builds with #{settings.collection}/#{settings.project}/#{settings.definition}"

  ##########################################################
  # HUBOT LISTENING END-POINT
  ##########################################################
  robot.router.post '/hubot/github-tfs/build/:room', (req, res) ->
    room   = req.params.room
    data   = if req.body.payload? then JSON.parse req.body.payload else req.body
    repo = data.repository.name

    if req.headers["x-github-event"] is "push"
      branch = data.ref.substring(data.ref.lastIndexOf('/')+1)
      tfsRegistrationData = robot.brain.get("tfsRegistrationData") ? {}
      settings = tfsRegistrationData[repo]

      if settings?
        processPushEvent(settings.project, settings.collection, settings.definition, repo, branch, data.pusher.name, room)
      else
        robot.messageRoom "A push event was received on #{repo} but I don't know what to do with it. You might want to use the 'tfs-build rem' command."
    else
      robot.messageRoom "An event was received on #{repo} but I don't know what to do with it"
    res.send 'OK'


  ##########################################################
  # TO BE REMOVED
  ##########################################################
  robot.hear /orly/, (res) ->
    res.send "yarly"

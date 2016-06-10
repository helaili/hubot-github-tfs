# Description
#   A Hubot script to integrate GitHub and Microsoft Team Foundation Server (TFS)
#
# Configuration:
#    HUBOT_TFS_SERVER - required
#    HUBOT_TFS_USERNAME - required
#    HUBOT_TFS_PASSWORD - required
#    HUBOT_TFS_GITHUB_PAT - optional
#    HUBOT_TFS_PROTOCOL - optional, default to `https`
#    HUBOT_TFS_PORT - optional, default to `80` for `http` and `443` for `https`
#    HUBOT_TFS_URL_PREFIX - optional, default to `/`
#    HUBOT_TFS_DEFAULT_COLLECTION - optional, default to `defaultcollection`
#
# Commands:
#   hubot tfs-build list builds for <project>
#   hubot tfs-build list builds for <project> from <collection>
#   tfs-build queue <project> with def=<definition id>
#   tfs-build queue <project> from <collection> with def=<definition id> branch=<branch name>
#   tfs-build list definitions for <project>
#   tfs-build list definitions for <project> from <collection>
#   tfs-build rem all
#   tfs-build rem about <org>/<repo>
#   tfs-build forget about <org>/<repo>
#   tfs-build rem <org>/<repo> builds with <project>/<definition id>
#   tfs-build rem <org>/<repo> builds with <project>/<definition id> from <collection>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Alain Hélaïli <helaili@github.com>

AsciiTable = require './ascii-table'


module.exports = (robot) ->
  commandArray = [
    'tfs-build list builds for <project>'
    'tfs-build list builds for <project> from <collection>'
    'tfs-build queue <project> with def=<definition id>'
    'tfs-build queue <project> from <collection> with def=<definition id> branch=<branch name>'
    'tfs-build list definitions for <project>'
    'tfs-build list definitions for <project> from <collection>'
    'tfs-build rem all'
    'tfs-build rem about <org>/<repo>'
    'tfs-build forget about <org>/<repo>'
    'tfs-build rem <org>/<repo> builds with <project>/<definition id>'
    'tfs-build rem <org>/<repo> builds with <project>/<definition id> from <collection>'
  ]

  # Initialize environment variables
  tfsServer = process.env.HUBOT_TFS_SERVER
  tfsUsername = process.env.HUBOT_TFS_USERNAME
  tfsPassword = process.env.HUBOT_TFS_PASSWORD
  ghPAT = process.env.HUBOT_TFS_GITHUB_PAT

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

  pendingBuilds = {}

  asciiTable = new AsciiTable()

  tableWrapper = ""
  if robot.adapterName is "slack"
    tableWrapper = "```"

  robot.logger.debug robot.adapterName


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

    auth = 'Basic ' + new Buffer(tfsUsername + ':' + tfsPassword).toString('base64');

    robot.http(tfsURL)
      .header('Content-Type', 'application/json')
      .header('Authorization', auth)
      .get() (apiCallErr, apiCallRes, body) ->
        if apiCallErr
          res.reply "Encountered an error :( #{apiCallErr}"
          robot.logger.debug apiCallErr
          robot.logger.debug body
          return
        else if apiCallRes.statusCode isnt 200
          res.reply "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
          robot.logger.debug apiCallErr
          robot.logger.debug body
          return
        else
          robot.logger.debug body
          result = JSON.parse body
          resultHeader = ""
          if tfsCollection? and tfsCollection isnt ""
            resultHeader = "I found #{result.count} results for #{tfsProject} in #{tfsCollection}\n"
          else
            resultHeader = "I found #{result.count} results for #{tfsProject}\n"
          tableResult = "#{tableWrapper}#{asciiTable.buildTable(tableDefinition, result.value)}#{tableWrapper}"
          res.reply "#{resultHeader}#{tableResult}"

  ########################################
  # POST the response and display a table
  ########################################
  processCommandWithPost = (res, apiCallStr, tableDefinition, data) ->
    # Don't go further if the required environment variables are missing
    return if missingEnvironmentForTFSBuildApi(res)

    tfsProject = res.match[1]
    tfsCollection = res.match[2]

    tfsURL = getTfsURL(apiCallStr, tfsProject, tfsCollection)

    auth = 'Basic ' + new Buffer(tfsUsername + ':' + tfsPassword).toString('base64');

    robot.http(tfsURL)
      .header('Content-Type', 'application/json')
      .header('Authorization', auth)
      .post(JSON.stringify(data)) (apiCallErr, apiCallRes, body) ->
        if apiCallErr
          res.reply "Encountered an error :( #{apiCallErr}"
          robot.logger.debug apiCallErr
          robot.logger.debug body
          return
        else if apiCallRes.statusCode isnt 200
          res.reply "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
          robot.logger.debug apiCallErr
          robot.logger.debug body
          return
        else
          robot.logger.debug body
          #buildTable is expecting an array
          result = []
          result.push JSON.parse body

          tableResult = "#{tableWrapper}#{asciiTable.buildTable(tableDefinition, result)}#{tableWrapper}"
          res.reply tableResult

  ###############################################################
  # A Push event has been received, we want to trigger a build
  ###############################################################
  processPushEvent = (tfsProject, tfsCollection, tfsDefinition, buildReqData, room) ->
    tfsURL = getTfsURL(tfsBuildQueueAPICall, tfsProject, tfsCollection)
    repo = buildReqData.repository.name
    branch = buildReqData.ref
    sha = buildReqData.after
    pusher = buildReqData.pusher.name

    data  = {
      "definition" : {
        "id" : tfsDefinition
      },
      "sourceBranch" : branch
      "sourceVersion" : sha
    }

    auth = 'Basic ' + new Buffer(tfsUsername + ':' + tfsPassword).toString('base64');

    robot.http(tfsURL)
      .header('Content-Type', 'application/json')
      .header('Authorization', auth)
      .post(JSON.stringify(data)) (apiCallErr, apiCallRes, body) ->
        if apiCallErr
          robot.messageRoom room, "Encountered an error :( #{apiCallErr} while processing an event"
          robot.logger.debug apiCallRes
          robot.logger.debug body
          return
        else if apiCallRes.statusCode isnt 200
          robot.messageRoom room, "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
          robot.logger.debug apiCallRes
          robot.logger.debug body
          return
        else
          buildResData = JSON.parse body
          robot.logger.debug buildResData

          robot.messageRoom room, "@#{pusher} just pushed code on #{repo}/#{branch}. Requested TFS build ##{buildResData.id} with #{tfsCollection}/#{tfsProject}/#{tfsDefinition}"

          setGitHubStatus(buildReqData.repository.statuses_url, buildReqData.after, "pending",  buildResData.url, "Requested TFS build ##{buildResData.id} with #{tfsCollection}/#{tfsProject}/#{tfsDefinition}")

          # Saving the repo and commit details so we can call the GitHub status API when build is finished.
          pendingBuilds[buildResData.id] = buildReqData

  ###############################################################
  # Update GitHub status
  ###############################################################
  setGitHubStatus = (statusURL, sha, state, link, description) ->
    if ghPAT?
      newURL = statusURL.replace /\{sha\}/, sha
      robot.logger.debug "Sending an update to #{newURL}"

      data = {
        "state": state
        "target_url": link
        "description": description
        "context": "continuous-integration/tfs/push"
      }

      robot.http(newURL)
        .header("Content-Type", "application/json")
        .header("Authorization", "token #{ghPAT}")
        .post(JSON.stringify(data)) (err, res, body) ->
          if err
            robot.logger.debug "Encountered an error :( #{err}"
            return
          else
            robot.logger.debug body
            return

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
  # hubot tfs-build list builds for <project>
  # hubot tfs-build list builds for <project> from <collection>
  ##########################################################
  robot.respond /tfs-build list builds for (\S*)(?: from )?(\S*)/, (res) ->
    processCommandWithGet(res, tfsBuildListAPICall, buildListTableDefinition)

  ##########################################################
  # HUBOT COMMAND
  # List the build definitions for a project
  # hubot tfs-build list definitions for <project>
  # hubot tfs-build list definitions for <project> from <collection>
  ##########################################################
  robot.respond /tfs-build list definitions for (\S*)(?: from )?(\S*)/, (res) ->
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
  # hubot tfs-build rem <org>/<repo> builds with <project>/<definition id>
  # hubot tfs-build rem <org>/<repo> builds with <project>/<definition id> from <collection>
  ##########################################################
  robot.respond /tfs-build rem (\S*)\/(\S*) builds with (\S*)\/(\S*)(?: from )?(\S*)/, (res) ->
    org = res.match[1]
    repo = res.match[2]

    tfsCollection = res.match[5]
    if tfsCollection.length is 0  # No collection was provided, using the default one
      tfsCollection = tfsDefaultCollection

    tfsData = {
      "project" : res.match[3]
      "definition" : parseInt(res.match[4], 10)
      "collection" : tfsCollection
    }

    tfsRegistrationData = robot.brain.get("tfsRegistrationData") ? {}
    oldSetting = tfsRegistrationData["#{org}/#{repo}"]
    tfsRegistrationData["#{org}/#{repo}"] = tfsData

    # TODO : Test it did save without error
    robot.brain.set "tfsRegistrationData", tfsRegistrationData

    if oldSetting?
      res.reply "Saved build setting for #{repo}. Used to build with #{oldSetting.collection}/#{oldSetting.project}/#{oldSetting.definition}. Now building with #{tfsData.collection}/#{tfsData.project}/#{tfsData.definition}"
    else
      res.reply "Saved build setting for #{repo}. Now building with #{tfsData.collection}/#{tfsData.project}/#{tfsData.definition}"


  ##########################################################
  # HUBOT COMMAND
  # Shows what Hubot remembers about a repo
  # hubot tfs-build rem about <org>/<repo>
  ##########################################################
  robot.respond /tfs-build rem about (\S*)/, (res) ->
    repo = res.match[1]
    tfsRegistrationData = robot.brain.get "tfsRegistrationData"
    settings = tfsRegistrationData[repo]
    if settings?
      res.reply "#{repo} builds with #{settings.project}/#{settings.definition} from #{settings.collection}"
    else
      res.reply "Sorry, I don't remember anything about #{repo}."

  ##########################################################
  # HUBOT COMMAND
  # Forget a repo
  # hubot tfs-build forget about <org>/<repo>
  ##########################################################
  robot.respond /tfs-build forget about (\S*)/, (res) ->
    repo = res.match[1]
    tfsRegistrationData = robot.brain.get "tfsRegistrationData"
    delete tfsRegistrationData[repo]
    res.reply "#{repo} is now forgotten"

  ##########################################################
  # HUBOT COMMAND
  # Shows what Hubot remembers about
  # hubot tfs-build rem all
  ##########################################################
  robot.respond /tfs-build rem all/, (res) ->
    tfsRegistrationData = robot.brain.get "tfsRegistrationData"

    if tfsRegistrationData?
      robot.logger.debug tfsRegistrationData
      response = "Here's all I remember : "
      for own repo of tfsRegistrationData
        repoData = tfsRegistrationData[repo]
        response += "\n#{repo} builds with #{repoData.collection}/#{repoData.project}/#{repoData.definition}"
    else
      response = "Sorry, I don't remember anything."
    res.reply response

  ##########################################################
  # HUBOT LISTENING END-POINT FOR PUSH EVENTS
  ##########################################################
  robot.router.post '/hubot/github-tfs/build/:room', (req, res) ->
    room   = req.params.room
    buildReqData   = if req.body.payload? then JSON.parse req.body.payload else req.body
    repo = buildReqData.repository.full_name

    if req.headers["x-github-event"] is "push"
      tfsRegistrationData = robot.brain.get("tfsRegistrationData") ? {}
      settings = tfsRegistrationData[repo]

      if settings?
        robot.logger.debug "Received a push event from #{repo}"

        processPushEvent(settings.project, settings.collection, settings.definition, buildReqData, room)
      else
        robot.logger.debug "Received a push event from #{repo} but don't know what to do with it"
        robot.messageRoom room, "A push event was received on #{repo} but I don't know what to do with it. You might want to use the 'tfs-build rem' command."
    else
      robot.logger.debug "Received a push event from #{repo} but don't know what to do with it"
      robot.messageRoom room, "An event was received on #{repo} but I don't know what to do with it. Sorry!"
    res.send 'OK'


  ##########################################################
  # HUBOT LISTENING END-POINT FOR BUILD RESULT
  ##########################################################
  robot.router.post '/hubot/github-tfs/build-result/:room', (req, res) ->
    room   = req.params.room
    buildResData = req.body.resource
    robot.logger.debug buildResData

    # Retrieving the push event previously stored
    buildReqData = pendingBuilds[buildResData.id]

    if buildReqData?
      # Don't need to keed this push data
      delete pendingBuilds[buildResData.id]
      #robot.logger.debug buildReqData

      branch = buildReqData.ref.substring(buildReqData.ref.lastIndexOf('/')+1)
      sha = buildReqData.after.substring(0, 7)

      robot.messageRoom room, "Build ##{buildResData.id} of #{buildReqData.repository.name}/#{branch} (#{sha}) #{buildResData.status}"

      #Setting the default state to error as the list of return code for the TFS API isn't documented
      state = "error"
      if buildResData.status == "succeeded"
        state = "success"
      else if buildResData.status == "failed"
        state = "failure"

      setGitHubStatus(buildReqData.repository.statuses_url, buildReqData.after, state,  buildResData.url, "Build submitted by Hubot")

    res.send 'OK'

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


module.exports = (robot) ->
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

  if process.env.HUBOT_TFS_DEFAULT_COLLECTION?
    tfsDefaultCollection = process.env.HUBOT_TFS_DEFAULT_COLLECTION
  else
    tfsDefaultCollection = "defaultcollection"

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

  debugRegex = (aRegexArrayItem) ->
     robot.logger.debug aRegexArrayItem

  robot.respond /tfs build list (\S*)(?: from )?(\S*)/, (res) ->
    # Don't go further if the required environment variables are missing
    return if missingEnvironmentForTFSBuildApi(res)

    tfsProject = res.match[1]
    tfsCollection = res.match[2]

    if tfsCollection.length is 0  # No collection was provided, using the default one
      tfsCollection = tfsDefaultCollection

    if tfsPort?
      tfsURL = "#{tfsProtocol}://#{tfsServer}:#{tfsPort}#{tfsURLPrefix}#{tfsCollection}/#{tfsProject}/#{tfsBuildListAPICall}"
    else
      tfsURL = "#{tfsProtocol}://#{tfsServer}#{tfsURLPrefix}#{tfsCollection}/#{tfsProject}/#{tfsBuildListAPICall}"

    tfsApiCall = {
      "url": tfsURL,
      "username": tfsUsername,
      "password": tfsPassword,
      "workstation": tfsWorkstation,
      "domain": tfsDomain
    }

    robot.logger.debug tfsApiCall.url


    httpntlm.get tfsApiCall, (apiCallErr, apiCallRes) ->
      if apiCallErr
        res.send "Encountered an error :( #{apiCallErr}"
        return
      else if apiCallRes.statusCode isnt 200
        res.send "Request came back with a problem :( Response code is #{apiCallRes.statusCode}."
        return
      else
        res.reply apiCallRes.body


  robot.hear /orly/, (res) ->
    res.send "yarly"

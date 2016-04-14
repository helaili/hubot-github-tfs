# Description
#   A bunch of useful methods
#
# Author:
#   Alain Hélaïli <helaili@github.com>


############################################################################
# Allows to access a value in obj with a string path such as "xxx.yyy.zzz"
# so you can get the value of obj.xxx.yyy.zzz instead of obj["xxx.yyy.zzz"]
#############################################################################
getValueFromAccessPath = (obj, pathSegmentArray) ->
  pathSegment = pathSegmentArray.shift()
  if pathSegment?
    getValueFromAccessPath(obj[pathSegment], pathSegmentArray)
  else
    obj



githubTfsUtils = exports? and exports or @githubTfsUtils = {}



class AsciiTable
  ######################################################################
  # Add some padChar at the end of str so its length is exactly `length`
  ######################################################################
  padString: (str, length, padChar) ->
    paddedString = str.substr(0, length)
    unless paddedString.length is length
      paddedString = paddedString + padChar while paddedString.length < length
    paddedString

  ############################################################################
  # Allows to access a value in obj with a string path such as "xxx.yyy.zzz"
  # so you can get the value of obj.xxx.yyy.zzz instead of obj["xxx.yyy.zzz"]
  #############################################################################
  getValueFromAccessPath: (obj, pathSegmentArray) ->
    pathSegment = pathSegmentArray.shift()
    if pathSegment?
      this.getValueFromAccessPath(obj[pathSegment], pathSegmentArray)
    else
      obj

  #########################################
  # Formatting a line in the table body
  # | vall 1 | val 2        |
  #########################################
  buildDataLine: (entry, tableDefinition) ->
    line = "|"
    line += this.padString(this.getValueFromAccessPath(entry, colDef.field.split(".")), colDef.length, " ") + "|" for colDef in tableDefinition
    line

  ############################################
  # Build an ascii table to display result
  ############################################
  buildTable: (tableDefinition, data) ->
    # Size of a row in chars, including border and column delimiter
    size = 1
    # The header of the table
    header = "| "
    # The body of the table
    body = ""

    size += colDef.length for colDef in tableDefinition

    header += this.padString(colDef.label, colDef.length-2, " ") + " | " for colDef in tableDefinition

    # Creates a line of ---- to be using above and below the header line
    border = this.padString("", size + tableDefinition.length, "-")
    # Now building the overall header
    # ------------------------
    # | col 1 | col 2        |
    # ------------------------
    header = "\n" + border + "\n" + header + "\n" + border
    body = body + "\n" + this.buildDataLine entry, tableDefinition for entry in data
    table = header + body + "\n" + border

    table

  sayHello: () ->
    msg = "Hello"
    msg


module.exports = AsciiTable

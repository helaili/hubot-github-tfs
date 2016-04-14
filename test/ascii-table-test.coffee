chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

AsciiTable = require './../src/ascii-table'

expect = chai.expect
assert = chai.assert

describe 'ascii-table', ->
  beforeEach ->
    @asciiTable = new AsciiTable()

  it 'pads strings to the right length', ->
    paddedString = @asciiTable.padString( "", 10, "-")
    expect(paddedString).to.be.a('string')
    expect(paddedString).to.have.length(10)

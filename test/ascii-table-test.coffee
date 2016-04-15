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
    paddedString = @asciiTable.padString( '', 10, '-')
    expect(paddedString).to.be.a('string')
    expect(paddedString).to.have.length(10)
    expect(paddedString).to.equal('----------')

  it 'pads strings with the right char', ->
    paddedString = @asciiTable.padString( '**', 3, '-')
    expect(paddedString).to.be.a('string')
    expect(paddedString).to.equal('**-')

  it 'shrinks the string when needed', ->
    paddedString = @asciiTable.padString( '*****', 3, '-')
    expect(paddedString).to.be.a('string')
    expect(paddedString).to.equal('***')

  jsonObj =
    field1 : 'astring'
    field2 : 42
    field3 :
        field4 : 'anotherstring'
        field5 :
            field6 : 'yetanotherstring'
            field7 : 42


  it 'gets a value from a simple path in a JSON object', ->
    value = @asciiTable.getValueFromAccessPath(jsonObj, 'field1')
    expect(value).to.be.a('string')
    expect(value).to.equal('astring')

    value = @asciiTable.getValueFromAccessPath(jsonObj, 'field2')
    expect(value).to.be.a('number')
    expect(value).to.equal(42)

  it 'gets a value from a complex path in a JSON object', ->
    value = @asciiTable.getValueFromAccessPath(jsonObj, 'field3.field5.field6')
    expect(value).to.be.a('string')
    expect(value).to.equal('yetanotherstring')

    value = @asciiTable.getValueFromAccessPath(jsonObj, 'field3.field5.field7')
    expect(value).to.be.a('number')
    expect(value).to.equal(42)

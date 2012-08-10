Spine   = @Spine or require('spine')
isArray = Spine.isArray
require = @require or ((value) -> eval(value))

class Collection extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  all: ->
    @model.select (rec) => @associated(rec)

  first: ->
    @all()[0]

  last: ->
    values = @all()
    values[values.length - 1]

  find: (_id) ->
    records = @select (rec) =>
      rec._id + '' is _id + ''
    throw('Unknown record') unless records[0]
    records[0]

  findAllByAttribute: (name, value) ->
    @model.select (rec) =>
      @associated(rec) and rec[name] is value

  findByAttribute: (name, value) ->
    @findAllByAttribute(name, value)[0]

  select: (cb) ->
    @model.select (rec) =>
      @associated(rec) and cb(rec)

  refresh: (values) ->
    delete @model.records[record._id] for record in @all()
    records = @model.fromJSON(values)

    records = [records] unless isArray(records)

    for record in records
      record.newRecord = false
      record[@fkey] = @record._id
      @model.records[record._id] = record

    @model.trigger('refresh', @model.cloneArray(records))

  create: (record) ->
    record[@fkey] = @record._id
    @model.create(record)

  # Private

  associated: (record) ->
    record[@fkey] is @record._id

class Instance extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  exists: ->
    @record[@fkey] and @model.exists(@record[@fkey])

  update: (value) ->
    unless value instanceof @model
      value = new @model(value)
    value.save() if value.isNew()
    @record[@fkey] = value and value._id

class Singleton extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  find: ->
    @record._id and @model.findByAttribute(@fkey, @record._id)

  update: (value) ->
    unless value instanceof @model
      value = @model.fromJSON(value)

    value[@fkey] = @record._id
    value.save()

singularize = (str) ->
  str.replace(/s$/, '')

underscore = (str) ->
  str.replace(/::/g, '/')
     .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
     .replace(/([a-z\d])([A-Z])/g, '$1_$2')
     .replace(/-/g, '_')
     .toLowerCase()

Spine.Model.extend
  hasMany: (name, model, fkey) ->
    fkey ?= "#{underscore(this.className)}__id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Collection(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).refresh(value) if value?
      association(@)

  belongsTo: (name, model, fkey) ->
    fkey ?= "#{singularize(name)}__id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Instance(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).update(value) if value?
      association(@).exists()

    @attributes.push(fkey)

  hasOne: (name, model, fkey) ->
    fkey ?= "#{underscore(@className)}__id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Singleton(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).update(value) if value?
      association(@).find()

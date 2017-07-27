###
Backbone dualStorage Adapter v1.4.2

A simple module to replace `Backbone.sync` with *localStorage*-based
persistence. Models are given GUIDS, and saved into a JSON object. Simple
as that.

---
Customized version for NC
https://github.com/raohmaru/Backbone.dualStorage
###

Backbone.DualStorage = {
  offlineStatusCodes: [408, 502]
}

Backbone.Model.prototype.hasTempId = ->
  _.isString(@id) and @id.length is 36 and @id.indexOf('t') == 0

getStoreName = (collection, model) ->
  model ||= collection.model.prototype
  _.result(collection, 'storeName') || _.result(model, 'storeName') ||
  _.result(collection, 'url')       || _.result(model, 'urlRoot')   || _.result(model, 'url')

# Make it easy for collections to sync dirty and destroyed records
# Simply call collection.syncDirtyAndDestroyed()
Backbone.Collection.prototype.syncDirty = (options) ->
  store = localStorage.getItem("#{getStoreName(@)}_dirty")
  ids = (store and store.split(',')) or []

  for id in ids
    @get(id)?.save(null, options)

Backbone.Collection.prototype.dirtyModels = ->
  store = localStorage.getItem("#{getStoreName(@)}_dirty")
  ids = (store and store.split(',')) or []
  models = for id in ids
    @get(id)

  _.compact(models)

Backbone.Collection.prototype.syncDestroyed = (options) ->
  store = localStorage.getItem("#{getStoreName(@)}_destroyed")
  ids = (store and store.split(',')) or []

  for id in ids
    model = new @model
    model.set model.idAttribute, id
    model.collection = @
    model.destroy(options)

Backbone.Collection.prototype.destroyedModelIds = ->
  store = localStorage.getItem("#{getStoreName(@)}_destroyed")

  ids = (store and store.split(',')) or []

Backbone.Collection.prototype.syncDirtyAndDestroyed = (options) ->
  @syncDirty(options)
  @syncDestroyed(options)

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  sep: '_' # previously '-'

  constructor: (name) ->
    @name = name
    @records = @recordsOn @name

  # Generates an unique id to use when saving new instances into localstorage
  # by default generates a pseudo-GUID by concatenating random hexadecimal.
  # you can overwrite this function to use another strategy
  generateId: ->
    't' + S4().substring(1) + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()

  # Save the current state of the **Store** to *localStorage*.
  save: ->
    localStorage.setItem @name, @records.join(',')

  recordsOn: (key) ->
    store = localStorage.getItem(key)
    (store and store.split(',')) or []

  dirty: (model) ->
    dirtyRecords = @recordsOn @name + '_dirty'
    if not _.include(dirtyRecords, model.id.toString())
      dirtyRecords.push model.id
      localStorage.setItem @name + '_dirty', dirtyRecords.join(',')
    model

  clean: (model, from) ->
    store = "#{@name}_#{from}"
    dirtyRecords = @recordsOn store
    if _.include dirtyRecords, model.id.toString()
      localStorage.setItem store, _.without(dirtyRecords, model.id.toString()).join(',')
    model

  destroyed: (model) ->
    destroyedRecords = @recordsOn @name + '_destroyed'
    if not _.include destroyedRecords, model.id.toString()
      destroyedRecords.push model.id
      localStorage.setItem @name + '_destroyed', destroyedRecords.join(',')
    model

  # Add a model, giving it a unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model, options) ->
    if not _.isObject(model) then return model
    if not model.id
      model.set model.idAttribute, @generateId()
    localStorage.setItem @name + @sep + model.id, JSON.stringify(if model.toJSON then model.toJSON(options) else model)
    @records.push model.id.toString()
    @save()
    model

  # Update a model by replacing its copy in `this.data`.
  update: (model, options) ->
    if not _.isObject(model) then return model
    if not model.id
      model.set model.idAttribute, @generateId()
    localStorage.setItem @name + @sep + model.id, JSON.stringify(if model.toJSON then model.toJSON(options) else model)
    if not _.include(@records, model.id.toString())
      @records.push model.id.toString()
    @save()
    model

  clear: ->
    for id in @records
      localStorage.removeItem @name + @sep + id
    @records = []
    @save()

  hasDirtyOrDestroyed: ->
    not _.isEmpty(localStorage.getItem(@name + '_dirty')) or not _.isEmpty(localStorage.getItem(@name + '_destroyed'))

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    modelAsJson = localStorage.getItem(@name + @sep + model.id)
    return null if modelAsJson == null
    JSON.parse modelAsJson

  # Return the array of all models currently in storage.
  findAll: ->
    for id in @records
      JSON.parse localStorage.getItem(@name + @sep + id)

  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    localStorage.removeItem @name + @sep + model.id
    @records = _.reject(@records, (record_id) ->
      record_id is model.id.toString()
    )
    @save()
    model


window.Store.exists = (storeName) -> localStorage.getItem(storeName) isnt null

callbackTranslator =
  needsTranslation: Backbone.VERSION == '0.9.10'

  forBackboneCaller: (callback) ->
    if @needsTranslation
      (model, resp, options) -> callback.call null, resp
    else
      callback

  forDualstorageCaller: (callback, model, options) ->
    if @needsTranslation
      (resp) -> callback.call null, model, resp, options
    else
      callback

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
localsync = (method, model, options) ->
  isValidModel = (method is 'clear') or (method is 'hasDirtyOrDestroyed')
  isValidModel ||= model instanceof Backbone.Model
  isValidModel ||= model instanceof Backbone.Collection

  if not isValidModel
    throw new Error 'model parameter is required to be a backbone model or collection.'

  store = new Store options.storeName

  response = switch method
    when 'read'
      if model instanceof Backbone.Model
        store.find(model)
      else
        store.findAll()
    when 'hasDirtyOrDestroyed'
      store.hasDirtyOrDestroyed()
    when 'clear'
      store.clear()
    when 'create'
      if options.add and not options.merge and (preExisting = store.find(model))
        preExisting
      else
        model = store.create(model, options)
        store.dirty(model) if options.dirty
        model
    when 'update'
      store.update(model, options)
      if options.dirty
        store.dirty(model)
      else
        store.clean(model, 'dirty')
    when 'delete'
      store.destroy(model)
      if options.dirty && !model.hasTempId()
        store.destroyed(model)
      else
        if model.hasTempId()
          store.clean(model, 'dirty')
        else
          store.clean(model, 'destroyed')

  if response
    if response.toJSON
      response = response.toJSON(options)
    if response.attributes
      response = response.attributes

  unless options.ignoreCallbacks
    if response
      options.success response
    else
      options.error 'Record not found'

  response

# Helper function to run parseBeforeLocalSave() in order to
# parse a remote JSON response before caching locally
parseRemoteResponse = (object, response) ->
  if not (object and object.parseBeforeLocalSave) then return response
  if _.isFunction(object.parseBeforeLocalSave) then object.parseBeforeLocalSave(response)

modelUpdatedWithResponse = (model, response) ->
  modelClone = new Backbone.Model
  modelClone.idAttribute = model.idAttribute
  modelClone.set model.attributes
  modelClone.set model.parse response
  modelClone

backboneSync = Backbone.DualStorage.originalSync = Backbone.sync
onlineSync = (method, model, options) ->
  options.success = callbackTranslator.forBackboneCaller(options.success)
  options.error   = callbackTranslator.forBackboneCaller(options.error)
  Backbone.DualStorage.originalSync(method, model, options)

dualsync = (method, model, options) ->
  options.storeName = getStoreName(model.collection, model)
  options.storeExists = Store.exists(options.storeName)
  options.success = callbackTranslator.forDualstorageCaller(options.success, model, options)
  options.error   = callbackTranslator.forDualstorageCaller(options.error, model, options)

  # execute only online sync
  return onlineSync(method, model, options) if _.result(model, 'remote') or _.result(model.collection, 'remote')

  # execute only local sync
  local = _.result(model, 'local') or _.result(model.collection, 'local')
  options.dirty = options.remote is false and not local
  if options.remote is false or local
    method = "update" if options.forceUpdate
    return localsync(method, model, options)

  # execute dual sync
  options.ignoreCallbacks = true

  success = options.success
  error = options.error

  useOfflineStorage = ->
    options.dirty = true
    options.ignoreCallbacks = false
    options.success = success
    options.error = error
    localsync(method, model, options)

  hasOfflineStatusCode = (xhr) ->
    offlineStatusCodes = Backbone.DualStorage.offlineStatusCodes
    offlineStatusCodes = offlineStatusCodes(xhr) if _.isFunction(offlineStatusCodes)
    xhr.status == 0 or xhr.status in offlineStatusCodes

  relayErrorCallback = (xhr) ->
    online = not hasOfflineStatusCode xhr
    if online or method == 'read' and not options.storeExists
      error xhr
    else
      useOfflineStorage()

  switch method
    when 'read'
      if localsync('hasDirtyOrDestroyed', model, options)
        useOfflineStorage()
      else
        options.success = (resp, _status, _xhr) ->
          return useOfflineStorage() if hasOfflineStatusCode options.xhr
          return success(resp, _status, _xhr) if _xhr and _xhr.status == 304
          resp = parseRemoteResponse(model, resp)

          if model instanceof Backbone.Collection
            collection = model
            idAttribute = collection.model.prototype.idAttribute
            localsync('clear', collection, options) unless options.add
            for modelAttributes in resp
              model = collection.get(modelAttributes[idAttribute])
              if model
                responseModel = modelUpdatedWithResponse(model, modelAttributes)
              else
                responseModel = new collection.model(modelAttributes)
              localsync('update', responseModel, options)
          else
            responseModel = modelUpdatedWithResponse(model, resp)
            localsync('update', responseModel, options)

          success(resp, _status, _xhr)

        options.error = (xhr) ->
          relayErrorCallback xhr

        options.xhr = onlineSync(method, model, options)

    when 'create'
      options.success = (resp, _status, _xhr) ->
        return useOfflineStorage() if hasOfflineStatusCode options.xhr
        if options.parse != false
          updatedModel = modelUpdatedWithResponse model, resp
          localsync(method, updatedModel, options)
        else
          method = "update"
          localsync(method, model, options)
        success(resp, _status, _xhr)
      options.error = (xhr) ->
        relayErrorCallback xhr

      options.xhr = onlineSync(method, model, options)

    when 'update'
      if model.hasTempId()
        temporaryId = model.id

        options.success = (resp, _status, _xhr) ->
          model.set model.idAttribute, temporaryId, silent: true
          return useOfflineStorage() if hasOfflineStatusCode options.xhr
          updatedModel = modelUpdatedWithResponse model, resp
          localsync('delete', model, options)
          localsync('create', updatedModel, options)
          success(resp, _status, _xhr)
        options.error = (xhr) ->
          model.set model.idAttribute, temporaryId, silent: true
          relayErrorCallback xhr

        model.set model.idAttribute, null, silent: true
        options.xhr = onlineSync('create', model, options)
      else
        options.success = (resp, _status, _xhr) ->
          return useOfflineStorage() if hasOfflineStatusCode options.xhr
          updatedModel = modelUpdatedWithResponse model, resp
          localsync(method, updatedModel, options)
          success(resp, _status, _xhr)
        options.error = (xhr) ->
          relayErrorCallback xhr

        options.xhr = onlineSync(method, model, options)

    when 'delete'
      if model.hasTempId()
        options.ignoreCallbacks = false
        localsync(method, model, options)
      else
        options.success = (resp, _status, _xhr) ->
          return useOfflineStorage() if hasOfflineStatusCode options.xhr
          localsync(method, model, options)
          success(resp, _status, _xhr)
        options.error = (xhr) ->
          relayErrorCallback xhr

        options.xhr = onlineSync(method, model, options)

Backbone.sync = dualsync

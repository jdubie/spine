Spine = @Spine or require('spine')
$     = Spine.$

hashStrip    = /^#*/
namedParam   = /:([\w\d]+)/g
splatParam   = /\*([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

#window = window ? module?.require('jsdom').createWindow()

class Spine.Route extends Spine.Module

  ###
    static methods
  ###

  @extend Spine.Events

  @historySupport: window.history?.pushState?

  @routes: []

  @options:
    trigger: true
    history: false
    shim: false

  @add: (path, callback) ->
    if (typeof path is 'object' and path not instanceof RegExp)
      @add(key, value) for key, value of path
    else
      @routes.push(new @(path, callback))

  @setup: (options = {}) ->
    @options = $.extend({}, @options, options)

    if (@options.history)
      @history = @historySupport && @options.history

    return if @options.shim

    if @history
      $(window).bind('popstate', @change)
    else
      $(window).bind('hashchange', @change)
    @change()

  @unbind: ->
    return if @options.shim

    if @history
      $(window).unbind('popstate', @change)
    else
      $(window).unbind('hashchange', @change)

  @navigate: (args...) ->
    options = {}

    lastArg = args[args.length - 1]
    if typeof lastArg is 'object'
      options = args.pop()
    else if typeof lastArg is 'boolean'
      options.trigger = args.pop()

    options = $.extend({}, @options, options)

    path = args.join('/')
    #return if @path is path # todo make it an option to re-run routes
    @path = path


    @trigger('navigate', @path)

    @matchRoute(@path, options) if options.trigger

    return if options.shim

    if @history
      history.pushState(
        {},
        document.title,
        @path
      )
    else
      window.location.hash = @path

  # Private

  @getPath: ->
    path = window.location.pathname
    if path.substr(0,1) isnt '/'
      path = '/' + path
    path

  @getHash: -> window.location.hash

  @getFragment: -> @getHash().replace(hashStrip, '')

  @getHost: ->
    (document.location + '').replace(@getPath() + @getHash(), '')

  @change: ->
    path = if @history then @getPath() else @getFragment()
    return if path is @path
    @path = path
    @matchRoute(@path)

  @matchRoute: (path, options) ->
    for route in @routes
      if route.match(path, options)
        @trigger('change', route, path)
        return route

  ###
    instance methods
  ###

  constructor: (@path, @callback) ->
    @names = []

    if typeof path is 'string'
      ## parse all variables in path of type :name
      namedParam.lastIndex = 0
      while (match = namedParam.exec(path)) != null
        @names.push(match[1])

      ## parse all variables in path of type (*)
      splatParam.lastIndex = 0
      while (match = splatParam.exec(path)) != null
        @names.push(match[1])

      ## create a proper regular expression
      path = path.replace(escapeRegExp, '\\$&')
                 .replace(namedParam, '([^\/]*)')
                 .replace(splatParam, '(.*?)')

      @route = new RegExp('^' + path + '$')
    else
      @route = path

  ## matches current route on a path
  match: (path, options = {}) ->
    match = @route.exec(path)
    return false unless match
    ## upon match, retrieves variables/parameters of route
    options.match = match
    params = match.slice(1)

    if @names.length
      for param, i in params
        options[@names[i]] = param

    ## performs callback
    ##    false return value will cause matchRoute to continue to
    ##    search for matching routes
    @callback.call(null, options) isnt false

# Coffee-script bug
Spine.Route.change = Spine.Route.proxy(Spine.Route.change)

Spine.Controller.include
  route: (path, callback) ->
    Spine.Route.add(path, @proxy(callback))

  routes: (routes) ->
    @route(key, value) for key, value of routes

  navigate: ->
    Spine.Route.navigate.apply(Spine.Route, arguments)

module?.exports = Spine.Route

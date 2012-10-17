# [-79.708, 43.607]

root = exports ? this
root.Longitude = null
root.Latitude = null
root.Accuracy = null

root.isoMap = null
root.mapdata = {locations:[], places:[]}
root.maprendered = []
root.updateinprogress = true
root.Center = [0, 0]
root.Delta = 0
root.User = null
root.Characters = []
    
delay = (ms, func) -> setTimeout func, ms
acquireGeo = ->
  if Modernizr.geolocation
    navigator.geolocation.getCurrentPosition useGeolocation, onGeolocationError
  else
    alert "Geolocation is not supported."

useGeolocation = (position) ->
  root.Longitude = parseFloat position.coords.longitude.toFixed 3
  root.Latitude = parseFloat position.coords.latitude.toFixed 3
  root.Accuracy = position.coords.accuracy
  if Longitude and Latitude and Accuracy then root.updateinprogress = false
  console.log "Location Acquired:[#{Longitude}, #{Latitude}] @~#{Accuracy}m"

onGeolocationError = (error) ->
  alert "Geolocation error - code: " + error.code + " message : " + error.message
  
Lovely ["dom-1.2.0", "fx-1.0.3", "ui-2.0.1", "ajax-1.1.2", "dnd-1.0.1", "sugar-1.0.3", "glyph-icons-1.0.2", "killie-1.0.0"], ($, fx, ui, ajax, dnd) ->
  hover = document.createElement("div")
  hover.className = "pixel"
  hover.id = "tail"
  $(hover).insertTo("body", "top")
  "#tail".hide()
  "#menu".hide()
  generateTiles = (tiles) ->
    console.log "Generating #{tiles.length} terrain tiles."
    for tile in tiles
      [x, y] = c2t tile.coordinates
      t = Crafty.e("2D, Text, DOM, Mouse, Coordinates, Terrain, " + tile.terrain)
        .attr
          long: tile.coordinates[0]
          lat: tile.coordinates[1]
          mapx: x
          mapy: y
          z: (x + y) * 5
          sight: 0
        .areaMap([0, 72], [64, 40], [128, 72], [64, 105])
        .bind("MouseOver", ->
          @.textColor("#000000", 0.7))
        .bind("MouseOut", ->
          @.textColor("#000000", 0.16))
        .css
          "font": "7pt Monaco"
          "text-align": "center"
          "line-height": "140px"
        .textColor("#000000", 0.16)
      for interactive in ["water", "waterfish", "forestmushroom", "forestfruit"]
        if tile.terrain is interactive
          t.addComponent "Collision"
          t.collision(new Crafty.polygon([0, 72], [64, 40], [128, 72], [64, 105]))
      t._element.className += " mapx#{x} mapy#{y}" 
      t.checkvision()
      isoMap.place x, y, 0, t
    console.log "Completed Map Gen"

  generatePlaces = (places) ->
    console.log "Generating #{places.length} place tiles."
    for place in places
      [x, y] = c2t place.coordinates
      z = 0
      if place.kind is "smith" or place.kind is "farm" or place.kind is "academy" then z = 1
      if place.kind is "shack" or place.kind is "house" or place.kind is "inn" then z = 2
      p = Crafty.e("HTML, Text, 2D, DOM, Mouse, Coordinates, Collision, Terrain, " + place.kind)
        .attr
          long: place.coordinates[0]
          lat: place.coordinates[1]
          mapx: x
          mapy: y
          z: z + ((x + y) * 5)
          sight: 0
        .collision(new Crafty.polygon([0, 72], [64, 40], [128, 72], [64, 105]))
        .css
          "font": "7pt Monaco"
          "text-align": "center"
          "line-height": "70px"
        .textColor("#000000", 0.9)
      p.checkvision()
      p = _.extend p, place
      p._element.className += " mapx#{x} mapy#{y}"
      isoMap.place x, y, 0, p
    console.log "Completed Places Gen"
            
  generateCharacters = (char) ->
    console.log "Beginning to generate Characters"
    [x, y] = c2t char.coordinates
    c = Crafty.e("2D, HTML, DOM, Mouse, Coordinates, Camera, Character, Solid, Slide," + char["gender"])
      .attr
        long: char.coordinates[0]
        lat: char.coordinates[1]
        mapx: x
        mapy: y
        z: 3 + (x + y) * 5
      .bind("DoubleClick", ->
        console.log "double clicked character"
        profile(@, "character") )
      # .css(
      #   "font": "7pt Monaco"
      #   "text-align": "center"
      #   "line-height": "140px" )
      # .textColor("#000000", 0.50)
    c = _.extend c, char
    isoMap.place x, y, 0, c
    camera = Crafty.e("Camera").camera c
    console.log "#{c.name} appeared at [#{x},#{y}]"
    makeportrait char, c
    c
  
  generateUser = (user) ->
    console.log "Beginning to generate Characters"
    [x, y] = c2t user.coordinates
    user = Crafty.e("2D, HTML, DOM, Mouse, Coordinates, cloud")
      .attr
        long: user["coordinates"][0]
        lat: user["coordinates"][1]
        mapx: x
        mapy: y
        z: 4 + (x + y) * 5
      .bind("Click", ->
        console.log "double clicked character" )
      .css(
        "font": "7pt Monaco"
        "text-align": "center"
        "line-height": "140px" )
    root.User = _.extend User, user
    isoMap.place x, y, 0, user
    console.log "User appeared at [#{x},#{y}]"
  
  makeportrait = (char, c) ->
    portraitslot = document.createElement("div")
    portraitslot.className = "portraitslot"
    portraitslot.id = "#{char.name}_portraitslot"
    portraitslot.innerHTML = "<div class='portrait' id=\"#{char.name}portrait\" style=\"background:url(#{char.portrait}) center center;\"></div>"
    scratch = document.createElement("canvas")
    scratch.className = "portraitbar"
    scratch.id = "#{char.name}_scratch"
    scratch.width = 110
    scratch.height = 110
    makebar scratch, char.scratch, char.scratchmax, true, "#8CFF9D"
    portraitslot.appendChild scratch
    mana = document.createElement("canvas")
    mana.className = "portraitbar"
    mana.id = "#{char.name}_mana"
    mana.width = 110
    mana.height = 110
    makebar mana, char.mana, char.manamax, false, "#8CDDFF"
    portraitslot.appendChild mana
    "footer".insert portraitslot
    
  makebar = (obj, v, max, direction, color) ->
    v = (max-v) / max
    if direction is true
      v = v + 0.51
    else
      if v >= 0.5
        v = 2 - (v - 0.48)
      else
        v = 0.5 - v
    v = v * Math.PI
    context = obj.getContext "2d"
    context.beginPath()
    context.arc(obj.width/2, obj.height/2, 49, v, 0.5 * Math.PI, direction)
    context.lineWidth = 7
    context.strokeStyle = color
    context.stroke()
    @
    
  c2t = (coordinates) ->
    x = parseFloat((coordinates[0] - Center[0]).toFixed 3) * 1000 + Delta
    y = parseFloat((coordinates[1] - Center[1]).toFixed 3) * 1000 
    [x, y]
  
  t2c = (tilepositions) ->
    x = parseFloat((Center[0] + (tilepositions[0] - Delta) / 1000).toFixed 3)
    y = parseFloat((Center[1] + tilepositions[1] / 1000).toFixed 3)
    [x, y]
    
  profile = (p, k) ->
    "menu".html("<ul>
        <div id='profilesummary'></div>
        <div id='profileinfo'></div>
        <li><button id='cancel' class='lui-button'>Close</button></li>
      </ul>
      <span class='arrow'></span>", "fade")
    if k is "character"
      "div#profilesummary".insert("<li class='pixel'>
        #{p.name}
      </li>")
      items(p)
    if k is "place" 
      "div#profilesummary".insert("<li class='pixel'>
        #{p.name}, #{p.kind}
        <div class='portrait' style=\"background:url(#{p.portrait}) center center;margin: 5px auto\"></div>
      </li>")
      store(p)
    "menu".show "fade"
    "div.portrait".onClick (event) ->
      current = "div#profileinfo".attr("class")
      if current == "stats" then items(p)
      else if current == "items"
        "div#equiped".remove()
        stats(p)
      else if current == "occupants" then store(p)
      else if current == "store" then occupants(p)

  occupants = (p) ->
    "div#profileinfo".html("
      <li>Occupants Overview</>
      <li>
        <div class='portrait' style=\"background:url(#{p.sprite()._image}) center center;margin: 5px auto\"></div>
        <button id='talk' class='lui-button'>Talk</button><
      </li>
      <li>
        <div class='portrait' style=\"background:url(#{p.sprite()._image}) center center;margin: 5px auto\"></div>
        <button id='talk' class='lui-button'>Talk</button>
      </li>
      ", "animate").attr "class", "occupants" 

  store = (p) ->
    $("div#profileinfo").html("<li><div id='forsale'></div></li>").attr "class", "store"
    for item in p.items
      e = Crafty.e("2D, DOM, item, " + item.portrait)
      e = _.extend e, item
      "div#forsale".insert "<div class='itemslot' data-droppable=\"{accept: 'div.itemportrait'}\"></div>"
    
  stats = (p) ->
    "div#profileinfo".clear()
    "div#profileinfo".insert "<li class='pixel'>#{p.xp}xp, #{p.spirit} spirit</li>"
    for stat in ["strength", "stamina", "dexterity", "intellegence", "intuition", "persuasion", "resolve"]
      "div#profileinfo".insert "<li class='pixel'><button id=\"#{p[stat]}\" class='lui-button '>#{stat} : #{p[stat]}</button></li>"
      "div#profileinfo".attr "class", "stats"

  items = (p) ->
    "div#profileinfo".html "<li class='pixel'>#{p.gold} gold</li><li><div id='equiped'></div></li><li><div id='inventory'></div></li>", "before"
    for slot in ["hand","head","neck","hand","finger","body","feet","finger"]
      "div#equiped".insert "<div class='itemslot', data-droppable=\"{accept: 'div.#{slot}'}\"></div>" 
    i=0
    while i <= p.carry
      "div#inventory".insert "<div class='itemslot' data-droppable=\"{accept: 'div.itemportrait'}\"></div>" 
      i++   
    itemarray = []
    for item in p.items
      e = Crafty.e("2D, DOM, item, " + item.portrait)
      e = _.extend e, item
      itemarray.push e
    for itemslot in $('div#inventory').children(".itemslot")
      break if itemarray.length <= 0
      item = itemarray.pop()
      i = $("#ent"+item[0])
      i.attr
        class: "itemportrait #{item.equipedlocation}"
      i.draggable {revert: true, revertDuration: 'short'}
      itemslot.insert i
      i[0].onMouseover (event) ->
        item = Crafty(parseInt(event.target._.id.slice(3)))
        "#tail".html("#{item.name}<br/>Quality: #{item.quality}<br/>Durability: #{item.durability}/#{item.durabilitymax}")
        if item.hasOwnProperty("effect")
          "#tail".insert "<br/>Charge: #{item.charge}/#{item.chargemax}"
          for effecttype, effect of item.effect
            "#tail".insert("<br/> #{effecttype}:#{effect["power"]} | Cost: #{effect["cost"]}")
        "#tail".position(event.pageX-75, event.pageY+5)
        "#tail".show()
      i[0].onMouseout (event) ->
        "#tail".hide()
    "div#profileinfo".attr "class", "items"
  
  dnd.Draggable.Options.dragstart = (event) ->
    "#tail".hide()
    
  dnd.Droppable.Options.drop = (event) ->
    event.target.highlight "green"
    # jujitsu move where i move where it is going to be to where I want it to go
    $(event.droppable).insert(event.draggable.__draggable._clone)
    # reset inheritance
    event.draggable.__draggable._clone._.style.top = event.droppable._.style.top
    event.draggable.__draggable._clone._.style.left = event.droppable._.style.left
        
  "#cancel".onClick (event) ->
    "menu".hide()
          
  loginform = ->
    new $.Form(id: 'loginform', method: 'get', action:'/user').insertTo "menu"
    "#loginform".insert("<ul><li id='new'></li><li id='log'></li><li id='lost'></li></ul>")
    new ui.Button("Begin Adventure!", 'type': 'submit').insertTo "#new"
    new $.Input('id': 'login', 'name': 'email', 'placeholder': 'your@email.com', 'type': 'email').insertTo "#log"
    new $.Input('id': 'password', 'name': 'password', 'placeholder': 'memorable phrase', 'type': 'password').insertTo "#log"
    new $.Input('name': 'coordinates', 'type': 'hidden', value: "[#{root.Longitude}, #{root.Latitude}]").insertTo "#log"
    new ui.Button("Login", 'type': 'submit').insertTo "#log"
    new ui.Button("I forgot my password...", 'type': 'submit').insertTo "#lost"
    root.Center = [Longitude, Latitude]
    "menu".show "fade"
    $("#loginform").remotize(
      success: ->
        console.log "login confirmed"
        "menu".hide "fade"
        root.User = @responseJSON["user"]
        generateUser User
        reveal User
        for char in @responseJSON["char"]
          reveal generateCharacters char)
  
  updateMap = (long, lat) ->
    unless updateinprogress
      console.log "trying to update maps"
      root.updateinprogress = true
      ajax.get "/location/",
        params:
          coordinates: [long, lat]
          negativecoordinates: maprendered
        success: ->
          console.log "Maps Response Recieved"
          response = @responseJSON
          _.each mapdata, (v, k) -> 
            mapdata[k] = _.union v, response[k]
          root.maprendered.push (coordinatesTo2 [long, lat]).toString()
          root.updateinprogress = false
        failure: ->
          console.log "Failed to Load Maps"
          root.updateinprogress = false
  
  checkforupdate = (coordinates) ->
    coordinates = coordinatesTo2 coordinates
    updateMap(coordinates[0], coordinates[1]) if coordinates.toString() not in maprendered
  
  coordinatesTo2 = (coordinates) ->
    coordinates.map (c) -> parseFloat(Math.ceil(c*100)/100)
    
  reveal = (entity, coordinatesBefore = undefined) ->
    exists = []
    nonexistant = []
    console.log "looking around"
    [exists, nonexistant] = selectarea [entity.mapx, entity.mapy], entity.vision
    if nonexistant.length > 0
      console.log "generating new tiles"
      generateTiles intersectionof nonexistant, mapdata.locations
      generatePlaces intersectionof nonexistant, mapdata.places
    unless coordinatesBefore
      console.log "showing tiles"
      toggleVisibility exists, +1
    else
      console.log "selecting visibility down tiles"
      exists2 = []
      [exists2, nonexistant] = selectarea coordinatesBefore, entity.vision
      crop = _.difference exists2, exists
      toggleVisibility crop, -1
      console.log "selecting visibility up tiles"
      crop = _.difference exists, exists2
      toggleVisibility crop, +1
      
  toggleVisibility = (selectedtile, delta) ->
    for tile in selectedtile
      for entry in $(tile)
        e = Crafty(parseInt((entry._.id).slice(3))) 
        e.sight += delta 
        e.trigger "checkforhide"
  
  selectarea = (coordinates, vision) ->
    range1 = [coordinates[0]-vision..coordinates[0]+vision]
    range2 = [coordinates[1]-vision..coordinates[1]+vision]
    exists = []
    nonexistant = []
    console.log "selecting area"
    for x in range1 by 1
      for y in range2 by 1
        t = $(".mapx#{x}.mapy#{y}")
        # t is an array of DOM elements, if there are no elements, you've reached the edge of what is visible.
        exists.push ".mapx#{x}.mapy#{y}"
        if t.length < 1
          nonexistant.push (t2c [x,y]).toString()
    [exists, nonexistant]
    
  intersectionof = (a, b) ->
    console.log "checking for intersections"
    (tile for tile in b when tile.coordinates.toString() in a)
  ###

                            C O S M I C  D R E A M

  ###
  $(document).on "ready", ->
    "input".onFocus ->
      Crafty.removeEvent @, "keydown", Crafty.keyboardDispatch
      Crafty.removeEvent @, "keyup", Crafty.keyboardDispatch
    "input".onBlur ->
      Crafty.addEvent @, "keydown", Crafty.keyboardDispatch
      Crafty.addEvent @, "keyup", Crafty.keyboardDispatch
      
    Crafty.scene "main", ->
      root.isoMap = Crafty.isometric2.init(128)
      root.Delta = Math.round(Math.sqrt(Math.pow(Crafty.viewport.width, 2) + Math.pow(Crafty.viewport.height, 2)) / 128)
      window.setInterval (->
        console.log "routining..."
        #initUser([x, y], "new")
        acquireGeo() unless Latitude or Longitude or Accuracy
        updateMap(Longitude, Latitude, 10) if _.isEmpty(mapdata.locations)
        loginform() if Latitude and Longitude and $("#loginform").length < 1 and not _.isEmpty(mapdata.locations) and not User
        #updateUser()
        #generateRandomMap map
        #updateWorld "Coordinates", "/location/"
      ), 2000

    Crafty.scene "loading", ->
      console.log "Loading..."
      Crafty.init()
      Crafty.canvas.init()
      # stage events
      Crafty.addEvent this, Crafty.stage.elem, "mousedown", (e) ->
         return if e.button > 1
         base =
           x: e.clientX
           y: e.clientY
         scroll = (e) ->
           dx = base.x - e.clientX
           dy = base.y - e.clientY
           base =
             x: e.clientX
             y: e.clientY
           Crafty.viewport.x -= dx
           Crafty.viewport.y -= dy      
         Crafty.addEvent this, Crafty.stage.elem, "mousemove", scroll
         Crafty.addEvent this, Crafty.stage.elem, "mouseup", ->
           Crafty.removeEvent this, Crafty.stage.elem, "mousemove", scroll
           
      Crafty.c "Camera",
        init: ->
        camera: (obj) ->
          @set obj
          that = this
          obj.bind "Moved", (location) ->
            that.set location
        set: (obj) ->
          Crafty.viewport.x = -obj.x - 64 + Crafty.viewport.width / 2 
          Crafty.viewport.y = -obj.y - 64  + Crafty.viewport.height / 2
          
      Crafty.c "Terrain",
        _sight: 0
        init: ->
        checkvision: () ->
          that = @
          @bind "checkforhide", ->
            if that.sight < 1
              that.visible = false
            else if that.sight > 0
              that.visible = true
            that.draw()

      Crafty.c "Coordinates",
        _coordinates: undefined
        _mapx: 0
        _mapy: 0 
        init: ->
                  
      Crafty.c "Character",
        _name: null
        _id: null
        _portrait: null
        _age: 0
        _gender: null
        _home: null
        _vision: 0
        _xp: 0 
        _abilities: null
        _status: null
        _scratch: 0
        _scratchmax: 0
        _wound: 0
        _woundmax: 0
        _injury: 0
        _mana: 0
        _manamax: 0
        _strength: 0 
        _dexterity: 0
        _stamina: 0
        _resolve: 0
        _intellegence: 0
        _intuition: 0
        _persuasion: 0
        _gold: null
        _reputation: null
        _arrogance: 0
        _caution: 0
        _greed: 0
        _indifference: 0
        _materialism: 0
        _stubbornness: 0
        _items: []

        _keys:
          UP_ARROW: [0, -1]
          DOWN_ARROW: [0, 1]
          RIGHT_ARROW: [1, 0]
          LEFT_ARROW: [-1, 0]
          W: [0, -1]
          S: [0, 1]
          D: [1, 0]
          A: [-1, 0]
        init: ->
          for k of @_keys
            keyCode = Crafty.keys[k] or k
            @_keys[keyCode] = @_keys[k]
            @bind "KeyDown", (e) ->
              if @_keys[e.key]
                direction = @_keys[e.key]
                @trigger "Slide", direction
                Crafty.trigger "Turn"
      Crafty.c "Slide",
      # Our slide component - listens for slide events
      # and smoothly slides to another tile location
        init: ->
          @_stepFrames = 8
          @_frames = 0
          @_tileSize = 128
          @_moving = false
          @_direction = [0,0]
          @_sourcemapXY = [0,0]
          @_sourceXY = [0,0]
          @_destXY = [0,0]
          @_deltaXY = [0,0]
          @bind("Slide", (d) ->
            # Don't continue to slide if we're already moving
            return false  if @_moving
            @_moving = true
            @_direction = d
            @_sourceXY = [@x, @y]
            @_sourcemapXY = [@mapx, @mapy]
            [@mapx, @mapy] = [@mapx + d[0], @mapy + d[1]]
            [@long, @lat] = t2c [@mapx, @mapy]
            @_destXY = _.toArray(isoMap.pos2px @mapx, @mapy)
            # Get our x and y velocity
            @_deltaXY[0] = (@_destXY[0] - @_sourceXY[0]) / @_stepFrames
            @_deltaXY[1] = (@_destXY[1] - @_sourceXY[1]) / @_stepFrames
            @_frames = @_stepFrames
          ).bind "EnterFrame", (e) ->
            # Don't continue to slide if we're already moving
            return false unless @_moving
            # If we're moving, update our position by our per-frame velocity
            if (@_direction[0] == 1 || @_direction[1] == 1)
              console.log "switch z immediately"
              @z = 4 + (@mapx + @mapy) * 5
            @x += @_deltaXY[0]
            @y += @_deltaXY[1]
            @_frames--
            if @_frames is 0
              # If we've run out of frames,
              # move us to our destination to avoid rounding errors.
              @_moving = false
              @x = @_destXY[0]
              @y = @_destXY[1]
              "menu".hide()
              "menu".clear()
              checkforupdate([@long, @lat])
              reveal @, @_sourcemapXY              
              if (@_direction[0] == -1 || @_direction[1] == -1) 
                console.log "switch z at end"
                @z = 4 + (@mapx + @mapy) * 5
              # check if you are out of the boundary
              # if so, send location request with the new area.
            @trigger "Moved",
              x: @x
              y: @y
        slideFrames: (frames) ->
          @_stepFrames = frames
          # A function we'll use later to 
          # cancel our movement and send us back to where we started
        cancelSlide: ->
          @x = @_sourceXY[0]
          @y = @_sourceXY[1]
          [@mapx, @mapy] = [@mapx - @_direction[0], @mapy - @_direction[1]]
          [@long, @lat] = t2c [@mapx, @mapy]
          @_moving = false
          @trigger "Moved",
            x: @x
            y: @y

      Crafty.c "Solid",
        init: ->
          @requires("Collision").collision(new Crafty.polygon([5, 72], [64, 43], [123, 72], [64, 100]))
          for solid in ["water", "waterfish"]
            @onHit solid, (obj) ->
              console.log "You can't walk on water"
              @cancelSlide()
          for solid in ["forestmushroom", "forestfruit"]
            @onHit solid, (obj) ->
              console.log "you should display a dialog for foraging"
          for place in ["shack", "house", "farm", "smith", "inn", "academy", "fortress"]
            @onHit place, (obj) ->
              profile(obj[obj.length-1].obj, "place") unless "menu".children().length

      Crafty.c "AStar",
        _compareNode: (node1, node2) ->
          return false  unless node1.tile[0] is node2.tile[0]
          true

        _nodeInArray: (node, array) ->
          for i of array
            return true  if @_compareNode(node, array[i])
          false

        _heuristic: `undefined`
        heuristic: (f) ->
          @_heuristic = f
          this

        _findAdjacent: `undefined`
        findAdjacent: (f) ->
          @_findAdjacent = f
          this

        findPath: (ignore, weighted, begining, end) ->
          Node = (tile, parent, g, h, f) ->
            @tile = tile
            @parent = parent
            @g = g
            @h = h
            @f = f
          throw ("Exception: You have to declare a heuristic and an adjacent function")  if @_heuristic is `undefined` or @_findAdjacent is `undefined`
          start = new Node(begining, -1, -1, -1, -1)
          destination = new Node(end, -1, -1, -1, -1)
          open = []
          closed = []
          g = 0
          h = @_heuristic(start.tile, destination.tile)
          f = g + h
          open.push start
          while open.length > 0
            open.sort (a, b) ->
              x = a.f
              y = b.f
              (if (x < y) then -1 else ((if (x > y) then 1 else 0)))
            current_node = open[0]
            if @_compareNode(current_node, destination)
              path = [destination.tile]
              until current_node.parent is -1
                current_node = closed[current_node.parent]
                path.unshift current_node.tile
              return path
            open.shift()
            closed.push current_node
            adj = @_findAdjacent(current_node.tile)
            for i of adj
              continue  if @_nodeInArray(new Node(adj[i]), closed)
              if ignore is `undefined` or not ignore(current_node.tile, adj[i])
                unless @_nodeInArray(new Node(adj[i]), open)
                  new_node = new Node(adj[i], closed.length - 1, -1, -1, -1)
                  new_node.g = 0
                  new_node.g += weighted(current_node.tile, new_node.tile)  unless weighted is `undefined`
                  new_node.h = @_heuristic(new_node.tile, destination.tile)
                  new_node.f = new_node.g + new_node.h
                  open.push new_node
                  
          []
      
      # preload sprites
      Crafty.load ["images/terrainsprites.png", "images/resources.png", "images/charsprites.gif", "images/buildingsprites.png", "images/equipment&abilities.png"], ->
        Crafty.sprite 128, "images/terrainsprites.png",
          grass1: [0, 0, 1, 1] 
          grass2: [1, 0, 1, 1] 
          grass3: [2, 0, 1, 1] 
          grass4: [3, 0, 1, 1]
          forest1: [0, 1, 1, 1] 
          forest2: [1, 1, 1, 1] 
          forest3: [2, 1, 1, 1] 
          forest4: [3, 1, 1, 1]
          forest5: [0, 2, 1, 1]
          forestdeep: [1, 2, 1, 1]
          forestfruit: [2, 2, 1, 1]
          forestmushroom: [3, 2, 1, 1]
          forestcleared1: [0, 3, 1, 1]
          forestcleared2: [1, 3, 1, 1]
          waterfish: [2, 3, 1, 1]
          water: [3, 3, 1, 1]
        Crafty.sprite 32, "images/resources.png",
          food: [0, 0, 1, 1]
          lumber: [1, 0, 1, 1]
          ore: [2, 0, 1, 1]
          gold: [3, 0, 1, 1]
          rep: [4, 0, 1, 1]
        Crafty.sprite 110, "images/charsprites.gif",
          m: [0, 0, 1, 1]
          f: [0, 0, 1, 1]
        Crafty.sprite 128, "images/buildingsprites.png",
          shack: [0, 0, 1, 1]
          house: [1, 0, 1, 1]
          inn: [2, 0, 1, 1]
          village: [3, 0, 1, 1]
          smith: [0, 1, 1, 1]
          farm: [1, 1, 1, 1]
          townhall: [2, 1, 1, 1]
          fortress: [3, 1, 1, 1]
          field: [0, 2, 1, 1]
          field2: [1, 2, 1, 1]
          cloud: [2, 2, 1, 1]
        Crafty.sprite 34, "images/equipment&abilities.png",
          apple: [0, 0, 1, 1]
          orange: [1, 0, 1, 1]
          mushroom: [2, 0, 1, 1]
          carrot: [3, 0, 1, 1]
          potato: [4, 0, 1, 1]
          fish: [5, 0, 1, 1]
          egg: [6, 0, 1, 1]
          bread: [7, 0, 1, 1]
          pie: [8, 0, 1, 1]
          cheese: [9, 0, 1, 1]
          meat: [10, 0, 1, 1]
          sausage: [11, 0, 1, 1]
          poison: [12, 0, 1, 1]
          wine: [13, 0, 1, 1]
          
          sword1: [0, 3, 1, 1]
          sword2: [1, 3, 1, 1]
          sword3: [2, 3, 1, 1]
          sword4: [3, 3, 1, 1]
          sword5: [4, 3, 1, 1]
          sword6: [5, 3, 1, 1]
          sword7: [6, 3, 1, 1]
          bastard1: [7, 3, 1, 1]
          bastard2: [8, 3, 1, 1]
          bastard3: [9, 3, 1, 1]
          bastard4: [10, 3, 1, 1]
          bastard5: [11, 3, 1, 1]
          bastard6: [12, 3, 1, 1]
          bastard7: [13, 3, 1, 1]

          dagger1: [0, 4, 1, 1]
          dagger2: [1, 4, 1, 1]
          dagger3: [2, 4, 1, 1]
          dagger4: [3, 4, 1, 1]
          dagger5: [4, 4, 1, 1]
          dagger6: [5, 4, 1, 1]
          dagger7: [6, 4, 1, 1]
          katara1: [7, 4, 1, 1]
          katara2: [8, 4, 1, 1]
          katara3: [9, 4, 1, 1]
          katara4: [10, 4, 1, 1]
          katara5: [11, 4, 1, 1]
          katara6: [12, 4, 1, 1]
          katara7: [13, 4, 1, 1]
          
          spear1: [0, 5, 1, 1]
          spear2: [1, 5, 1, 1]
          spear3: [2, 5, 1, 1]
          spear4: [3, 5, 1, 1]
          spear5: [4, 5, 1, 1]
          spear6: [5, 5, 1, 1]
          spear7: [6, 5, 1, 1]
          lance1: [7, 5, 1, 1]
          lance2: [8, 5, 1, 1]
          lance3: [9, 5, 1, 1]
          lance4: [10, 5, 1, 1]
          lance5: [11, 5, 1, 1]
          lance6: [12, 5, 1, 1]
          lance7: [13, 5, 1, 1]
          
          wand1: [0, 6, 1, 1]
          wand2: [1, 6, 1, 1]
          wand3: [2, 6, 1, 1]
          wand4: [3, 6, 1, 1]
          wand5: [4, 6, 1, 1]
          wand6: [7, 6, 1, 1]
          wand7: [6, 6, 1, 1]
          staff1: [7, 6, 1, 1]
          staff2: [8, 6, 1, 1]
          staff3: [9, 6, 1, 1]
          staff4: [10, 6, 1, 1]
          staff5: [11, 6, 1, 1]
          staff6: [12, 6, 1, 1]
          staff7: [13, 6, 1, 1]
          
          handaxe1: [0, 7, 1, 1]
          handaxe2: [1, 7, 1, 1]
          handaxe3: [2, 7, 1, 1]
          handaxe4: [3, 7, 1, 1]
          handaxe5: [4, 7, 1, 1]
          handaxe6: [5, 7, 1, 1]
          handaxe7: [6, 7, 1, 1]
          greataxe1: [7, 7, 1, 1]
          greataxe2: [8, 7, 1, 1]
          greataxe3: [9, 7, 1, 1]
          greataxe4: [10, 7, 1, 1]
          greataxe5: [11, 7, 1, 1]
          greataxe6: [12, 7, 1, 1]
          greataxe7: [13, 7, 1, 1]
          
          bow1: [0, 8, 1, 1]
          bow2: [1, 8, 1, 1]
          bow3: [2, 8, 1, 1]
          bow4: [3, 8, 1, 1]
          bow5: [4, 8, 1, 1]
          bow6: [5, 8, 1, 1]
          bow7: [6, 8, 1, 1]
          composite1: [7, 8, 1, 1]
          composite2: [8, 8, 1, 1]
          composite3: [9, 8, 1, 1]
          composite4: [10, 8, 1, 1]
          composite5: [11, 8, 1, 1]
          composite6: [12, 8, 1, 1]
          composite7: [13, 8, 1, 1]
          
          lightshield1: [0, 9, 1, 1]
          lightshield2: [1, 9, 1, 1]
          lightshield3: [2, 9, 1, 1]
          lightshield4: [3, 9, 1, 1]
          lightshield5: [4, 9, 1, 1]
          lightshield6: [5, 9, 1, 1]
          lightshield7: [6, 9, 1, 1]
          heavyshield1: [7, 9, 1, 1]
          heavyshield2: [8, 9, 1, 1]
          heavyshield3: [9, 9, 1, 1]
          heavyshield4: [10, 9, 1, 1]
          heavyshield5: [11, 9, 1, 1]
          heavyshield6: [12, 9, 1, 1]
          heavyshield7: [13, 9, 1, 1]
          
          dress1: [0, 10, 1, 1]
          dress2: [1, 10, 1, 1]
          shirt1: [2, 10, 1, 1]
          shirt2: [3, 10, 1, 1]
          shirt3: [4, 10, 1, 1]
          shirt4: [5, 10, 1, 1]
          shirt5: [6, 10, 1, 1]
          hat1: [7, 10, 1, 1]
          hat2: [8, 10, 1, 1]
          hat3: [9, 10, 1, 1]
          helmet1: [10, 10, 1, 1]
          helmet2: [11, 10, 1, 1]
          helmet3: [12, 10, 1, 1]
          helmet4: [13, 10, 1, 1]
          
          robe1: [0, 11, 1, 1]
          robe2: [1, 11, 1, 1]
          robe3: [2, 11, 1, 1]
          robe4: [3, 11, 1, 1]
          robe5: [4, 11, 1, 1]
          robe6: [5, 11, 1, 1]
          robe7: [6, 11, 1, 1]
          armor1: [7, 11, 1, 1]
          armor2: [8, 11, 1, 1]
          armor3: [9, 11, 1, 1]
          armor4: [10, 11, 1, 1]
          armor5: [11, 11, 1, 1]
          armor6: [12, 11, 1, 1]
          armor7: [13, 11, 1, 1]
          
          feet1: [0, 12, 1, 1]
          feet2: [1, 12, 1, 1]
          feet3: [2, 12, 1, 1]
          feet4: [3, 12, 1, 1]
          feet5: [4, 12, 1, 1]
          feet6: [5, 12, 1, 1]
          feet7: [6, 12, 1, 1]
          hand1: [7, 12, 1, 1]
          hand2: [8, 12, 1, 1]
          hand3: [9, 12, 1, 1]
          hand4: [10, 12, 1, 1]
          hand5: [11, 12, 1, 1]
          hand6: [12, 12, 1, 1]
          hand7: [13, 12, 1, 1]
          
          quartz: [0, 13, 1, 1]
          amethyst: [1, 13, 1, 1]
          emerald: [2, 13, 1, 1]
          ruby: [3, 13, 1, 1]
          sapphire: [4, 13, 1, 1]
          diamond: [5, 13, 1, 1]
          topaz: [6, 13, 1, 1]
          bag1: [7, 13, 1, 1]
          bag2: [8, 13, 1, 1]
          bag3: [9, 13, 1, 1]
          bag4: [10, 13, 1, 1]
          package1: [11, 13, 1, 1]
          package2: [12, 13, 1, 1]
          chest: [13, 13, 1, 1]

          note1: [0, 14, 1, 1]
          note2: [1, 14, 1, 1]
          note3: [2, 14, 1, 1]
          ward: [3, 14, 1, 1]
          warrant: [4, 14, 1, 1]
          letter: [5, 14, 1, 1]
          invitation: [6, 14, 1, 1]
          journal1: [7, 14, 1, 1]
          journal2: [8, 14, 1, 1]
          scroll1: [9, 14, 1, 1]
          scroll3: [10, 14, 1, 1]
          scroll4: [11, 14, 1, 1]
          contract: [12, 14, 1, 1]
          map: [13, 14, 1, 1]

          book1: [0, 15, 1, 1]
          book2: [1, 15, 1, 1]
          book3: [2, 15, 1, 1]
          book4: [3, 15, 1, 1]
          book5: [4, 15, 1, 1]
          book6: [5, 15, 1, 1]
          book7: [6, 15, 1, 1]
          key1: [7, 15, 1, 1]
          key2: [8, 15, 1, 1]
          key3: [9, 15, 1, 1]
          key4: [10, 15, 1, 1]
          key5: [11, 15, 1, 1]
          key6: [12, 15, 1, 1]
          key7: [13, 15, 1, 1]

          ring1: [0,16, 1, 1]
          ring2: [1,16, 1, 1]
          ring3: [2,16, 1, 1]
          ring4: [3,16, 1, 1]
          ring5: [4,16, 1, 1]
          ring6: [5,16, 1, 1]
          ring7: [6,16, 1, 1]
          neck1: [7,16, 1, 1]
          neck2: [8,16, 1, 1]
          neck3: [9,16, 1, 1]
          neck4: [10,16, 1, 1]
          neck5: [11,16, 1, 1]
          neck6: [12,16, 1, 1]
          neck7: [13,16, 1, 1]
          
      Crafty.scene "main"  
    Crafty.scene "loading"
      
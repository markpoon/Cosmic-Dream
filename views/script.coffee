useGeolocation = (position) ->
  window.longitude = position.coords.longitude.toFixed 3
  window.latitude = position.coords.latitude.toFixed 3 

onGeolocationError = (error) ->
  alert "Geolocation error - code: " + error.code + " message : " + error.message
  
Lovely ["dom-1.2.0", "fx-1.0.3", "ui-2.0.1", "ajax-1.1.2", "sugar-1.0.3", "glyph-icons-1.0.2", "killie-1.0.0"], ($, fx, ui, ajax) ->  
  sendLocation = (lat, long) ->
    ajax.get "/location/",
      params:
        coordinate: [lat, long]
      success: ->
        alert "Successfully found Locations"
      failure: ->
        alert "Could not call upon Locations"
      complete: ->
        alert "Finding Locations Complete"
  
  $(document).on "ready", ->
    if Modernizr.geolocation
      navigator.geolocation.getCurrentPosition useGeolocation, onGeolocationError
    else
      alert "Geolocation is not supported."
    Crafty.init()
    Crafty.c "Coordinates",
      _lat = 0
      _long = 0
      init: ->
        @defineGetter @, "lat", (-> 
          @_lat)
        @defineSetter @, (v) -> 
          @_lat = v
        @defineGetter @, "long", (-> 
          @_long)
        @defineSetter @, (v) -> 
          @_long = v
    Crafty.sprite 128, "images/terrainsprite.png",
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
      
    Crafty.scene "loading", ->
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
      Crafty.load ["images/terrainsprite.png", "images/charsprites.png"], ->
        Crafty.scene "main"
        
    Crafty.scene "main", ->
      land = ["bingo", "grass1", "grass2", "grass1", "grass3", "grass1", "grass4", "grass1", "bingo"]
      forest = ["forest1", "forest2", "forest3", "forest4", "forest5"]
      deepforest = ["forestdeep", "forestfruit", "forestfruit", "forestmushroom"]
      water = ["water", "water", "waterfish"]
      tiles = []
      iso = Crafty.isometric.size(128)
      area = iso.area();
      y = area.y.start
      while y <= area.y.end
        x = area.x.start
        while x <= area.x.end
          terrain = Crafty.math.randomElementOfArray land
          if terrain is "bingo"
            t = _.union forest, deepforest, water
            terrain = Crafty.math.randomElementOfArray t
          deltaLong = Math.round(area.x.end / 2 - x)
          deltaLat = Math.round(area.y.end / 2 - y)
          # Terrain, Lat, Long
          tile = Crafty.e("2D, DOM, Mouse, Text, Coordinates, " + terrain)
            .attr(
              z: x + 1 * y + 1
              long: (window.longitude * 1000 + deltaLong) / 1000
              lat: (window.latitude * 1000 + deltaLat) / 1000) 
            .areaMap([64, 32], [128, 64], [128, 96], [64, 128], [0, 96], [0, 64])
            .css(
              "font": "7pt Monaco"
              "text-align": "center"
              "vertical-align": "bottom"
            )
            .textColor("#CCC", 0.8)
            .bind("MouseUp", (e) ->
              if e.mouseButton is Crafty.mouseButtons.RIGHT 
                @destroy())
            .bind("MouseOver", ->
              @.y -= 16)
            .bind("MouseOut", ->
              @.y += 16)
          tile.text ->
            "#{tile.long}, #{tile.lat}"
          iso.place x, y, 0, tile
          tile2 = 
            lat: (window.longitude * 1000 + deltaLong) / 1000
            long: (window.latitude * 1000 + deltaLat) / 1000
            terrain: terrain
            x: x
            y: y
          tiles.push tile2
          x++
        y++
      iso.place 0, 0, 0, Crafty.e("2D, DOM, Mouse, Coordiantes, ")
      console.log tiles
      
    Crafty.scene "loading"
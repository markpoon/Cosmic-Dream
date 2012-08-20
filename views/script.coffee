Lovely ["dom-1.2.0", "sugar-1.0.3", "fx-1.0.3", "ui-2.0.1", "ajax-1.1.2", "glyph-icons-1.0.2", "killie-1.0.0"], ($, fx, ui, ajax) ->  

  useGeolocation = (position) ->
    latitude = position.coords.latitude.toFixed 3
    longitude = position.coords.longitude.toFixed 3
    "#latitude".html latitude
    "#longitude".html longitude
#     ajax.post "user/resturl",
#     success ->
#     failure ->
#     complete ->
  onGeolocationError = (error) ->
    alert "Geolocation error - code: " + error.code + " message : " + error.message
  
  loadGame = ->
    Crafty.init()
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
    land = ["bingo", "grass1", "grass1", "grass2", "grass1", "grass3", "grass1", "grass4", "grass1", "bingo"]
    forest = ["forest1", "forest2", "forest3", "forest4", "forest5"]
    deepforest = ["forestdeep", "forestfruit", "forestfruit", "forestmushroom"]
    water = ["water", "water", "waterfish"]

    iso = Crafty.isometric.size(128)
    
    i = 5
    while i >= 0
      y = 0
      while y < 20
        terrain = Crafty.math.randomElementOfArray land
        if terrain is "bingo"
          t = _.union forest, deepforest, water
          terrain = Crafty.math.randomElementOfArray t
        tile = Crafty.e("2D, DOM, Mouse, " + terrain)
          .attr("z", i + 1 * y + 1)
          .areaMap([64, 0], [128, 32], [128, 96], [64, 128], [0, 96], [0, 32])
          .bind("MouseUp", (e) ->
            if e.mouseButton is Crafty.mouseButtons.RIGHT 
              @destroy())
          .bind("MouseOver", ->
            @.y -= 32)
          .bind("MouseOut", ->
            @.y += 32)
        iso.place i, y, 0, tile
        y++
      i--
    Crafty.addEvent this, Crafty.stage.elem, "mousedown", (e) ->
      return  if e.button > 1
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
  
  $(document).on "ready", ->
    if Modernizr.geolocation
      navigator.geolocation.getCurrentPosition useGeolocation, onGeolocationError
    else
      alert "Geolocation is not supported."
    loadGame()

###

Crafty.hexIso
category 2D
Place entities in a 45deg hex isometric fashion. It is similar to isometric but has another grid locations
###
Crafty.extend hexIso:
  _tile:
    width: 0
    height: 0
    side: 0

  _map:
    i: 0
    j: 0

  _origin:
    x: 0
    y: 0

  
  ###
  
  Crafty.hexIso.init
  comp Crafty.hexIso
  sign public this Crafty.hexIso.init(Number tileWidth,Number tileHeight,Number mapWidth,Number mapHeight)
  param tileRadius - The size of base tile width in Pixel
  param mapRadius - The radius of whole map in Tiles
  
  Method used to initialize the size of the isometric placement.
  Recommended to use a size values in the power of `2` (128, 64 or 32).
  This makes it easy to calculate positions and implement zooming.
  
  example
  ~~~
  var iso = Crafty.hexIso.init(64,128,20,20);
  ~~~
  
  see Crafty.hexIso.place
  ###
  init: (tileradius, mapradius, ) ->
    tr = parseInt(tr)
    @_tile.width = tr * 2
    @_tile.height = tr * Math.sqrt(3) 
    @_tile.side = tr * 3 / 2
    
    mr = parseInt(mr)
    @_tile.r = @_tile.width / @_tile.height
    @_map.width = parseInt(mw)
    @_map.height = parseInt(mh) or parseInt(mw)
    @_origin.x = @_map.height * @_tile.width / 2

  
  ###
  
  Crafty.hexIso.place
  comp Crafty.hexIso
  sign public this Crafty.hexIso.place(Entity tile,Number x, Number y, Number layer)
  param x - The `x` position to place the tile
  param y - The `y` position to place the tile
  param layer - The `z` position to place the tile (calculated by y position * layer)
  param tile - The entity that should be position in the isometric fashion
  
  Use this method to place an entity in an isometric grid.
  
  example
  ~~~
  var iso = Crafty.hexIso.init(64,128,20,20);
  isos.place(Crafty.e('2D, DOM, Color').color('red').attr({w:128, h:128}),1,1,2);
  ~~~
  
  see Crafty.hexIso.size
  ###
  hack: ->
    console.log "custom command"
  
  place: (i, j, z, obj) ->
    pos = @pos2px(i, j)
    layer = 1  unless layer
    marginX = 0
    marginY = 0
    if obj.__margin isnt `undefined`
      marginX = obj.__margin[0]
      marginY = obj.__margin[1]
    obj.x = pos.left + (marginX)
    obj.y = (pos.top + marginY) - obj.h
    obj.z = (pos.top) * layer

  centerAt: (x, y) ->
    pos = @pos2px(x, y)
    Crafty.viewport.x = -pos.left + Crafty.viewport.width / 2 - @_tile.width
    Crafty.viewport.y = -pos.top + Crafty.viewport.height / 2

  area: (offset) ->
    offset = 0  unless offset
    
    #calculate the corners
    vp = Crafty.viewport.rect()
    ow = offset * @_tile.width
    oh = offset * @_tile.height
    vp._x -= (@_tile.width / 2 + ow)
    vp._y -= (@_tile.height / 2 + oh)
    vp._w += (@_tile.width / 2 + ow)
    vp._h += (@_tile.height / 2 + oh)
    
    #  Crafty.viewport.x = -vp._x;
    #            Crafty.viewport.y = -vp._y;    
    #            Crafty.viewport.width = vp._w;
    #            Crafty.viewport.height = vp._h;   
    grid = []
    y = vp._y
    yl = (vp._y + vp._h)

    while y < yl
      x = vp._x
      xl = (vp._x + vp._w)

      while x < xl
        row = @px2pos(x, y)
        grid.push [~~row.x, ~~row.y]
        x += @_tile.width / 2
      y += @_tile.height / 2
    grid

  pos2px: (i, j) ->
    x = i * @_tile.side
    y = j * @_tile.height + i%2 * @_tile.height / 2
    left: ((i - j) * @_tile.width / 2 + @_origin.x)
    top: ((i + j) * @_tile.height / 2)

  px2pos: (left, top) ->
    x = (left - @_origin.x) / @_tile.r
    x: ((top + x) / @_tile.height)
    y: ((top - x) / @_tile.height)

  polygon: (obj) ->
    obj.requires "Collision"
    marginX = 0
    marginY = 0
    if obj.__margin isnt `undefined`
      marginX = obj.__margin[0]
      marginY = obj.__margin[1]
    points = [[marginX - 0, obj.h - marginY - @_tile.height / 2], [marginX - @_tile.width / 2, obj.h - marginY - 0], [marginX - @_tile.width, obj.h - marginY - @_tile.height / 2], [marginX - @_tile.width / 2, obj.h - marginY - @_tile.height]]
    poly = new Crafty.polygon(points)
    poly

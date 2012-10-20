$i = (id) ->
  document.getElementById id
$r = (parent, child) ->
  (document.getElementById(parent)).removeChild document.getElementById(child)
$t = (name) ->
  document.getElementsByTagName name
$c = (code) ->
  String.fromCharCode code
$h = (value) ->
  ("0" + Math.max(0, Math.min(255, Math.round(value))).toString(16)).slice -2
_i = (id, value) ->
  $t("div")[id].innerHTML += value
_h = (value) ->
  (if not hires then value else Math.round(value / 2))
get_screen_size = ->
  w = document.documentElement.clientWidth
  h = document.documentElement.clientHeight
  Array w, h
init = ->
  a = 0
  i = 0

  while i < n
    star[i] = new Array(5)
    star[i][0] = Math.random() * w * 2 - x * 2
    star[i][1] = Math.random() * h * 2 - y * 2
    star[i][2] = Math.round(Math.random() * z)
    star[i][3] = 0
    star[i][4] = 0
    i++
  starfield = $i("starfield")
  starfield.style.position = "absolute"
  starfield.width = w
  starfield.height = h
  context = starfield.getContext("2d")
  
  #context.lineCap='round';
  context.fillStyle = "rgb(0,0,0)"
  context.strokeStyle = "rgb(255,255,255)"
  adsense = $i("adsense")
  adsense.style.left = Math.round((w - 728) / 2) + "px"
  adsense.style.top = (h - 15) + "px"
  adsense.style.width = 728 + "px"
  adsense.style.height = 15 + "px"
  adsense.style.display = "block"
anim = ->
  mouse_x = cursor_x - x
  mouse_y = cursor_y - y
  context.fillRect 0, 0, w, h
  i = 0

  while i < n
    test = true
    star_x_save = star[i][3]
    star_y_save = star[i][4]
    star[i][0] += mouse_x >> 4
    if star[i][0] > x << 1
      star[i][0] -= w << 1
      test = false
    if star[i][0] < -x << 1
      star[i][0] += w << 1
      test = false
    star[i][1] += mouse_y >> 4
    if star[i][1] > y << 1
      star[i][1] -= h << 1
      test = false
    if star[i][1] < -y << 1
      star[i][1] += h << 1
      test = false
    star[i][2] -= star_speed
    if star[i][2] > z
      star[i][2] -= z
      test = false
    if star[i][2] < 0
      star[i][2] += z
      test = false
    star[i][3] = x + (star[i][0] / star[i][2]) * star_ratio
    star[i][4] = y + (star[i][1] / star[i][2]) * star_ratio
    if star_x_save > 0 and star_x_save < w and star_y_save > 0 and star_y_save < h and test
      context.lineWidth = (1 - star_color_ratio * star[i][2]) * 2
      context.beginPath()
      context.moveTo star_x_save, star_y_save
      context.lineTo star[i][3], star[i][4]
      context.stroke()
      context.closePath()
    i++
  timeout = setTimeout("anim()", fps)
move = (evt) ->
  evt = evt or event
  cursor_x = evt.pageX - canvas_x
  cursor_y = evt.pageY - canvas_y
key_manager = (evt) ->
  evt = evt or event
  key = evt.which or evt.keyCode
  
  #ctrl=evt.ctrlKey;
  switch key
    when 27
      flag = (if flag then false else true)
      if flag
        timeout = setTimeout("anim()", fps)
      else
        clearTimeout timeout
    when 32
      star_speed_save = (if (star_speed isnt 0) then star_speed else star_speed_save)
      star_speed = (if (star_speed isnt 0) then 0 else star_speed_save)
    when 13
      context.fillStyle = "rgba(0,0,0," + opacity + ")"
  top.status = "key=" + ((if (key < 100) then "0" else "")) + ((if (key < 10) then "0" else "")) + key
release = ->
  switch key
    when 13
      context.fillStyle = "rgb(0,0,0)"
mouse_wheel = (evt) ->
  evt = evt or event
  delta = 0
  if evt.wheelDelta
    delta = evt.wheelDelta / 120
  else delta = -evt.detail / 3  if evt.detail
  star_speed += (if (delta >= 0) then -0.2 else 0.2)
  evt.preventDefault()  if evt.preventDefault
start = ->
  resize()
  anim()
resize = ->
  w = parseInt((if (url.indexOf("w=") isnt -1) then url.substring(url.indexOf("w=") + 2, (if ((url.substring(url.indexOf("w=") + 2, url.length)).indexOf("&") isnt -1) then url.indexOf("w=") + 2 + (url.substring(url.indexOf("w=") + 2, url.length)).indexOf("&") else url.length)) else get_screen_size()[0]))
  h = parseInt((if (url.indexOf("h=") isnt -1) then url.substring(url.indexOf("h=") + 2, (if ((url.substring(url.indexOf("h=") + 2, url.length)).indexOf("&") isnt -1) then url.indexOf("h=") + 2 + (url.substring(url.indexOf("h=") + 2, url.length)).indexOf("&") else url.length)) else get_screen_size()[1]))
  x = Math.round(w / 2)
  y = Math.round(h / 2)
  z = (w + h) / 2
  star_color_ratio = 1 / z
  cursor_x = x
  cursor_y = y
  init()
url = document.location.href
flag = true
test = true
n = parseInt((if (url.indexOf("n=") isnt -1) then url.substring(url.indexOf("n=") + 2, (if ((url.substring(url.indexOf("n=") + 2, url.length)).indexOf("&") isnt -1) then url.indexOf("n=") + 2 + (url.substring(url.indexOf("n=") + 2, url.length)).indexOf("&") else url.length)) else 512))
w = 0
h = 0
x = 0
y = 0
z = 0
star_color_ratio = 0
star_x_save = undefined
star_y_save = undefined
star_ratio = 256
star_speed = 4
star_speed_save = 0
star = new Array(n)
color = undefined
opacity = 0.1
cursor_x = 0
cursor_y = 0
mouse_x = 0
mouse_y = 0
canvas_x = 0
canvas_y = 0
canvas_w = 0
canvas_h = 0
context = undefined
key = undefined
ctrl = undefined
timeout = undefined
fps = 0
document.onmousemove = move
document.onkeypress = key_manager
document.onkeyup = release
document.onmousewheel = mouse_wheel
window.addEventListener "DOMMouseScroll", mouse_wheel, false  if window.addEventListener
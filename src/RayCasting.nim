import sdl2, math

# My own type for creating Vectors 
type
  V_type = enum
    v_int, # vector components are int
    v_float # vector components are float
  Vector2 = ref V_obj
  V_obj = object
    case type : V_type
    of v_int : intX, intY : int
    of v_float : floatX, floatY : float

# ------ SDL2 CONF ------ 

discard sdl2.init(INIT_EVERYTHING)

var
  window : WindowPtr
  render : RendererPtr

window = createWindow("NIM RayCasting",SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480, SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync)


var
  evt = sdl2.defaultEvent
  runGame = true

# ------ GAME DATA ------
#[ Map Meaning:
  0 -> No wall
  Other -> Wall (each number is a color)
]#
var worldMap =[
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
  [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1],
  [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

var
  pos = Vector2(type : v_float, floatX : 22, floatY : 12) 
  dir = Vector2(type: v_float, floatX : -1, floatY : 0)
  plane = Vector2(type : v_float, floatX : 0, floatY : 0.66)
  time : uint32 = 0 
  oldTime : uint32 = 0 

  color : array[4, int] = [0,0,0,0] # Array to store colors in rgba format

# ------ MAIN LOOP ------

while runGame:
  # Set color to black
  render.setDrawColor(0,0,0,255)
  # Clear the entire screen black
  render.clear
  # RayCasting loop
  for x in 0..640:
    var
      cameraX : float = 2 * x / 640 - 1 # x coordinate in camera space
      # Calculate Ray Direction
      rayDir = Vector2(type : v_float, floatX : dir.floatX + plane.floatX * cameraX, floatY : dir.floatY + plane.floatY * cameraX)
      # Which square of the map the ray is in
      map = Vector2(type : v_int, intX : int pos.floatX, intY : int pos.floatY)
      # Length of the ray from current position to next x or y side
      sideDist  = Vector2(type: v_float, floatX : 0 , floatY : 0)
      # Length of the ray from one x or y side to next x or y side
      deltaDist = Vector2(type : v_float, floatX : abs(1/rayDir.floatX), floatY : abs(1/rayDir.floatY))
      perpWallDist : float32 # var to calcule length of the ray layer
      # Which direction must the ray move in (+1 or -1)
      step = Vector2(type : v_int, intX : 0, intY : 0)
      hit : int = 0 # true(1) when the ray hit a wall 
      side : int # indicates if the ray hit a X side (0) or if a Y side(1) of a wall has been hit 

    # Calculate step and sideDist                                     
    if rayDir.floatX < 0:
      step.intX = -1
      sideDist.floatX = (pos.floatX - float map.intX) * deltaDist.floatX
    else:
      step.intX = 1
      sideDist.floatX = (float(map.intX) + 1.0 - pos.floatX) * deltaDist.floatX

    if rayDir.floatY < 0:
      step.intY = -1
      sideDist.floatY = (pos.floatY - float map.intY) * deltaDist.floatY
    else:
      step.intY = 1
      sideDist.floatY = (float(map.intY) + 1.0 - pos.floatY) * deltaDist.floatY

    # DDA Algorithm
    while hit == 0:
      if sideDist.floatX < sideDist.floatY:
        sideDist.floatX += deltaDist.floatX 
        map.intX += step.intX
        side = 0
      else:
        sideDist.floatY += deltaDist.floatY
        map.intY += step.intY
        side = 1

      if worldMap[map.intX][map.intY] > 0 : hit = 1

    if side == 0:
      perpWallDist = (float(map.intX) - pos.floatX + (1 - step.intX) / 2) / rayDir.floatX
    else:
      perpWallDist = (float(map.intY) - pos.floatY + (1 - step.intY) / 2) / rayDir.floatY

    var lineHeight : int = int(480 / perpWallDist)
    var drawStart : int = int(-lineHeight / 2 + 480 / 2)
    
    if drawStart < 0: drawStart = 0

    var drawEnd : int = int(lineHeight / 2 + 480 / 2)
    if drawEnd >= 480: drawEnd = 480 - 1

    case worldMap[map.intX][map.intY]
    of 1: color = [245,66,66,255] # Rojo
    of 2: color = [66,255,95,255] # Verde
    of 3: color = [66,81,245,255] # Azul
    of 4: color = [255,255,255,255] # Blanco
    else: color = [255,165,0,255] # Naranja

    if side == 1:
      for i in 0..2: # Change brigthness of the color
        color[i] = int32(color[i] / 2)

    render.setDrawColor(uint8(color[0]),uint8(color[1]),uint8(color[2]),uint8(color[3]))
    render.drawLine(cint(x),cint(drawStart),cint(x),cint(drawEnd))
    
  oldTime = time
  time = getTicks()
  var diff : uint32 = time - oldTime
  var frameTime : float = float(diff) / 1000.0 # Time to calculate actual frame
  var fps : int = int(1.0 / frameTime)
  render.present # Update the screen

  var moveSpeed : float = frameTime *  7.0 
  var rotSpeed : float = frameTime * 3.0

  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break

  # Key reading and movement
  var keyState = getKeyBoardState() 
  
  if keyState[int SDL_SCANCODE_W] != 0:
    if worldMap[int(pos.floatX + dir.floatX * moveSpeed)][int pos.floatY] == 0: pos.floatX += dir.floatX * moveSpeed
    if worldMap[int pos.floatX][int(pos.floatY + dir.floatY * moveSpeed)] == 0: pos.floatY += dir.floatY * moveSpeed

  if keyState[int SDL_SCANCODE_S] != 0:
    if worldMap[int(pos.floatX - dir.floatX * moveSpeed)][int pos.floatY] == 0: pos.floatX -= dir.floatX * moveSpeed
    if worldMap[int pos.floatX][int(pos.floatY - dir.floatY * moveSpeed)] == 0: pos.floatY -= dir.floatY * moveSpeed
    
  if keyState[int SDL_SCANCODE_D] != 0:
    var oldDirX : float = dir.floatX
    dir.floatX = dir.floatX * cos(-rotSpeed) - dir.floatY * sin(-rotSpeed)
    dir.floatY = oldDirX * sin(-rotSpeed) + dir.floatY * cos(-rotSpeed)
    var oldPlaneX : float = plane.floatX
    plane.floatX = plane.floatX * cos(-rotSpeed) - plane.floatY * sin(-rotSpeed)
    plane.floatY = oldPlaneX * sin(-rotSpeed) + plane.floatY * cos(-rotSpeed)

  if keyState[int SDL_SCANCODE_A] != 0:
     var oldDirX : float = dir.floatX
     dir.floatX = dir.floatX * cos(rotSpeed) - dir.floatY * sin(rotSpeed)
     dir.floatY = oldDirX * sin(rotSpeed) + dir.floatY * cos(rotSpeed)
     var oldPlaneX : float = plane.floatX
     plane.floatX = plane.floatX * cos(rotSpeed) - plane.floatY * sin(rotSpeed)
     plane.floatY = oldPlaneX * sin(rotSpeed) + plane.floatY * cos(rotSpeed)
    
    # LookUp table for ScanCodes -> https://wiki.libsdl.org/SDLScancode3Lookup
    
destroy render
destroy window
sdl2.quit()

import sdl2
import math

# ------ SDL2 CONF ------

discard sdl2.init(INIT_EVERYTHING)

var
  window : WindowPtr
  render : RendererPtr

window = createWindow("NIM RayCasting", 100,100,640,480, SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync)


var
  evt = sdl2.defaultEvent
  runGame = true

# ------ GAME DATA ------
#[
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
  posX : float = 22
  posY : float = 12
  dirX : float = -1
  diry : float =  0
  planeX : float = 0
  planeY : float = 0.66
  time : uint32 = 0
  oldTime : uint32 = 0
  color : array[4, int] = [0,0,0,0]

# ------ MAIN LOOP ------

while runGame:
  render.setDrawColor(0,0,0,0)
  render.clear
  oldTime = time
  for x in 0..640:
    var
      cameraX : float = 2.0 * float(x) / float(640) - 1
      rayDirX : float = dirX + planeX * cameraX
      rayDirY : float = dirY + planeY * cameraX
      mapX : int = int(posX)
      mapY : int = int(posY)
      sideDistX : float
      sideDistY : float
      deltaDistX : float = abs(1 / rayDirX)
      deltaDistY : float = abs(1 / rayDirY)
      perpWallDist : float
      stepX : int
      stepY : int
      hit : int = 0
      side : int

    if rayDirX < 0:
      stepX = -1
      sideDistX = (posX - float(mapX) * deltaDistX)
    else:
      stepX = 1
      sideDistX = (float(mapX) + 1.0 - posX) * deltaDistX

    if rayDirY < 0:
      stepY = -1
      sideDistY = (posY - float(mapY)) * deltaDistY
    else:
      stepY = 1
      sideDistY = (float(mapY) + 1.0 - posY) * deltaDistY

    # DDA Algorithm
    while hit == 0:
      if sideDistX < sideDistY:
        sideDistX += deltaDistX
        mapX += stepX
        side = 0
      else:
        sideDistY += deltaDistY
        mapY += stepY
        side = 1

      if worldMap[mapX][mapY] > 0 : hit = 1

    if side == 0:
      perpWallDist = (float(mapX) - posX + (1 - stepX) / 2) / rayDirX
    else:
      perpWallDist = (float(mapY) - posY + (1 - stepY) / 2) / rayDirY

    var lineHeight : int = (int) 480 / perpWallDist

    var drawStart : int = int(-lineHeight / 2 + 640 / 2)
    if drawStart < 0: drawStart = 0

    var drawEnd : int = int(lineHeight / 2 + 640 / 2)
    if drawEnd < 0: drawEnd = 640 - 1

    case worldMap[mapX][mapY]
    of 1: color = [245,66,66,255] # Rojo
    of 2: color = [66,255,95,255] # Verde
    of 3: color = [66,81,245,255] # Azul
    of 4: color = [255,255,255,255] # Blanco
    else: color = [255,165,0,255] # Naranja

    if side == 1:
      for i in 0..2:
        color[i] = int(color[i] / 2)

    render.setDrawColor(uint8(color[0]),uint8(color[1]),uint8(color[2]),uint8(color[3]))
    render.drawLine(cint(x),cint(drawStart),cint(x),cint(drawEnd))

    time = getTicks()
    var diff : uint32 = time - oldTime
    var frameTime : float = float(diff) / 1000.0
    var moveSpeed : float = frameTime *  10.0
    var rotSpeed : float = frameTime * 3.0

    while pollEvent(evt):
      if evt.kind == QuitEvent:
        runGame = false
        break
      # LookUp table for ScanCodes -> https://wiki.libsdl.org/SDLScancode3Lookup
      if evt.kind == KeyDown:
        case int(evt.key.keysym.scancode)
        of 26: # W Key
          if worldMap[int(posX + dirX * moveSpeed)][int(posY)] == 0: posX += dirX * moveSpeed
          if worldMap[int(posX)][int(posY + dirY * moveSpeed)] == 0: posY += dirY * moveSpeed
        of 22: # S Key
          if worldMap[int(posX - dirX * moveSpeed)][int(posY)] == 0: posX -= dirX * moveSpeed
          if worldMap[int(posX)][int(posY - dirY * moveSpeed)] == 0: posY -= dirY * moveSpeed
        of 4: # A Key
          var oldDirX : float = dirX
          dirX = dirX * cos(rotSpeed) - dirY * sin(rotSpeed)
          dirY = oldDirX * sin(rotSpeed) + dirY * cos(rotSpeed)
          var oldPlaneX : float = planeX
          planeX = planeX * cos(rotSpeed) - planeY * sin(rotSpeed)
          planeY = oldPlaneX * sin(rotSpeed) + planeY * cos(rotSpeed)
        of 7: # D Key
          var oldDirX : float = dirX
          dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed)
          dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed)
          var oldPlaneX : float = planeX
          planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed)
          planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed)
        else: echo "tecla no soportada"
  render.present
destroy render
destroy window
sdl2.quit()

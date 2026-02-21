## Mouse/touch to game coordinates mapping

import raylib
import types

var
  gameMouse: Vector2
  prevGameMouse: Vector2
  gameScale: float32 = 1.0
  gameOffsetX: float32 = 0.0
  gameOffsetY: float32 = 0.0

proc initInputManager*() =
  gameMouse = Vector2(x: 0, y: 0)
  prevGameMouse = Vector2(x: 0, y: 0)

proc updateInputManager*(screenMouse: Vector2) =
  prevGameMouse = gameMouse
  let screenW = getScreenWidth().float32
  let screenH = getScreenHeight().float32
  gameScale = min(screenW / GameWidth.float32, screenH / GameHeight.float32)
  let destW = GameWidth.float32 * gameScale
  let destH = GameHeight.float32 * gameScale
  gameOffsetX = (screenW - destW) / 2.0
  gameOffsetY = (screenH - destH) / 2.0

  gameMouse.x = (screenMouse.x - gameOffsetX) / gameScale
  gameMouse.y = (screenMouse.y - gameOffsetY) / gameScale

proc gameMousePos*(): Vector2 = gameMouse

proc isMouseInGame*(): bool =
  gameMouse.x >= 0 and gameMouse.x < GameWidth.float32 and
  gameMouse.y >= 0 and gameMouse.y < GameHeight.float32

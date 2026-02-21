## Palace Scene: Top-down room exploration with card placement stations

import raylib
import ../types, ../palette, ../ui, ../renderer, ../cards

const
  TileSize = 12
  RoomW = 26  # tiles
  RoomH = 14  # tiles
  KnightSpeed = 60.0'f32

var
  rooms: array[4, Room]
  currentRoom: int
  knight: PalaceKnight
  backButton: PixelButton
  interactPrompt: bool
  interactStation: int  # -1 if none
  placingCards: bool
  placeCardIdx: int
  availableCards: seq[int]

var changeSceneProc*: proc(s: Scene)
var gameParticles*: ptr ParticleSystem

proc initRooms() =
  # Kitchen
  rooms[0] = Room(kind: RoomKitchen, exits: [-1, 1, -1, 3])
  rooms[0].stations[0] = Station(pos: Vector2(x: 60, y: 40), cards: [-1, -1, -1])
  rooms[0].stations[1] = Station(pos: Vector2(x: 160, y: 40), cards: [-1, -1, -1])
  rooms[0].stations[2] = Station(pos: Vector2(x: 110, y: 100), cards: [-1, -1, -1])

  # Bedroom
  rooms[1] = Room(kind: RoomBedroom, exits: [-1, -1, -1, 0])
  rooms[1].stations[0] = Station(pos: Vector2(x: 50, y: 50), cards: [-1, -1, -1])
  rooms[1].stations[1] = Station(pos: Vector2(x: 200, y: 50), cards: [-1, -1, -1])
  rooms[1].stations[2] = Station(pos: Vector2(x: 125, y: 110), cards: [-1, -1, -1])

  # Garden
  rooms[2] = Room(kind: RoomGarden, exits: [3, -1, -1, -1])
  rooms[2].stations[0] = Station(pos: Vector2(x: 80, y: 40), cards: [-1, -1, -1])
  rooms[2].stations[1] = Station(pos: Vector2(x: 200, y: 70), cards: [-1, -1, -1])
  rooms[2].stations[2] = Station(pos: Vector2(x: 80, y: 120), cards: [-1, -1, -1])

  # Library
  rooms[3] = Room(kind: RoomLibrary, exits: [-1, 0, 2, -1])
  rooms[3].stations[0] = Station(pos: Vector2(x: 60, y: 40), cards: [-1, -1, -1])
  rooms[3].stations[1] = Station(pos: Vector2(x: 200, y: 40), cards: [-1, -1, -1])
  rooms[3].stations[2] = Station(pos: Vector2(x: 130, y: 100), cards: [-1, -1, -1])

proc initPalaceScene*() =
  initRooms()
  currentRoom = 0
  knight = PalaceKnight(
    pos: Vector2(x: 150, y: 90),
    targetPos: Vector2(x: 150, y: 90),
    direction: 0, frame: 0, frameTimer: 0,
  )
  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  interactPrompt = false
  interactStation = -1
  placingCards = false
  placeCardIdx = 0
  availableCards = newDeck()
  shuffleDeck(availableCards)

proc tryChangeRoom(dir: int) =
  let nextRoom = rooms[currentRoom].exits[dir]
  if nextRoom >= 0:
    currentRoom = nextRoom
    # Place knight at opposite edge
    case dir
    of 0: knight.pos.y = float32(GameHeight - 30) # came from north, appear at south
    of 1: knight.pos.x = 20.0 # came from east, appear at west
    of 2: knight.pos.y = 30.0  # came from south, appear at north
    of 3: knight.pos.x = float32(GameWidth - 20) # came from west, appear at east
    else: discard

proc updatePalaceScene*(dt: float32) =
  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneTitle)
    return

  if placingCards:
    # In card placement mode - press 1-3 or click to place
    if isKeyPressed(Escape):
      placingCards = false
    return

  # Knight movement
  var dx, dy: float32 = 0
  if isKeyDown(Left) or isKeyDown(A): dx -= 1
  if isKeyDown(Right) or isKeyDown(D): dx += 1
  if isKeyDown(Up) or isKeyDown(W): dy -= 1
  if isKeyDown(Down) or isKeyDown(S): dy += 1

  if dx != 0 or dy != 0:
    knight.moving = true
    if dx < 0: knight.direction = 2
    elif dx > 0: knight.direction = 3
    if dy < 0: knight.direction = 1
    elif dy > 0: knight.direction = 0

    knight.pos.x += dx * KnightSpeed * dt
    knight.pos.y += dy * KnightSpeed * dt

    # Animation
    knight.frameTimer += dt
    if knight.frameTimer > 0.15:
      knight.frameTimer = 0
      knight.frame = (knight.frame + 1) mod 4

    # Clamp to room bounds
    knight.pos.x = clamp(knight.pos.x, 10, GameWidth.float32 - 18)
    knight.pos.y = clamp(knight.pos.y, 24, GameHeight.float32 - 18)

    # Check room transitions
    if knight.pos.y <= 25: tryChangeRoom(0)    # North
    if knight.pos.x >= GameWidth.float32 - 19: tryChangeRoom(1)  # East
    if knight.pos.y >= GameHeight.float32 - 19: tryChangeRoom(2) # South
    if knight.pos.x <= 11: tryChangeRoom(3)    # West
  else:
    knight.moving = false
    knight.frame = 0

  # Check proximity to stations
  interactPrompt = false
  interactStation = -1
  for i in 0..2:
    let st = rooms[currentRoom].stations[i]
    let dx = knight.pos.x - st.pos.x
    let dy = knight.pos.y - st.pos.y
    if dx*dx + dy*dy < 400:  # within ~20px
      interactPrompt = true
      interactStation = i
      break

  if interactPrompt and (isKeyPressed(E) or isKeyPressed(Space)):
    placingCards = true
    placeCardIdx = 0

proc drawRoom() =
  let room = rooms[currentRoom]

  # Floor
  let floorColor = case room.kind
    of RoomKitchen: PalGrayDark
    of RoomBedroom: PalPurpleDark
    of RoomGarden: PalForest
    of RoomLibrary: PalNavy

  let wallColor = case room.kind
    of RoomKitchen: Color(r: 180, g: 160, b: 140, a: 255)
    of RoomBedroom: PalPlum
    of RoomGarden: PalGreenDark
    of RoomLibrary: Color(r: 80, g: 50, b: 30, a: 255)

  # Floor tiles
  for ty in 0..<RoomH:
    for tx in 0..<RoomW:
      let x = int32(tx * TileSize) + 4
      let y = int32(ty * TileSize) + 22
      let checker = if (tx + ty) mod 2 == 0: floorColor
                    else: Color(r: uint8(int(floorColor.r) + 10),
                                g: uint8(int(floorColor.g) + 10),
                                b: uint8(int(floorColor.b) + 10), a: 255)
      drawRectangle(x, y, TileSize, TileSize, checker)

  # Walls
  drawRectangle(0, 22, GameWidth, 4, wallColor)   # Top wall
  drawRectangle(0, 22, 4, GameHeight - 22, wallColor)  # Left wall
  drawRectangle(GameWidth - 4, 22, 4, GameHeight - 22, wallColor) # Right wall
  drawRectangle(0, GameHeight - 4, GameWidth, 4, wallColor) # Bottom wall

  # Draw exits as gaps
  for i in 0..3:
    if room.exits[i] >= 0:
      case i
      of 0: drawRectangle(GameWidth div 2 - 15, 22, 30, 4, PalBlack) # North
      of 1: drawRectangle(GameWidth - 4, GameHeight div 2 - 15, 4, 30, PalBlack) # East
      of 2: drawRectangle(GameWidth div 2 - 15, GameHeight - 4, 30, 4, PalBlack) # South
      of 3: drawRectangle(0, GameHeight div 2 - 15, 4, 30, PalBlack) # West
      else: discard

  # Draw stations
  for i in 0..2:
    let st = room.stations[i]
    let sx = int32(st.pos.x) - 10
    let sy = int32(st.pos.y) - 10
    # Station platform
    drawRectangle(sx, sy, 20, 20,
      if st.filled: PalGreenDark else: PalGrayDark)
    drawRectangleLines(Rectangle(x: sx.float32, y: sy.float32,
      width: 20, height: 20), 1, PalBlack)
    # Station number
    drawText($(i + 1), sx + 7, sy + 6, 8, PalWhite)
    # Show cards if placed
    if st.filled:
      for j in 0..2:
        if st.cards[j] >= 0:
          let card = paoTable[st.cards[j]].card
          drawCardFace(card, sx + int32(j) * 8 - 2, sy - 14, 10, 14)

proc drawKnight() =
  let kx = int32(knight.pos.x)
  let ky = int32(knight.pos.y)

  # Body (8x12 character)
  let bodyColor = PalSkyBlue
  let headColor = PalPeach

  # Simple directional sprite
  # Head
  drawRectangle(kx - 3, ky - 6, 6, 5, headColor)
  # Eyes
  case knight.direction
  of 0: # Down
    drawRectangle(kx - 2, ky - 4, 1, 1, PalBlack)
    drawRectangle(kx + 1, ky - 4, 1, 1, PalBlack)
  of 1: # Up
    discard # No eyes visible from behind
  of 2: # Left
    drawRectangle(kx - 3, ky - 4, 1, 1, PalBlack)
  of 3: # Right
    drawRectangle(kx + 2, ky - 4, 1, 1, PalBlack)
  else: discard

  # Body
  drawRectangle(kx - 3, ky - 1, 6, 6, bodyColor)
  # Legs (animate)
  let legOffset = if knight.moving and knight.frame mod 2 == 0: 1'i32 else: 0'i32
  drawRectangle(kx - 2, ky + 5, 2, 3 + legOffset, PalNavyBlue)
  drawRectangle(kx, ky + 5, 2, 3 - legOffset, PalNavyBlue)
  # Outline
  drawRectangleLines(Rectangle(x: float32(kx - 3), y: float32(ky - 6),
    width: 6, height: 14), 1, PalBlack)

proc drawPalaceScene*() =
  # Header
  drawRectangle(0, 0, GameWidth, 22, PalNavy)
  drawButton(backButton)

  let roomName = case rooms[currentRoom].kind
    of RoomKitchen: "Kitchen"
    of RoomBedroom: "Bedroom"
    of RoomGarden: "Garden"
    of RoomLibrary: "Library"
  drawPixelText("PALACE: " & roomName, 50, 7, 8, PalWhite)

  drawRoom()
  drawKnight()

  # Interact prompt
  if interactPrompt and not placingCards:
    drawCenteredText("[E] Interact", GameHeight - 16, 8, PalGold)

  # Card placement overlay
  if placingCards:
    drawRectangle(0, 0, GameWidth, GameHeight,
      Color(r: 0, g: 0, b: 0, a: 150))
    drawCenteredTextShadow("Place PAO Triple", 30, 10, PalGold)
    drawCenteredText("Station " & $(interactStation + 1), 50, 8, PalWhite)

    if availableCards.len > 0:
      # Show next 3 cards to place
      for i in 0..2:
        let idx = placeCardIdx + i
        if idx < availableCards.len:
          let ci = availableCards[idx]
          let card = paoTable[ci].card
          let cx = int32(80 + i * 60)
          drawCardFace(card, cx, 65, CardWidth, CardHeight)
          let pao = paoTable[ci]
          let label = case i
            of 0: "P: " & pao.person
            of 1: "A: " & pao.action
            of 2: "O: " & pao.obj
            else: ""
          drawPixelText(label, cx - 10, 110, 8, PalWhite)

    drawCenteredText("[ESC] Cancel", GameHeight - 20, 8, PalGray)

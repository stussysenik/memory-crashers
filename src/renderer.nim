## Rendering utilities: RenderTexture scaling, card drawing, suit symbols

import raylib
import types, palette

var
  target*: RenderTexture2D

proc initRenderer*() =
  target = loadRenderTexture(GameWidth, GameHeight)
  setTextureFilter(target.texture, Point)

proc beginGameDraw*() =
  beginTextureMode(target)

proc endGameDraw*(shakeX: float32 = 0; shakeY: float32 = 0) =
  endTextureMode()
  let screenW = getScreenWidth().float32
  let screenH = getScreenHeight().float32
  let scale = min(screenW / GameWidth.float32, screenH / GameHeight.float32)
  let destW = GameWidth.float32 * scale
  let destH = GameHeight.float32 * scale
  let offsetX = (screenW - destW) / 2.0 + shakeX
  let offsetY = (screenH - destH) / 2.0 + shakeY

  beginDrawing()
  clearBackground(PalBlack)
  drawTexture(
    target.texture,
    Rectangle(x: 0, y: 0, width: GameWidth.float32, height: -GameHeight.float32),
    Rectangle(x: offsetX, y: offsetY, width: destW, height: destH),
    Vector2(x: 0, y: 0),
    0,
    White
  )
  endDrawing()

proc unloadRenderer*() =
  # naylib handles cleanup via destructors
  discard

proc drawPixelRect*(x, y, w, h: int32, color: Color) =
  drawRectangle(x, y, w, h, color)

proc drawPixelRectOutline*(x, y, w, h: int32, color: Color) =
  drawRectangleLines(Rectangle(x: x.float32, y: y.float32,
    width: w.float32, height: h.float32), 1.0, color)

proc drawSuitSymbol*(suit: Suit, x, y: int32, size: int32 = 5) =
  let col = if suitColor(suit): PalCardRed else: PalCardBlack
  case suit
  of Hearts:
    # Simple heart shape: two circles + triangle
    let cx = x.float32
    let cy = y.float32
    let s = size.float32
    drawCircle(int32(cx - s*0.3), int32(cy - s*0.15), s*0.35, col)
    drawCircle(int32(cx + s*0.3), int32(cy - s*0.15), s*0.35, col)
    drawTriangle(
      Vector2(x: cx - s*0.6, y: cy),
      Vector2(x: cx, y: cy + s*0.7),
      Vector2(x: cx + s*0.6, y: cy),
      col
    )
  of Diamonds:
    let cx = x.float32
    let cy = y.float32
    let s = size.float32
    drawTriangle(
      Vector2(x: cx, y: cy - s*0.5),
      Vector2(x: cx - s*0.4, y: cy),
      Vector2(x: cx, y: cy + s*0.5),
      col
    )
    drawTriangle(
      Vector2(x: cx, y: cy - s*0.5),
      Vector2(x: cx, y: cy + s*0.5),
      Vector2(x: cx + s*0.4, y: cy),
      col
    )
  of Clubs:
    let cx = x.float32
    let cy = y.float32
    let s = size.float32
    drawCircle(int32(cx), int32(cy - s*0.3), s*0.3, col)
    drawCircle(int32(cx - s*0.3), int32(cy + s*0.1), s*0.3, col)
    drawCircle(int32(cx + s*0.3), int32(cy + s*0.1), s*0.3, col)
    drawRectangle(int32(cx - s*0.1), int32(cy + s*0.1), int32(s*0.2), int32(s*0.5), col)
  of Spades:
    let cx = x.float32
    let cy = y.float32
    let s = size.float32
    drawTriangle(
      Vector2(x: cx, y: cy - s*0.5),
      Vector2(x: cx + s*0.5, y: cy + s*0.15),
      Vector2(x: cx - s*0.5, y: cy + s*0.15),
      col
    )
    drawCircle(int32(cx - s*0.25), int32(cy + s*0.15), s*0.28, col)
    drawCircle(int32(cx + s*0.25), int32(cy + s*0.15), s*0.28, col)
    drawRectangle(int32(cx - s*0.1), int32(cy + s*0.2), int32(s*0.2), int32(s*0.4), col)

proc drawCardFace*(card: Card, x, y: int32, w: int32 = CardWidth, h: int32 = CardHeight) =
  # Card background
  drawRectangle(x, y, w, h, PalCardFace)
  # Border
  drawPixelRectOutline(x, y, w, h, PalCardBorder)

  let rankStr = rankChar(card.rank)
  let col = if suitColor(card.suit): PalCardRed else: PalCardBlack

  # Rank text top-left
  drawText(rankStr, x + 2, y + 2, 8, col)

  # Suit symbol center
  drawSuitSymbol(card.suit, x + w div 2, y + h div 2, 6)

  # Small rank bottom-right (upside down effect - just draw small)
  drawText(rankStr, x + w - 10, y + h - 10, 8, col)

proc drawCardBack*(x, y: int32, w: int32 = CardWidth, h: int32 = CardHeight) =
  drawRectangle(x, y, w, h, PalCardBack)
  drawPixelRectOutline(x, y, w, h, PalCardBorder)
  # Cross-hatch pattern
  for i in countup(0'i32, w, 4):
    drawLine(x + i, y + 1, x + i, y + h - 1, PalBlueDark)
  for j in countup(0'i32, h, 4):
    drawLine(x + 1, y + j, x + w - 1, y + j, PalBlueDark)
  # Center diamond
  let cx = x + w div 2
  let cy = y + h div 2
  drawSuitSymbol(Spades, cx, cy, 5)

proc drawCardFlipping*(card: Card, x, y: int32, flipProgress: float32,
                       w: int32 = CardWidth, h: int32 = CardHeight) =
  ## flipProgress: 0.0 = fully back, 1.0 = fully face
  let absFlip = abs(flipProgress * 2.0 - 1.0)
  let drawW = max(int32(w.float32 * absFlip), 2'i32)
  let drawX = x + (w - drawW) div 2

  if flipProgress < 0.5:
    drawCardBack(drawX, y, drawW, h)
  else:
    drawCardFace(card, drawX, y, drawW, h)

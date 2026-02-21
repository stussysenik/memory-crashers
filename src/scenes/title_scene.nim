## Title Scene: Bouncing logo, 4 mode buttons, player stats

import raylib
import std/math
import ../types, ../palette, ../ui, ../animation

var
  logoY: float32
  logoTween: Tween
  buttons: array[4, PixelButton]
  logoTimer: float32

# Forward declarations - these are set by the main module
var changeSceneProc*: proc(s: Scene)

proc initTitleScene*() =
  logoY = -20
  logoTween = newTween(-20, 20, 0.8, EaseOutBounce)
  logoTimer = 0

  let btnW: float32 = 100
  let btnH: float32 = 18
  let startX: float32 = (GameWidth.float32 - btnW) / 2
  let startY: float32 = 75

  buttons[0] = newPixelButton(startX, startY, btnW, btnH,
    "Card Academy", PalGreen, PalLime, PalBlack)
  buttons[1] = newPixelButton(startX, startY + 24, btnW, btnH,
    "Battle Arena", PalBlue, PalSkyBlue, PalWhite)
  buttons[2] = newPixelButton(startX, startY + 48, btnW, btnH,
    "Memory Palace", PalPurple, PalMagenta, PalWhite)
  buttons[3] = newPixelButton(startX, startY + 72, btnW, btnH,
    "Daily Challenge", PalOrange, PalGold, PalBlack)

proc updateTitleScene*(dt: float32) =
  logoTimer += dt
  updateTween(logoTween, dt)
  logoY = logoTween.current

  # Bouncing idle animation after initial tween
  if logoTween.isComplete():
    logoY = 20 + sin(logoTimer * 2.0) * 3.0

  for i in 0..3:
    if updateButton(buttons[i]):
      let scene = case i
        of 0: SceneAcademy
        of 1: SceneArena
        of 2: ScenePalace
        of 3: SceneDaily
        else: SceneTitle
      if changeSceneProc != nil:
        changeSceneProc(scene)

proc drawTitleScene*() =
  # Background gradient effect with stripes
  for y in countup(0'i32, GameHeight, 2):
    let t = float32(y) / GameHeight.float32
    let col = Color(
      r: uint8(float32(PalNavy.r) * (1 - t) + float32(PalPurpleDark.r) * t),
      g: uint8(float32(PalNavy.g) * (1 - t) + float32(PalPurpleDark.g) * t),
      b: uint8(float32(PalNavy.b) * (1 - t) + float32(PalPurpleDark.b) * t),
      a: 255
    )
    drawRectangle(0, y, GameWidth, 2, col)

  # Title text
  drawCenteredTextShadow("MEMORY", int32(logoY), 20, PalGold)
  drawCenteredTextShadow("CRASHERS", int32(logoY) + 20, 20, PalCoral)

  # Subtitle
  drawCenteredText("Master the Deck", int32(logoY) + 45, 8, PalLightGray)

  # Buttons
  for btn in buttons:
    drawButton(btn)

  # Player stats at bottom
  drawPixelText("Press a button to begin!", 60, GameHeight - 14, 8, PalGray)

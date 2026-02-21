## Home Scene: Dashboard replacing title screen
## Shows at-a-glance progress + clear next action

import raylib
import std/math
import ../types, ../palette, ../design, ../ui, ../animation, ../hints, ../player,
       ../learn_data

var
  logoY: float32
  logoTween: Tween
  logoTimer: float32
  continueBtn: PixelButton
  practiceBtn: PixelButton
  speedBtn: PixelButton
  dailyBtn: PixelButton
  browseBtn: PixelButton
  modesUnlocked: bool

var changeSceneProc*: proc(s: Scene)
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

proc ctaLabel(pd: PlayerData): string =
  if pd.totalCardsStudied == 0:
    "START LEARNING"
  elif pd.currentStage < 7:
    "CONTINUE: Stage " & $(pd.currentStage + 1)
  else:
    "PRACTICE TIME!"

proc initHomeScene*() =
  logoY = -20
  logoTween = newTween(-20, 8, 0.8, EaseOutBounce)
  logoTimer = 0
  setHintCategory(HintHome)

  # Check if modes are unlocked (Stage 0 completed)
  modesUnlocked = false
  if playerDataPtr != nil:
    modesUnlocked = playerDataPtr[].stageProgress[0].completed

  # Primary CTA button (large, centered)
  let ctaW: float32 = BtnPrimaryW.float32
  let ctaH: float32 = BtnPrimaryH.float32
  let ctaX = (ScreenW.float32 - ctaW) / 2
  let ctaY: float32 = 104
  var label = "START LEARNING"
  if playerDataPtr != nil:
    label = ctaLabel(playerDataPtr[])
  continueBtn = newPixelButton(ctaX, ctaY, ctaW, ctaH,
    label, ColBtnPrimary, PalLime, PalBlack)

  # Secondary buttons (4 side-by-side: Practice | Speed | Daily | Browse)
  let btnW: float32 = 52
  let btnH: float32 = BtnSecondaryH.float32
  let gap: float32 = RowGap.float32
  let totalW = btnW * 4 + gap * 3
  let startX = (ScreenW.float32 - totalW) / 2
  let btnY: float32 = 130

  if modesUnlocked:
    practiceBtn = newPixelButton(startX, btnY, btnW, btnH,
      "Practice", ColBtnSecondary, PalSkyBlue, PalWhite)
    speedBtn = newPixelButton(startX + btnW + gap, btnY, btnW, btnH,
      "Speed", PalGold, PalGold, PalBlack)
    dailyBtn = newPixelButton(startX + (btnW + gap) * 2, btnY, btnW, btnH,
      "Daily", PalOrange, PalGold, PalBlack)
  else:
    practiceBtn = newPixelButton(startX, btnY, btnW, btnH,
      "Practice", PalGrayDark, PalGrayDark, PalGray)
    speedBtn = newPixelButton(startX + btnW + gap, btnY, btnW, btnH,
      "Speed", PalGrayDark, PalGrayDark, PalGray)
    dailyBtn = newPixelButton(startX + (btnW + gap) * 2, btnY, btnW, btnH,
      "Daily", PalGrayDark, PalGrayDark, PalGray)

  # Browse button — always enabled
  browseBtn = newPixelButton(startX + (btnW + gap) * 3, btnY, btnW, btnH,
    "Browse", PalTeal, PalCyan, PalBlack)

proc updateHomeScene*(dt: float32) =
  logoTimer += dt
  updateTween(logoTween, dt)
  logoY = logoTween.current
  updateHints(dt)

  if logoTween.isComplete():
    logoY = 8 + sin(logoTimer * 2.0) * 2.0

  if updateButton(continueBtn):
    if changeSceneProc != nil:
      changeSceneProc(SceneLearn)

  if modesUnlocked:
    if updateButton(practiceBtn):
      if changeSceneProc != nil:
        changeSceneProc(ScenePractice)

    if updateButton(speedBtn):
      if changeSceneProc != nil:
        changeSceneProc(SceneSpeedCards)

    if updateButton(dailyBtn):
      if changeSceneProc != nil:
        changeSceneProc(SceneDaily)
  else:
    # Still update to track hover state but don't navigate
    discard updateButton(practiceBtn)
    discard updateButton(speedBtn)
    discard updateButton(dailyBtn)

  # Browse always enabled
  if updateButton(browseBtn):
    if changeSceneProc != nil:
      changeSceneProc(SceneBrowse)

proc drawHomeScene*() =
  # Background gradient
  for y in countup(0'i32, GameHeight, 2):
    let t = float32(y) / GameHeight.float32
    let col = Color(
      r: uint8(float32(PalNavy.r) * (1 - t) + float32(PalPurpleDark.r) * t),
      g: uint8(float32(PalNavy.g) * (1 - t) + float32(PalPurpleDark.g) * t),
      b: uint8(float32(PalNavy.b) * (1 - t) + float32(PalPurpleDark.b) * t),
      a: 255
    )
    drawRectangle(0, y, GameWidth, 2, col)

  # Title
  drawCenteredTextShadow("MEMORY", int32(logoY), FontLarge, PalGold)
  drawCenteredTextShadow("CRASHERS", int32(logoY) + 20, FontLarge, PalCoral)

  if playerDataPtr != nil:
    let pd = playerDataPtr[]
    let barW: int32 = 200
    let barX = int32((ScreenW - barW) div 2)

    if pd.totalCardsStudied == 0:
      # --- New user: compelling motivation ---
      drawCenteredText("Memory athletes memorize a full deck", 46,
        FontTiny, PalGold)
      drawCenteredText("in under 30 seconds. You can train", 56,
        FontTiny, ColTextSecondary)
      drawCenteredText("this skill with the PAO method.", 66,
        FontTiny, ColTextSecondary)
      drawCenteredText("Sharpen focus. Build mental palaces.", 78,
        FontTiny, PalCyan)
      drawCenteredText("Compete against your own records.", 88,
        FontTiny, PalGray)

    else:
      # --- Returning user: show progress ---

      # Row 1: Current learning stage with description
      let stageLabel = if pd.currentStage < 7:
        "Learning: " & StageNames[pd.currentStage]
      else: "All stages complete!"
      let stageDesc = if pd.currentStage < 7:
        StageDescriptions[pd.currentStage]
      else: ""
      drawPixelText(stageLabel, barX, 50, FontTiny, ColTextAccent)
      if stageDesc.len > 0:
        let descW = measureText(stageDesc, FontTiny)
        drawPixelText(stageDesc, barX + barW - descW, 50, FontTiny, PalGray)
      let stageProgress = if pd.currentStage < 7:
        stageProgressPercent(pd, pd.currentStage)
      else: 1.0'f32
      drawProgressBar(barX, 59, barW, 4, stageProgress,
        PalGrayDark, StageColors[min(pd.currentStage, 6)])

      # Row 2: Cards mastered out of 52
      let mastered = masteredCardCount(pd)
      let masteryPct = float32(mastered) / 52.0
      drawPixelText("Cards Mastered", barX, 67, FontTiny, ColTextSecondary)
      let masteryStr = $mastered & "/52"
      let mW = measureText(masteryStr, FontTiny)
      drawPixelText(masteryStr, barX + barW - mW, 67, FontTiny, ColMastery5)
      drawProgressBar(barX, 76, barW, 4, masteryPct,
        PalGrayDark, ColMastery5)

      # Row 3: Level + XP
      let needed = xpForLevel(pd.level + 1)
      let xpProg = xpProgress(pd)
      drawPixelText("Level " & $pd.level, barX, 84, FontTiny, PalGold)
      let xpStr = $pd.xp & "/" & $needed & " XP"
      let xW = measureText(xpStr, FontTiny)
      drawPixelText(xpStr, barX + barW - xW, 84, FontTiny, PalCyan)
      drawProgressBar(barX, 93, barW, 4, xpProg, PalGrayDark, PalCyan)

  else:
    # No save data at all: show motivation
    drawCenteredText("Memory athletes memorize a full deck", 46,
      FontTiny, PalGold)
    drawCenteredText("in under 30 seconds. You can train", 56,
      FontTiny, ColTextSecondary)
    drawCenteredText("this skill with the PAO method.", 66,
      FontTiny, ColTextSecondary)
    drawCenteredText("Sharpen focus. Build mental palaces.", 78,
      FontTiny, PalCyan)
    drawCenteredText("Compete against your own records.", 88,
      FontTiny, PalGray)

  # Buttons
  drawButton(continueBtn)
  drawButton(practiceBtn)
  drawButton(speedBtn)
  drawButton(dailyBtn)
  drawButton(browseBtn)

  # Hint bar
  drawHintBar()

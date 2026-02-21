## Daily Challenge: Day-seeded full deck challenge with streak tracking

import raylib
import std/strutils
import ../types, ../palette, ../ui, ../animation, ../renderer, ../cards,
       ../input_manager, ../player, ../storage

var
  phase: ArenaPhase
  dailyDeck: seq[int]
  currentViewCard: int
  memorizeTimer: float32
  recallSelected: seq[int]
  recallGrid: seq[int]
  scoreAccuracy: float32
  scoreFinal: int
  alreadyCompleted: bool
  dayNumber: int
  backButton: PixelButton
  nextCardButton: PixelButton
  prevCardButton: PixelButton
  doneMemButton: PixelButton
  startButton: PixelButton
  undoButton: PixelButton

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32, duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData

proc initDailyScene*() =
  dayNumber = getDayNumber()
  alreadyCompleted = false
  if playerDataPtr != nil:
    alreadyCompleted = playerDataPtr[].dailyCompleted and
                       playerDataPtr[].lastPlayDate == dayNumber

  dailyDeck = newDeck()
  shuffleDeckSeeded(dailyDeck, dayNumber)

  phase = ArenaSetup
  currentViewCard = 0
  memorizeTimer = 0
  recallSelected = @[]

  recallGrid = dailyDeck
  var gridCopy = recallGrid
  # Shuffle with different seed for grid display
  setRandomSeed(uint32(dayNumber + 9999))
  for i in countdown(gridCopy.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(gridCopy[i], gridCopy[j])
  recallGrid = gridCopy

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  startButton = newPixelButton(110, 120, 100, 20, "Begin!", PalGreen, PalLime, PalBlack)

  let btnY = GameHeight.float32 - 22
  prevCardButton = newPixelButton(40, btnY, 50, 16, "< Prev", PalGrayDark, PalGray, PalWhite)
  nextCardButton = newPixelButton(170, btnY, 50, 16, "Next >", PalGrayDark, PalGray, PalWhite)
  doneMemButton = newPixelButton(110, btnY, 60, 16, "Done!", PalGreen, PalLime, PalBlack)
  undoButton = newPixelButton(4, GameHeight.float32 - 20, 40, 16,
    "Undo", PalRedDark, PalRed, PalWhite)

proc calculateDailyScore() =
  var correct = 0
  for i in 0..<min(recallSelected.len, dailyDeck.len):
    if recallSelected[i] == dailyDeck[i]:
      correct += 1
  scoreAccuracy = float32(correct) / 52.0
  let timeBonus = max(0.5, 2.0 - memorizeTimer / 260.0)
  scoreFinal = int(scoreAccuracy * 100.0 * timeBonus)

  if playerDataPtr != nil:
    playerDataPtr[].dailyCompleted = true
    updateStreak(playerDataPtr[], dayNumber)
    addXp(playerDataPtr[], XpDailyComplete + playerDataPtr[].streak * XpStreakBonus)
    savePlayerData(playerDataPtr[])

proc updateDailyScene*(dt: float32) =
  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneTitle)
    return

  case phase
  of ArenaSetup:
    if not alreadyCompleted:
      if updateButton(startButton):
        phase = ArenaMemorize
        currentViewCard = 0
        memorizeTimer = 0

  of ArenaMemorize:
    memorizeTimer += dt

    if updateButton(prevCardButton):
      if currentViewCard > 0: currentViewCard -= 1
    if updateButton(nextCardButton):
      if currentViewCard < 51: currentViewCard += 1
    if updateButton(doneMemButton):
      phase = ArenaRecall
      recallSelected = @[]

    if isKeyPressed(Left) and currentViewCard > 0: currentViewCard -= 1
    if isKeyPressed(Right) and currentViewCard < 51: currentViewCard += 1
    if isKeyPressed(Enter): phase = ArenaRecall

  of ArenaRecall:
    if updateButton(undoButton):
      if recallSelected.len > 0: discard recallSelected.pop()

    let mp = gameMousePos()
    let cols = 13
    let gridW = cols * (CardWidth + 2)
    let startX = (GameWidth - gridW) div 2
    let startY: int32 = 26

    for i in 0..<recallGrid.len:
      if recallGrid[i] in recallSelected: continue
      let col = i mod cols
      let row = i div cols
      let cx = float32(startX + int32(col) * (CardWidth + 2))
      let cy = float32(startY + int32(row) * (CardHeight + 2))
      let rect = Rectangle(x: cx, y: cy,
                            width: CardWidth.float32, height: CardHeight.float32)
      if checkCollisionPointRec(mp, rect) and isMouseButtonPressed(Left):
        recallSelected.add(recallGrid[i])
        if recallSelected.len == 52:
          calculateDailyScore()
          phase = ArenaResults
          if scoreAccuracy >= 0.5:
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 90), 40)

  of ArenaResults:
    if isMouseButtonPressed(Left) or isKeyPressed(Enter):
      if changeSceneProc != nil:
        changeSceneProc(SceneTitle)

proc drawDailyScene*() =
  drawRectangle(0, 0, GameWidth, 22, PalNavy)
  drawButton(backButton)
  drawPixelText("DAILY CHALLENGE", 50, 7, 8, PalWhite)

  case phase
  of ArenaSetup:
    drawCenteredTextShadow("DAILY CHALLENGE", 35, 14, PalGold)
    drawCenteredText("Full 52-card deck", 55, 8, PalLightGray)
    drawCenteredText("Same puzzle for everyone today!", 67, 8, PalLightGray)

    if playerDataPtr != nil:
      drawPixelText("Streak: " & $playerDataPtr[].streak & " days", 100, 85, 8, PalOrange)
      drawPixelText("Best: " & $playerDataPtr[].bestStreak & " days", 100, 97, 8, PalGray)

    if alreadyCompleted:
      drawCenteredTextShadow("Already completed today!", 120, 8, PalGreen)
      drawCenteredText("Come back tomorrow!", 135, 8, PalLightGray)
    else:
      drawButton(startButton)

  of ArenaMemorize:
    let timeStr = "Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s"
    drawPixelText(timeStr, 220, 7, 8, PalGold)

    let ci = dailyDeck[currentViewCard]
    let card = paoTable[ci].card
    let cardX = int32((GameWidth - CardWidth * 2) div 2)
    let cardY: int32 = 28
    drawCardFace(card, cardX, cardY, CardWidth * 2, CardHeight * 2)

    let pao = paoTable[ci]
    drawPixelText(pao.person & " " & pao.action & " " & pao.obj,
      10, 115, 8, PalGold)

    let progress = $(currentViewCard + 1) & " / 52"
    drawCenteredText(progress, 130, 8, PalLightGray)

    drawButton(prevCardButton)
    drawButton(nextCardButton)
    drawButton(doneMemButton)

  of ArenaRecall:
    drawPixelText($recallSelected.len & "/52", 260, 7, 8, PalGold)

    let cols = 13
    let gridW = cols * (CardWidth + 2)
    let startX = (GameWidth - gridW) div 2
    let startY: int32 = 26

    for i in 0..<recallGrid.len:
      let col = i mod cols
      let row = i div cols
      let cx = int32(startX + int32(col) * (CardWidth + 2))
      let cy = int32(startY + int32(row) * (CardHeight + 2))

      if recallGrid[i] in recallSelected:
        drawRectangle(cx, cy, CardWidth, CardHeight,
          Color(r: 40, g: 40, b: 50, a: 255))
      else:
        let card = paoTable[recallGrid[i]].card
        drawCardFace(card, cx, cy)

    drawButton(undoButton)

  of ArenaResults:
    drawCenteredTextShadow("DAILY RESULTS", 35, 14, PalGold)
    drawCenteredTextShadow("Score: " & $scoreFinal, 60, 16, PalGold)

    let accPct = int(scoreAccuracy * 100)
    drawCenteredText("Accuracy: " & $accPct & "%", 85, 8,
      if scoreAccuracy >= 0.5: PalGreen else: PalRed)
    drawCenteredText("Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s",
      100, 8, PalLightGray)

    if playerDataPtr != nil:
      drawCenteredText("Streak: " & $playerDataPtr[].streak & " days!", 120, 8, PalOrange)

    drawCenteredText("Click to return", 150, 8, PalLightGray)

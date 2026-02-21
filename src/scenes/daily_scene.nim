## Daily Challenge: Day-seeded full deck challenge with streak tracking
## Updated with hint bar, design system, and elaborated feedback

import raylib
import std/strutils
import ../types, ../palette, ../design, ../ui, ../animation, ../renderer, ../cards,
       ../input_manager, ../player, ../storage, ../hints

type
  DailyPhase = enum
    DailySetup, DailyMemorize, DailyRecall, DailyResults

var
  phase: DailyPhase
  dailyDeck: seq[int]
  currentViewCard: int
  memorizeTimer: float32
  recallSelected: seq[int]
  recallGrid: seq[int]
  mistakes: seq[MistakeRecord]
  scoreAccuracy: float32
  scoreFinal: int
  alreadyCompleted: bool
  dayNumber: int

  # Per-card feedback
  lastFeedbackCorrect: bool
  feedbackTimer: float32
  feedbackSlotIdx: int

  # UI
  backButton: PixelButton
  nextCardButton: PixelButton
  prevCardButton: PixelButton
  doneMemButton: PixelButton
  startButton: PixelButton
  undoButton: PixelButton
  resultsContinueBtn: PixelButton

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32; duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

proc initDailyScene*() =
  dayNumber = getDayNumber()
  alreadyCompleted = false
  if playerDataPtr != nil:
    alreadyCompleted = playerDataPtr[].dailyCompleted and
                       playerDataPtr[].lastPlayDate == dayNumber

  dailyDeck = newDeck()
  shuffleDeckSeeded(dailyDeck, dayNumber)

  phase = DailySetup
  currentViewCard = 0
  memorizeTimer = 0
  recallSelected = @[]
  mistakes = @[]
  feedbackTimer = 0
  setHintCategory(HintDaily)

  recallGrid = dailyDeck
  var gridCopy = recallGrid
  setRandomSeed(uint32(dayNumber + 9999))
  for i in countdown(gridCopy.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(gridCopy[i], gridCopy[j])
  recallGrid = gridCopy

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  startButton = newPixelButton((ScreenW.float32 - 100) / 2,
    float32(ContentY + 80), 100, 20, "Begin!", ColBtnPrimary, PalLime, PalBlack)

  let btnY = float32(ContentY + ContentH - 18)
  prevCardButton = newPixelButton(float32(ContentMargin + 4), btnY, 50, 16,
    "< Prev", PalGrayDark, PalGray, PalWhite)
  nextCardButton = newPixelButton(float32(ScreenW - ContentMargin - 54), btnY, 50, 16,
    "Next >", PalGrayDark, PalGray, PalWhite)
  doneMemButton = newPixelButton((ScreenW.float32 - 60) / 2, btnY, 60, 16,
    "Done!", PalGreen, PalLime, PalBlack)
  undoButton = newPixelButton(4, float32(HintBarY - 18), 40, 16,
    "Undo", PalRedDark, PalRed, PalWhite)

proc calculateDailyScore() =
  var correct = 0
  mistakes = @[]
  for i in 0..<min(recallSelected.len, dailyDeck.len):
    if recallSelected[i] == dailyDeck[i]:
      correct += 1
    else:
      mistakes.add(MistakeRecord(
        position: i,
        pickedCardIdx: recallSelected[i],
        correctCardIdx: dailyDeck[i],
      ))
  scoreAccuracy = float32(correct) / 52.0
  let timeBonus = max(0.5, 2.0 - memorizeTimer / 260.0)
  scoreFinal = int(scoreAccuracy * 100.0 * timeBonus)

  if playerDataPtr != nil:
    playerDataPtr[].dailyCompleted = true
    updateStreak(playerDataPtr[], dayNumber)
    discard addXp(playerDataPtr[], XpDailyComplete + playerDataPtr[].streak * XpStreakBonus)
    savePlayerData(playerDataPtr[])
    if gameFloatingTexts != nil:
      spawnFloatingText(gameFloatingTexts[], "+50 XP", 160, 50, PalGold)

  resultsContinueBtn = newPixelButton(
    (ScreenW.float32 - 100) / 2, float32(ContentY + ContentH - 18),
    100, 18, "Continue", ColBtnPrimary, PalLime, PalBlack)

proc updateDailyScene*(dt: float32) =
  updateHints(dt)

  if feedbackTimer > 0:
    feedbackTimer -= dt

  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneHome)
    return

  case phase
  of DailySetup:
    if not alreadyCompleted:
      if updateButton(startButton):
        phase = DailyMemorize
        currentViewCard = 0
        memorizeTimer = 0

  of DailyMemorize:
    memorizeTimer += dt

    if updateButton(prevCardButton):
      if currentViewCard > 0: currentViewCard -= 1
    if updateButton(nextCardButton):
      if currentViewCard < 51: currentViewCard += 1
    if updateButton(doneMemButton):
      phase = DailyRecall
      recallSelected = @[]

    if isKeyPressed(Left) and currentViewCard > 0: currentViewCard -= 1
    if isKeyPressed(Right) and currentViewCard < 51: currentViewCard += 1
    if isKeyPressed(Enter):
      phase = DailyRecall
      recallSelected = @[]

  of DailyRecall:
    memorizeTimer += dt

    if updateButton(undoButton):
      if recallSelected.len > 0: discard recallSelected.pop()

    let mp = gameMousePos()
    let cols = 13
    let gridW = cols * (CardSMW + 2)
    let startX = (ScreenW - int32(gridW)) div 2
    let startY = int32(ContentY + 4)

    for i in 0..<recallGrid.len:
      if recallGrid[i] in recallSelected: continue
      let col = i mod cols
      let row = i div cols
      let cx = float32(int32(startX) + int32(col) * (CardSMW + 2))
      let cy = float32(startY + int32(row) * (CardSMH + 2))
      let rect = Rectangle(x: cx, y: cy,
                            width: CardSMW.float32, height: CardSMH.float32)
      if checkCollisionPointRec(mp, rect) and isMouseButtonPressed(Left):
        let selectedCard = recallGrid[i]
        let pos = recallSelected.len
        recallSelected.add(selectedCard)

        # Instant feedback
        let isCorrect = pos < dailyDeck.len and selectedCard == dailyDeck[pos]
        lastFeedbackCorrect = isCorrect
        feedbackSlotIdx = pos
        feedbackTimer = 0.4

        if not isCorrect:
          if triggerShakeProc != nil:
            triggerShakeProc(1.5, 0.1)

        if recallSelected.len == 52:
          calculateDailyScore()
          phase = DailyResults
          if scoreAccuracy >= 0.5:
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 90), 40)

  of DailyResults:
    if updateButton(resultsContinueBtn):
      if changeSceneProc != nil:
        changeSceneProc(SceneHome)

proc drawDailyScene*() =
  drawHeader("DAILY CHALLENGE")
  drawButton(backButton)

  case phase
  of DailySetup:
    drawCenteredTextShadow("DAILY CHALLENGE", int32(ContentY + 8), FontMedium, PalGold)
    drawCenteredText("Full 52-card deck", int32(ContentY + 28), FontTiny, ColTextSecondary)
    drawCenteredText("Same puzzle for everyone today!", int32(ContentY + 40),
      FontTiny, ColTextSecondary)

    if playerDataPtr != nil:
      drawPixelText("Streak: " & $playerDataPtr[].streak & " days",
        int32(ContentMargin + 60), int32(ContentY + 56), FontTiny, PalOrange)
      drawPixelText("Best: " & $playerDataPtr[].bestStreak & " days",
        int32(ContentMargin + 60), int32(ContentY + 68), FontTiny, PalGray)

    if alreadyCompleted:
      drawCenteredTextShadow("Already completed today!", int32(ContentY + 84),
        FontTiny, ColCorrect)
      drawCenteredText("Come back tomorrow!", int32(ContentY + 98),
        FontTiny, ColTextSecondary)
    else:
      drawButton(startButton)

  of DailyMemorize:
    let timeStr = "Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s"
    drawPixelText(timeStr, int32(ScreenW - ContentMargin - 70),
      int32(HeaderY + 6), FontTiny, PalGold)

    let ci = dailyDeck[currentViewCard]
    let card = paoTable[ci].card
    let pao = paoTable[ci]

    let cardX = int32((ScreenW - CardLGW) div 2)
    let cardY = int32(ContentY + 4)
    drawCardFace(card, cardX, cardY, CardLGW, CardLGH)

    drawCenteredText(pao.person & " " & pao.action & " " & pao.obj,
      int32(ContentY + 72), FontTiny, PalGold)

    let progress = $(currentViewCard + 1) & " / 52"
    drawCenteredText(progress, int32(ContentY + 84), FontTiny, ColTextSecondary)

    drawButton(prevCardButton)
    drawButton(nextCardButton)
    drawButton(doneMemButton)

  of DailyRecall:
    drawPixelText($recallSelected.len & "/52",
      int32(ScreenW - ContentMargin - 30), int32(HeaderY + 6), FontTiny, PalGold)

    let cols = 13
    let gridW = cols * (CardSMW + 2)
    let startX = (ScreenW - int32(gridW)) div 2
    let startY = int32(ContentY + 4)

    for i in 0..<recallGrid.len:
      let col = i mod cols
      let row = i div cols
      let cx = int32(startX) + int32(col) * (CardSMW + 2)
      let cy = startY + int32(row) * (CardSMH + 2)

      if recallGrid[i] in recallSelected:
        drawRectangle(cx, cy, CardSMW, CardSMH,
          Color(r: 40, g: 40, b: 50, a: 255))
      else:
        let card = paoTable[recallGrid[i]].card
        drawCardFace(card, cx, cy, CardSMW, CardSMH)

    # Feedback flash
    if feedbackTimer > 0 and feedbackSlotIdx < recallSelected.len:
      let alpha = uint8(feedbackTimer / 0.4 * 120)
      let flashCol = if lastFeedbackCorrect:
        Color(r: ColCorrect.r, g: ColCorrect.g, b: ColCorrect.b, a: alpha)
      else:
        Color(r: ColWrong.r, g: ColWrong.g, b: ColWrong.b, a: alpha)
      let flashX = int32(ContentMargin + feedbackSlotIdx * 6)
      let flashY = int32(HintBarY - 8)
      drawRectangle(flashX, flashY, 5, 6, flashCol)

    drawButton(undoButton)

  of DailyResults:
    drawCenteredTextShadow("DAILY RESULTS", int32(ContentY + 4), FontMedium, PalGold)
    drawCenteredTextShadow("Score: " & $scoreFinal, int32(ContentY + 24),
      FontMedium, PalGold)

    let accPct = int(scoreAccuracy * 100)
    drawCenteredText("Accuracy: " & $accPct & "%", int32(ContentY + 44), FontTiny,
      if scoreAccuracy >= 0.5: ColCorrect else: ColWrong)
    drawCenteredText("Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s",
      int32(ContentY + 56), FontTiny, ColTextSecondary)

    if playerDataPtr != nil:
      drawCenteredText("Streak: " & $playerDataPtr[].streak & " days!",
        int32(ContentY + 70), FontTiny, PalOrange)

    # Show top 3 mistakes with PAO
    if mistakes.len > 0:
      drawPixelText("Top mistakes:", int32(ContentMargin), int32(ContentY + 84),
        FontTiny, ColWrong)
      for i in 0..<min(mistakes.len, 3):
        let m = mistakes[i]
        let correctPao = paoTable[m.correctCardIdx]
        let correctCard = correctPao.card
        let y = int32(ContentY + 94 + i * 12)
        drawPixelText("Pos " & $(m.position + 1) & ": " &
          rankChar(correctCard.rank) & suitChar(correctCard.suit) & " = " &
          correctPao.person, int32(ContentMargin), y, FontTiny, PalLightGray)

    drawButton(resultsContinueBtn)

  # Hint bar
  drawHintBar()

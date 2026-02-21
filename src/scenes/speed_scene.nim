## Speed Cards Scene: WMC Championship discipline
## Full 52-card deck, memorize one at a time, then recall in order

import raylib
import std/[strutils, math]
import ../types, ../palette, ../design, ../ui, ../animation, ../renderer, ../cards,
       ../input_manager, ../player, ../storage, ../hints

var
  phase: SpeedPhase
  speedDeck: seq[int]
  currentCard: int
  memorizeTimer: float32
  recallTimer: float32
  countdownTimer: float32
  countdownValue: int
  recallSelected: seq[int]
  recallGrid: seq[int]  # shuffled grid for recall picking
  speedAccuracy: float32
  mistakes: seq[MistakeRecord]
  speedTotalCards: int

  # Per-card feedback
  lastFeedbackCorrect: bool
  feedbackTimer: float32
  feedbackSlotIdx: int

  # Multi-deck
  speedDeckCount: int = 1
  speedDeckButtons: array[5, PixelButton]
  speedMultiDeckUnlocked: bool

  # Recall pagination
  speedRecallPage: int
  speedRecallPageCount: int
  speedRecallUsedPositions: seq[int]

  # UI
  backButton: PixelButton
  goButton: PixelButton
  stopButton: PixelButton
  prevCardButton: PixelButton
  nextCardButton: PixelButton
  undoButton: PixelButton
  tryAgainButton: PixelButton
  homeButton: PixelButton

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32; duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

proc initSpeedScene*() =
  phase = SpeedReady
  speedDeck = @[]
  currentCard = 0
  memorizeTimer = 0
  recallTimer = 0
  countdownTimer = 0
  recallSelected = @[]
  speedRecallUsedPositions = @[]
  mistakes = @[]
  feedbackTimer = 0
  speedRecallPage = 0
  speedRecallPageCount = 1
  speedDeckCount = 1
  speedTotalCards = 52
  setHintCategory(HintSpeed)

  # Check multi-deck unlock: 3+ attempts OR 40+ mastered
  speedMultiDeckUnlocked = false
  if playerDataPtr != nil:
    speedMultiDeckUnlocked = playerDataPtr[].speedAttempts >= 3 or
                             masteredCardCount(playerDataPtr[]) >= 40

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  goButton = newPixelButton((ScreenW.float32 - 100) / 2,
    float32(ContentY + 80), 100, 24, "GO!", ColBtnPrimary, PalLime, PalBlack)

  # Deck count buttons
  let dcBtnW: float32 = 28
  let dcGap: float32 = 4
  let dcTotalW = dcBtnW * 5 + dcGap * 4
  let dcStartX = (ScreenW.float32 - dcTotalW) / 2
  for i in 0..4:
    let label = $(i + 1) & "x"
    speedDeckButtons[i] = newPixelButton(
      dcStartX + float32(i) * (dcBtnW + dcGap),
      float32(ContentY + 66), dcBtnW, 14,
      label, PalBlueDark, PalBlue, PalWhite)

proc startCountdown() =
  phase = SpeedCountdown
  countdownValue = 3
  countdownTimer = 1.0

proc startMemorize() =
  phase = SpeedMemorize
  if speedDeckCount > 1:
    speedDeck = newMultiDeck(speedDeckCount)
  else:
    speedDeck = newDeck()
    shuffleDeck(speedDeck)
  speedTotalCards = speedDeck.len
  currentCard = 0
  memorizeTimer = 0

  let btnY = float32(ContentY + ContentH - 18)
  prevCardButton = newPixelButton(float32(ContentMargin + 4), btnY, 50, 16,
    "< Prev", PalGrayDark, PalGray, PalWhite)
  nextCardButton = newPixelButton(float32(ScreenW - ContentMargin - 54), btnY, 50, 16,
    "Next >", PalGrayDark, PalGray, PalWhite)
  stopButton = newPixelButton((ScreenW.float32 - 60) / 2, btnY, 60, 16,
    "STOP", PalRedDark, PalRed, PalWhite)

proc startRecall() =
  phase = SpeedRecall
  recallTimer = 0
  recallSelected = @[]
  speedRecallUsedPositions = @[]
  feedbackTimer = 0
  speedRecallPage = 0
  speedRecallPageCount = int(ceil(float32(speedTotalCards) / 52.0))

  # Shuffle grid for recall
  recallGrid = speedDeck
  var gridCopy = recallGrid
  for i in countdown(gridCopy.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(gridCopy[i], gridCopy[j])
  recallGrid = gridCopy

  undoButton = newPixelButton(4, float32(HintBarY - 18), 40, 16,
    "Undo", PalRedDark, PalRed, PalWhite)

proc calculateSpeedResults() =
  var correct = 0
  mistakes = @[]
  for i in 0..<min(recallSelected.len, speedDeck.len):
    if recallSelected[i] == speedDeck[i]:
      correct += 1
    else:
      mistakes.add(MistakeRecord(
        position: i,
        pickedCardIdx: recallSelected[i],
        correctCardIdx: speedDeck[i],
      ))
  speedAccuracy = float32(correct) / float32(speedTotalCards)

  let totalTime = memorizeTimer + recallTimer
  if playerDataPtr != nil:
    if speedDeckCount > 1:
      discard recordMultiDeckResult(playerDataPtr[], speedDeckCount, totalTime, speedAccuracy)
    else:
      discard recordSpeedResult(playerDataPtr[], totalTime, memorizeTimer, speedAccuracy)
    savePlayerData(playerDataPtr[])
    if gameFloatingTexts != nil:
      spawnFloatingText(gameFloatingTexts[], "+75 XP", 160, 50, PalGold)

  phase = SpeedResults
  tryAgainButton = newPixelButton((ScreenW.float32 - 100) / 2 - 56,
    float32(ContentY + ContentH - 20), 100, 18,
    "Try Again", ColBtnPrimary, PalLime, PalBlack)
  homeButton = newPixelButton((ScreenW.float32 - 100) / 2 + 56,
    float32(ContentY + ContentH - 20), 100, 18,
    "Home", ColBtnSecondary, PalSkyBlue, PalWhite)

proc speedBenchmark(memTime: float32): string =
  if memTime < 30: "World Class"
  elif memTime < 60: "Grandmaster"
  elif memTime < 120: "Expert"
  elif memTime < 300: "Advanced"
  elif memTime < 600: "Intermediate"
  else: "Beginner"

proc updateSpeedScene*(dt: float32) =
  updateHints(dt)

  if feedbackTimer > 0:
    feedbackTimer -= dt

  if updateButton(backButton):
    case phase
    of SpeedReady:
      if changeSceneProc != nil:
        changeSceneProc(SceneHome)
    of SpeedCountdown, SpeedMemorize, SpeedRecall:
      phase = SpeedReady
    of SpeedResults:
      phase = SpeedReady
    return

  case phase
  of SpeedReady:
    if speedMultiDeckUnlocked:
      for i in 0..4:
        if updateButton(speedDeckButtons[i]):
          speedDeckCount = i + 1

    if updateButton(goButton):
      startCountdown()

  of SpeedCountdown:
    countdownTimer -= dt
    if countdownTimer <= 0:
      countdownValue -= 1
      if countdownValue <= 0:
        startMemorize()
      else:
        countdownTimer = 1.0

  of SpeedMemorize:
    memorizeTimer += dt

    if updateButton(prevCardButton):
      if currentCard > 0: currentCard -= 1
    if updateButton(nextCardButton):
      if currentCard < speedTotalCards - 1: currentCard += 1
    if updateButton(stopButton):
      startRecall()

    if isKeyPressed(Left) and currentCard > 0: currentCard -= 1
    if isKeyPressed(Right) and currentCard < speedTotalCards - 1: currentCard += 1
    if isKeyPressed(Enter):
      startRecall()

  of SpeedRecall:
    recallTimer += dt

    if updateButton(undoButton):
      if recallSelected.len > 0:
        discard recallSelected.pop()
        if speedRecallUsedPositions.len > 0:
          discard speedRecallUsedPositions.pop()

    # Page navigation for multi-deck
    if speedRecallPageCount > 1:
      if isKeyPressed(RightBracket) and speedRecallPage < speedRecallPageCount - 1:
        speedRecallPage += 1
      if isKeyPressed(LeftBracket) and speedRecallPage > 0:
        speedRecallPage -= 1

    let mp = gameMousePos()
    let pageStart = speedRecallPage * 52
    let pageEnd = min(pageStart + 52, recallGrid.len)
    let pageCards = pageEnd - pageStart
    let cols = min(pageCards, 13)
    let gridW = cols * (CardSMW + 2)
    let startX = (ScreenW - int32(gridW)) div 2
    let startY = int32(ContentY + 4)

    for idx in pageStart..<pageEnd:
      let i = idx - pageStart
      if idx in speedRecallUsedPositions: continue
      let col = i mod cols
      let row = i div cols
      let cx = float32(int32(startX) + int32(col) * (CardSMW + 2))
      let cy = float32(startY + int32(row) * (CardSMH + 2))
      let rect = Rectangle(x: cx, y: cy,
                            width: CardSMW.float32, height: CardSMH.float32)
      if checkCollisionPointRec(mp, rect) and isMouseButtonPressed(Left):
        let selectedCard = recallGrid[idx]
        let pos = recallSelected.len
        recallSelected.add(selectedCard)
        speedRecallUsedPositions.add(idx)

        # Instant feedback
        let isCorrect = pos < speedDeck.len and selectedCard == speedDeck[pos]
        lastFeedbackCorrect = isCorrect
        feedbackSlotIdx = pos
        feedbackTimer = 0.4

        if not isCorrect:
          if triggerShakeProc != nil:
            triggerShakeProc(1.5, 0.1)

        if recallSelected.len == speedTotalCards:
          calculateSpeedResults()
          if speedAccuracy >= 0.5:
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 90), 40)

  of SpeedResults:
    if updateButton(tryAgainButton):
      phase = SpeedReady
    if updateButton(homeButton):
      if changeSceneProc != nil:
        changeSceneProc(SceneHome)

proc drawSpeedScene*() =
  drawHeader("SPEED CARDS")
  drawButton(backButton)

  case phase
  of SpeedReady:
    drawCenteredTextShadow("SPEED CARDS", int32(ContentY + 8), FontMedium, PalGold)
    drawCenteredText("WMC Discipline", int32(ContentY + 26), FontTiny, ColTextSecondary)

    drawCenteredText("Memorize all cards in order,", int32(ContentY + 40),
      FontTiny, PalLightGray)
    drawCenteredText("then recall them from memory.", int32(ContentY + 50),
      FontTiny, PalLightGray)

    # Soft gate warning if not enough mastered cards
    if playerDataPtr != nil and masteredCardCount(playerDataPtr[]) < 12:
      drawCenteredText("Learn at least 12 cards first!",
        int32(ContentY + 60), FontTiny, PalOrange)

    # Multi-deck selector
    if speedMultiDeckUnlocked:
      drawPixelText("Decks:", int32(ContentMargin), int32(ContentY + 68), FontTiny, PalGray)
      for i in 0..4:
        var btn = speedDeckButtons[i]
        if i + 1 == speedDeckCount:
          btn.color = ColBtnPrimary
          btn.hoverColor = PalLime
          btn.textColor = PalBlack
        drawButton(btn)

    # Show personal best (below deck selector or in its place)
    let pbY = if speedMultiDeckUnlocked: ContentY + 82 else: ContentY + 62
    if playerDataPtr != nil:
      if speedDeckCount == 1 and playerDataPtr[].speedBestTime > 0:
        let pb = playerDataPtr[].speedBestTime
        drawCenteredText("PB: " & formatFloat(pb, ffDecimal, 1) & "s  " &
          speedBenchmark(playerDataPtr[].speedBestMemorizeTime),
          int32(pbY), FontTiny, PalGold)
      elif speedDeckCount > 1:
        let mdIdx = speedDeckCount - 1
        let bestTime = playerDataPtr[].multiDeckBestTimes[mdIdx]
        if bestTime > 0:
          drawCenteredText("PB " & $speedDeckCount & "x: " &
            formatFloat(bestTime, ffDecimal, 1) & "s",
            int32(pbY), FontTiny, PalGold)

    drawButton(goButton)

  of SpeedCountdown:
    drawCenteredTextShadow($countdownValue, int32(ContentY + 40),
      FontLarge, PalGold)

  of SpeedMemorize:
    # Timer prominently
    let timeStr = formatFloat(memorizeTimer, ffDecimal, 1) & "s"
    drawPixelText(timeStr, int32(ScreenW - ContentMargin - 40),
      int32(HeaderY + 6), FontTiny, PalGold)

    let ci = speedDeck[currentCard]
    let card = paoTable[ci].card
    let pao = paoTable[ci]

    # Large card
    let cardX = int32((ScreenW - CardLGW) div 2)
    let cardY = int32(ContentY + 4)
    drawCardFace(card, cardX, cardY, CardLGW, CardLGH)

    # PAO text below card
    let infoY = int32(ContentY + 72)
    drawCenteredText(pao.person & " " & pao.action & " " & pao.obj,
      infoY, FontTiny, PalGold)

    # Progress bar
    let progW: int32 = 200
    let progX = int32((ScreenW - progW) div 2)
    let progY = infoY + 14
    drawProgressBar(progX, progY, progW, 4,
      float32(currentCard + 1) / float32(speedTotalCards), PalGrayDark, PalCyan)
    drawCenteredText($(currentCard + 1) & "/" & $speedTotalCards, progY + 6, FontTiny, ColTextSecondary)

    drawButton(prevCardButton)
    drawButton(nextCardButton)
    drawButton(stopButton)

  of SpeedRecall:
    # Header with page info for multi-deck
    if speedRecallPageCount > 1:
      drawPixelText("Page " & $(speedRecallPage + 1) & "/" & $speedRecallPageCount,
        int32(ContentMargin), int32(HeaderY + 6), FontTiny, PalWhite)
    drawPixelText($recallSelected.len & "/" & $speedTotalCards,
      int32(ScreenW - ContentMargin - 30), int32(HeaderY + 6), FontTiny, PalGold)

    let pageStart = speedRecallPage * 52
    let pageEnd = min(pageStart + 52, recallGrid.len)
    let pageCards = pageEnd - pageStart
    let cols = min(pageCards, 13)
    let gridW = cols * (CardSMW + 2)
    let startX = (ScreenW - int32(gridW)) div 2
    let startY = int32(ContentY + 4)

    for idx in pageStart..<pageEnd:
      let i = idx - pageStart
      let col = i mod cols
      let row = i div cols
      let cx = int32(startX) + int32(col) * (CardSMW + 2)
      let cy = startY + int32(row) * (CardSMH + 2)

      if idx in speedRecallUsedPositions:
        drawRectangle(cx, cy, CardSMW, CardSMH,
          Color(r: 40, g: 40, b: 50, a: 255))
      else:
        let card = paoTable[recallGrid[idx]].card
        drawCardFace(card, cx, cy, CardSMW, CardSMH)

    # Page navigation arrows
    if speedRecallPageCount > 1:
      if speedRecallPage > 0:
        drawPixelText("[", 2, int32(ContentY + ContentH div 2), FontSmall, PalGold)
      if speedRecallPage < speedRecallPageCount - 1:
        drawPixelText("]", int32(ScreenW - 10), int32(ContentY + ContentH div 2), FontSmall, PalGold)

    # Feedback flash
    if feedbackTimer > 0 and feedbackSlotIdx < recallSelected.len:
      let alpha = uint8(feedbackTimer / 0.4 * 120)
      let flashCol = if lastFeedbackCorrect:
        Color(r: ColCorrect.r, g: ColCorrect.g, b: ColCorrect.b, a: alpha)
      else:
        Color(r: ColWrong.r, g: ColWrong.g, b: ColWrong.b, a: alpha)
      let flashX = int32(ContentMargin + (feedbackSlotIdx mod 52) * 6)
      let flashY = int32(HintBarY - 8)
      drawRectangle(flashX, flashY, 5, 6, flashCol)

    drawButton(undoButton)

  of SpeedResults:
    let totalTime = memorizeTimer + recallTimer
    drawCenteredTextShadow("SPEED RESULTS", int32(ContentY + 2), FontMedium, PalGold)

    # Multi-deck context
    if speedDeckCount > 1:
      drawCenteredText($speedDeckCount & " decks (" & $speedTotalCards & " cards)",
        int32(ContentY + 16), FontTiny, PalCyan)

    let baseY = if speedDeckCount > 1: ContentY + 22 else: ContentY + 16

    # Total time
    drawCenteredText("Total: " & formatFloat(totalTime, ffDecimal, 1) & "s",
      int32(baseY + 4), FontSmall, ColTextPrimary)

    # Breakdown
    drawCenteredText("Memorize: " & formatFloat(memorizeTimer, ffDecimal, 1) &
      "s  |  Recall: " & formatFloat(recallTimer, ffDecimal, 1) & "s",
      int32(baseY + 18), FontTiny, ColTextSecondary)

    # Accuracy
    let accPct = int(speedAccuracy * 100)
    let accCol = if speedAccuracy >= 0.8: ColCorrect
                 elif speedAccuracy >= 0.5: PalGold
                 else: ColWrong
    drawCenteredText("Accuracy: " & $accPct & "%", int32(baseY + 32),
      FontSmall, accCol)

    # WMC benchmark (only for 1-deck) or per-card time tier
    if speedDeckCount == 1:
      let bench = speedBenchmark(memorizeTimer)
      drawCenteredText(bench, int32(baseY + 48), FontSmall, PalGold)
    else:
      let secsPerCard = totalTime / float32(speedTotalCards)
      let tier = tierForTime(secsPerCard)
      drawCenteredText(tierName(tier) & " (" &
        formatFloat(secsPerCard, ffDecimal, 1) & "s/card)",
        int32(baseY + 48), FontTiny, PalGold)

    # Personal best
    if playerDataPtr != nil:
      if speedDeckCount == 1 and playerDataPtr[].speedBestTime > 0:
        drawCenteredText("PB: " & formatFloat(playerDataPtr[].speedBestTime, ffDecimal, 1) & "s",
          int32(baseY + 62), FontTiny, PalCyan)
      elif speedDeckCount > 1:
        let mdIdx = speedDeckCount - 1
        if playerDataPtr[].multiDeckBestTimes[mdIdx] > 0:
          drawCenteredText("PB " & $speedDeckCount & "x: " &
            formatFloat(playerDataPtr[].multiDeckBestTimes[mdIdx], ffDecimal, 1) & "s",
            int32(baseY + 62), FontTiny, PalCyan)

    # Top mistakes
    if mistakes.len > 0:
      drawPixelText("Mistakes: " & $mistakes.len & "/" & $speedTotalCards,
        int32(ContentMargin), int32(baseY + 76), FontTiny, ColWrong)
      for i in 0..<min(mistakes.len, 2):
        let m = mistakes[i]
        let correctPao = paoTable[m.correctCardIdx]
        let correctCard = correctPao.card
        let y = int32(baseY + 86 + i * 10)
        drawPixelText("Pos " & $(m.position + 1) & ": " &
          rankChar(correctCard.rank) & suitChar(correctCard.suit) & " = " &
          correctPao.person, int32(ContentMargin), y, FontTiny, PalLightGray)

    drawButton(tryAgainButton)
    drawButton(homeButton)

  # Hint bar
  drawHintBar()

## Practice Scene: Adaptive timed memorize -> recall with instant feedback + mistake analysis

import raylib
import std/[strutils, math]
import ../types, ../palette, ../design, ../ui, ../animation, ../renderer, ../cards,
       ../input_manager, ../player, ../storage, ../hints

var
  phase: PracticePhase
  practiceDeck: seq[int]
  cardCount: int
  suggestedCount: int
  currentViewCard: int
  memorizeTimer: float32
  recallSelected: seq[int]
  recallGrid: seq[int]
  mistakes: seq[MistakeRecord]
  scoreAccuracy: float32
  totalTime: float32
  totalCards: int  # actual total (may differ from cardCount for multi-deck)

  # Per-card feedback
  lastFeedbackCorrect: bool
  feedbackTimer: float32
  feedbackSlotIdx: int  # which slot got feedback

  # Multi-deck
  deckCount: int = 1
  deckCountButtons: array[5, PixelButton]
  multiDeckUnlocked: bool

  # Recall pagination
  recallPage: int
  recallPageCount: int
  recallUsedPositions: seq[int]  # grid positions already picked (for duplicate cards)

  # UI
  backButton: PixelButton
  countButtons: array[4, PixelButton]
  startButton: PixelButton
  prevCardButton: PixelButton
  nextCardButton: PixelButton
  doneMemButton: PixelButton
  undoButton: PixelButton
  resultsContinueBtn: PixelButton
  resultsScrollY: int

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32; duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

# Mastery thresholds for card count unlocks: 5=0, 13=8, 26=20, 52=40
const CountMasteryReq: array[4, int] = [0, 8, 20, 40]

proc isCountUnlocked(idx: int): bool =
  if playerDataPtr == nil: return idx == 0
  masteredCardCount(playerDataPtr[]) >= CountMasteryReq[idx]

proc initPracticeScene*() =
  phase = PracticeSetup
  practiceDeck = @[]
  recallSelected = @[]
  recallGrid = @[]
  recallUsedPositions = @[]
  mistakes = @[]
  memorizeTimer = 0
  feedbackTimer = 0
  resultsScrollY = 0
  recallPage = 0
  recallPageCount = 1
  deckCount = 1
  setHintCategory(HintPractice)

  # Determine suggested count
  suggestedCount = 5
  if playerDataPtr != nil:
    suggestedCount = suggestedCardCount(playerDataPtr[])
  cardCount = suggestedCount

  # Check multi-deck unlock: 52 cards AND 40+ mastered
  multiDeckUnlocked = false
  if playerDataPtr != nil:
    multiDeckUnlocked = masteredCardCount(playerDataPtr[]) >= 40

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)

  # Card count buttons
  let btnW: float32 = 56
  let btnH: float32 = 18
  let totalW = btnW * 4 + float32(SpaceSM * 3)
  let startX = (ScreenW.float32 - totalW) / 2
  for i in 0..3:
    let x = startX + float32(i) * (btnW + SpaceSM.float32)
    let label = $PracticeCardCounts[i] & " cards"
    countButtons[i] = newPixelButton(x, float32(ContentY + 40), btnW, btnH,
      label, PalBlueDark, PalBlue, PalWhite)

  # Deck count selector buttons (1x-5x)
  let dcBtnW: float32 = 28
  let dcGap: float32 = 4
  let dcTotalW = dcBtnW * 5 + dcGap * 4
  let dcStartX = (ScreenW.float32 - dcTotalW) / 2
  for i in 0..4:
    let label = $(i + 1) & "x"
    deckCountButtons[i] = newPixelButton(
      dcStartX + float32(i) * (dcBtnW + dcGap),
      float32(ContentY + 62), dcBtnW, 14,
      label, PalBlueDark, PalBlue, PalWhite)

  startButton = newPixelButton((ScreenW.float32 - 100) / 2,
    float32(ContentY + 80), 100, 20, "Start!", ColBtnPrimary, PalLime, PalBlack)

proc startPractice() =
  if deckCount > 1 and cardCount == 52:
    practiceDeck = newMultiDeck(deckCount)
  else:
    practiceDeck = newDeck()
    shuffleDeck(practiceDeck)
    practiceDeck.setLen(cardCount)

  totalCards = practiceDeck.len
  currentViewCard = 0
  memorizeTimer = 0
  recallSelected = @[]
  recallUsedPositions = @[]
  mistakes = @[]
  feedbackTimer = 0
  recallPage = 0
  recallPageCount = int(ceil(float32(totalCards) / 52.0))

  # Prepare shuffled recall grid
  recallGrid = practiceDeck
  var gridCopy = recallGrid
  for i in countdown(gridCopy.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(gridCopy[i], gridCopy[j])
  recallGrid = gridCopy

  phase = PracticeMemorize

  let btnY = float32(ContentY + ContentH - 18)
  prevCardButton = newPixelButton(float32(ContentMargin + 4), btnY, 50, 16,
    "< Prev", PalGrayDark, PalGray, PalWhite)
  nextCardButton = newPixelButton(float32(ScreenW - ContentMargin - 54), btnY, 50, 16,
    "Next >", PalGrayDark, PalGray, PalWhite)
  doneMemButton = newPixelButton((ScreenW.float32 - 60) / 2, btnY, 60, 16,
    "Done!", PalGreen, PalLime, PalBlack)

proc calculateResults() =
  var correct = 0
  mistakes = @[]
  for i in 0..<min(recallSelected.len, practiceDeck.len):
    if recallSelected[i] == practiceDeck[i]:
      correct += 1
    else:
      mistakes.add(MistakeRecord(
        position: i,
        pickedCardIdx: recallSelected[i],
        correctCardIdx: practiceDeck[i],
      ))
  scoreAccuracy = if practiceDeck.len > 0:
    float32(correct) / float32(practiceDeck.len)
  else: 0
  totalTime = memorizeTimer

  if playerDataPtr != nil:
    if deckCount > 1:
      discard recordMultiDeckResult(playerDataPtr[], deckCount, totalTime, scoreAccuracy)
    else:
      discard recordPracticeResult(playerDataPtr[], cardCount, totalTime, scoreAccuracy)
    savePlayerData(playerDataPtr[])
    if gameFloatingTexts != nil:
      spawnFloatingText(gameFloatingTexts[], "+25 XP", 160, 60, PalGold)

  resultsContinueBtn = newPixelButton(
    (ScreenW.float32 - 100) / 2, float32(ContentY + ContentH - 18),
    100, 18, "Continue", ColBtnPrimary, PalLime, PalBlack)

proc updatePracticeScene*(dt: float32) =
  updateHints(dt)

  if feedbackTimer > 0:
    feedbackTimer -= dt

  if updateButton(backButton):
    case phase
    of PracticeSetup:
      if changeSceneProc != nil:
        changeSceneProc(SceneHome)
    of PracticeMemorize, PracticeRecall:
      phase = PracticeSetup
    of PracticeResults:
      phase = PracticeSetup
    return

  case phase
  of PracticeSetup:
    for i in 0..3:
      if isCountUnlocked(i):
        if updateButton(countButtons[i]):
          cardCount = PracticeCardCounts[i]
          if cardCount != 52:
            deckCount = 1
      else:
        discard updateButton(countButtons[i])

    # Deck count selector (only when 52 cards AND unlocked)
    if cardCount == 52 and multiDeckUnlocked:
      for i in 0..4:
        if updateButton(deckCountButtons[i]):
          deckCount = i + 1

    if updateButton(startButton):
      startPractice()

  of PracticeMemorize:
    memorizeTimer += dt

    if updateButton(prevCardButton):
      if currentViewCard > 0: currentViewCard -= 1
    if updateButton(nextCardButton):
      if currentViewCard < totalCards - 1: currentViewCard += 1
    if updateButton(doneMemButton):
      phase = PracticeRecall
      recallSelected = @[]
      recallUsedPositions = @[]
      recallPage = 0
      undoButton = newPixelButton(4, float32(HintBarY - 18), 40, 16,
        "Undo", PalRedDark, PalRed, PalWhite)

    if isKeyPressed(Left) and currentViewCard > 0: currentViewCard -= 1
    if isKeyPressed(Right) and currentViewCard < totalCards - 1: currentViewCard += 1
    if isKeyPressed(Enter):
      phase = PracticeRecall
      recallSelected = @[]
      recallUsedPositions = @[]
      recallPage = 0

  of PracticeRecall:
    memorizeTimer += dt  # Continue timing during recall

    if updateButton(undoButton):
      if recallSelected.len > 0:
        discard recallSelected.pop()
        if recallUsedPositions.len > 0:
          discard recallUsedPositions.pop()

    # Page navigation for multi-deck ([ and ] keys)
    if recallPageCount > 1:
      if isKeyPressed(RightBracket) and recallPage < recallPageCount - 1:
        recallPage += 1
      if isKeyPressed(LeftBracket) and recallPage > 0:
        recallPage -= 1

    let mp = gameMousePos()
    let pageStart = recallPage * 52
    let pageEnd = min(pageStart + 52, recallGrid.len)
    let pageCards = pageEnd - pageStart
    let cols = min(pageCards, 13)
    let gridW = cols * (CardSMW + 2)
    let startX = (ScreenW - int32(gridW)) div 2
    let startY = int32(ContentY + 4)

    for idx in pageStart..<pageEnd:
      let i = idx - pageStart  # local index within page
      if idx in recallUsedPositions: continue
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
        recallUsedPositions.add(idx)

        # Instant per-card feedback
        let isCorrect = pos < practiceDeck.len and selectedCard == practiceDeck[pos]
        lastFeedbackCorrect = isCorrect
        feedbackSlotIdx = pos
        feedbackTimer = 0.4

        if not isCorrect:
          if triggerShakeProc != nil:
            triggerShakeProc(1.5, 0.1)

        if recallSelected.len == totalCards:
          calculateResults()
          phase = PracticeResults
          if scoreAccuracy >= 0.8:
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 90), 30)

  of PracticeResults:
    if updateButton(resultsContinueBtn):
      phase = PracticeSetup

    # Scroll mistakes with keys
    if isKeyPressed(Down) and resultsScrollY < max(0, mistakes.len - 3):
      resultsScrollY += 1
    if isKeyPressed(Up) and resultsScrollY > 0:
      resultsScrollY -= 1

proc drawPracticeScene*() =
  drawHeader("PRACTICE")
  drawButton(backButton)

  case phase
  of PracticeSetup:
    drawCenteredText("Timed Card Recall", int32(ContentY + 4), FontSmall, ColTextAccent)

    # Suggested count indicator
    drawCenteredText("Suggested: " & $suggestedCount & " cards",
      int32(ContentY + 22), FontTiny, PalGray)

    # Count buttons with highlight for selected / locked state
    for i in 0..3:
      var btn = countButtons[i]
      if not isCountUnlocked(i):
        btn.color = PalGrayDark
        btn.hoverColor = PalGrayDark
        btn.textColor = PalGray
        btn.label = $PracticeCardCounts[i] & " [lock]"
      elif PracticeCardCounts[i] == cardCount:
        btn.color = ColBtnPrimary
        btn.hoverColor = PalLime
        btn.textColor = PalBlack
      drawButton(btn)

    # Deck count selector
    if cardCount == 52 and multiDeckUnlocked:
      drawPixelText("Decks:", int32(ContentMargin), int32(ContentY + 64), FontTiny, PalGray)
      for i in 0..4:
        var btn = deckCountButtons[i]
        if i + 1 == deckCount:
          btn.color = ColBtnPrimary
          btn.hoverColor = PalLime
          btn.textColor = PalBlack
        drawButton(btn)

    # Best scores
    if playerDataPtr != nil:
      let bestY = if cardCount == 52 and multiDeckUnlocked: ContentY + 78 else: ContentY + 64
      if deckCount > 1:
        let mdIdx = deckCount - 1
        let bestTime = playerDataPtr[].multiDeckBestTimes[mdIdx]
        let bestAcc = playerDataPtr[].multiDeckBestAccuracy[mdIdx]
        if bestTime > 0:
          drawPixelText("Best " & $deckCount & "x: " & formatFloat(bestTime, ffDecimal, 1) & "s, " &
            $int(bestAcc * 100) & "%",
            int32(ContentMargin), int32(bestY), FontTiny, PalGray)
      else:
        let idx = practiceCountIndex(cardCount)
        let bestTime = playerDataPtr[].practiceBestTimes[idx]
        let bestAcc = playerDataPtr[].practiceBestAccuracy[idx]
        if bestTime > 0:
          drawPixelText("Best: " & formatFloat(bestTime, ffDecimal, 1) & "s, " &
            $int(bestAcc * 100) & "% accuracy",
            int32(ContentMargin), int32(bestY), FontTiny, PalGray)

    drawButton(startButton)

  of PracticeMemorize:
    let timeStr = "Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s"
    drawPixelText(timeStr, int32(ScreenW - ContentMargin - 70),
      int32(HeaderY + 6), FontTiny, PalGold)

    let ci = practiceDeck[currentViewCard]
    let card = paoTable[ci].card
    let pao = paoTable[ci]

    let cardX = int32((ScreenW - CardLGW) div 2)
    let cardY = int32(ContentY + 4)
    drawCardFace(card, cardX, cardY, CardLGW, CardLGH)

    # PAO info
    let infoY = int32(ContentY + 72)
    drawCenteredText(pao.person & " " & pao.action & " " & pao.obj,
      infoY, FontTiny, PalGold)

    let progress = $(currentViewCard + 1) & " / " & $totalCards
    drawCenteredText(progress, infoY + 12, FontTiny, ColTextSecondary)

    drawButton(prevCardButton)
    drawButton(nextCardButton)
    drawButton(doneMemButton)

  of PracticeRecall:
    # Header info
    let headerLabel = if recallPageCount > 1:
      "Page " & $(recallPage + 1) & "/" & $recallPageCount
    else: "Pick cards in order!"
    drawPixelText(headerLabel,
      int32(ContentMargin), int32(HeaderY + 6), FontTiny, PalWhite)
    drawPixelText($recallSelected.len & "/" & $totalCards,
      int32(ScreenW - ContentMargin - 30), int32(HeaderY + 6), FontTiny, PalGold)

    let pageStart = recallPage * 52
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

      if idx in recallUsedPositions:
        drawRectangle(cx, cy, CardSMW, CardSMH,
          Color(r: 40, g: 40, b: 50, a: 255))
      else:
        let card = paoTable[recallGrid[idx]].card
        drawCardFace(card, cx, cy, CardSMW, CardSMH)

    # Page navigation arrows
    if recallPageCount > 1:
      if recallPage > 0:
        drawPixelText("[", 2, int32(ContentY + ContentH div 2), FontSmall, PalGold)
      if recallPage < recallPageCount - 1:
        drawPixelText("]", int32(ScreenW - 10), int32(ContentY + ContentH div 2), FontSmall, PalGold)

    # Feedback flash on selected slots
    if feedbackTimer > 0 and feedbackSlotIdx < recallSelected.len:
      let alpha = uint8(feedbackTimer / 0.4 * 120)
      let flashCol = if lastFeedbackCorrect:
        Color(r: ColCorrect.r, g: ColCorrect.g, b: ColCorrect.b, a: alpha)
      else:
        Color(r: ColWrong.r, g: ColWrong.g, b: ColWrong.b, a: alpha)
      let flashX = int32(ContentMargin + (feedbackSlotIdx mod 20) * 14)
      let flashY = int32(HintBarY - 14)
      drawRectangle(flashX, flashY, 12, 10, flashCol)

    # Selected order at bottom (last 20)
    let selY = int32(HintBarY - 14)
    let selStart = max(0, recallSelected.len - 20)
    for i in selStart..<recallSelected.len:
      let card = paoTable[recallSelected[i]].card
      let rk = rankChar(card.rank)
      let isCorrect = i < practiceDeck.len and recallSelected[i] == practiceDeck[i]
      let col = if isCorrect: ColCorrect else: ColWrong
      drawPixelText(rk, int32(ContentMargin + (i - selStart) * 14), selY, FontTiny, col)

    drawButton(undoButton)

  of PracticeResults:
    drawCenteredTextShadow("RESULTS", int32(ContentY + 2), FontMedium, PalGold)

    # Deck count context
    if deckCount > 1:
      drawCenteredText($deckCount & " decks (" & $totalCards & " cards)",
        int32(ContentY + 16), FontTiny, PalCyan)

    let accPct = int(scoreAccuracy * 100)
    let accCol = if scoreAccuracy >= 0.8: ColCorrect
                 elif scoreAccuracy >= 0.5: PalGold
                 else: ColWrong
    let accY = if deckCount > 1: ContentY + 26 else: ContentY + 20
    drawCenteredText("Accuracy: " & $accPct & "%", int32(accY),
      FontSmall, accCol)

    drawCenteredText("Time: " & formatFloat(totalTime, ffDecimal, 1) & "s",
      int32(accY + 14), FontTiny, ColTextSecondary)

    # Performance tier
    if totalCards > 0:
      let secsPerCard = totalTime / float32(totalCards)
      let tier = tierForTime(secsPerCard)
      drawCenteredText(tierName(tier) & " (" &
        formatFloat(secsPerCard, ffDecimal, 1) & "s/card)",
        int32(ContentY + 46), FontTiny, PalGold)

    # Mistake breakdown
    if mistakes.len > 0:
      drawPixelText("Mistakes:", int32(ContentMargin), int32(ContentY + 60),
        FontTiny, ColWrong)
      let maxShow = min(mistakes.len - resultsScrollY, 3)
      for i in 0..<maxShow:
        let m = mistakes[resultsScrollY + i]
        let y = int32(ContentY + 72 + i * 22)
        let pickedCard = paoTable[m.pickedCardIdx].card
        let correctCard = paoTable[m.correctCardIdx].card
        let correctPao = paoTable[m.correctCardIdx]

        drawPixelText("Pos " & $(m.position + 1) & ": picked " &
          rankChar(pickedCard.rank) & suitChar(pickedCard.suit) &
          ", correct " & rankChar(correctCard.rank) & suitChar(correctCard.suit),
          int32(ContentMargin), y, FontTiny, PalLightGray)
        drawPixelText("  -> " & correctPao.person & " " & correctPao.action &
          " " & correctPao.obj,
          int32(ContentMargin), y + 10, FontTiny, PalGold)

      if mistakes.len > 3:
        drawPixelText("[Up/Down to scroll]",
          int32(ContentMargin), int32(ContentY + ContentH - 36), FontTiny, PalGray)
    else:
      drawCenteredText("Perfect run! No mistakes!", int32(ContentY + 64),
        FontTiny, ColCorrect)

    drawButton(resultsContinueBtn)

  # Hint bar
  drawHintBar()

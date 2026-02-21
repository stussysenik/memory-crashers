## Card Browser Scene: Grid, Suit, and Stage views with detail popup
## Browse all 52 cards, see mastery colors, view PAO associations

import raylib
import ../types, ../palette, ../design, ../ui, ../renderer, ../cards,
       ../input_manager, ../hints, ../learn_data

var
  browseView: BrowseView
  viewButtons: array[3, PixelButton]
  backButton: PixelButton

  # Suit view
  suitFilter: int  # 0-3 for Hearts/Diamonds/Clubs/Spades
  suitButtons: array[4, PixelButton]
  suitScrollOffset: int
  suitFilteredCards: seq[int]

  # Stage view
  stageFilter: int  # 0-6
  stageTabButtons: array[7, PixelButton]
  stageScrollOffset: int
  stageFilteredCards: seq[int]

  # Detail popup
  popupVisible: bool
  popupCardIdx: int

var changeSceneProc*: proc(s: Scene)
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

proc updateSuitFilter() =
  suitFilteredCards = @[]
  let startIdx = suitFilter * 13
  for i in startIdx..<startIdx + 13:
    suitFilteredCards.add(i)
  suitScrollOffset = 0

proc updateStageFilter() =
  stageFilteredCards = stageCards(stageFilter)
  stageScrollOffset = 0

proc initBrowseScene*() =
  browseView = BrowseGrid
  popupVisible = false
  popupCardIdx = 0
  suitFilter = 0
  stageFilter = 0
  suitScrollOffset = 0
  stageScrollOffset = 0
  setHintCategory(HintHome)

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)

  # View tab buttons at Y=26
  let tabW: float32 = 40
  let tabH: float32 = 12
  let tabGap: float32 = 4
  let totalTabW = tabW * 3 + tabGap * 2
  let tabStartX = (ScreenW.float32 - totalTabW) / 2
  let tabY: float32 = float32(HeaderY + HeaderH + 2)
  viewButtons[0] = newPixelButton(tabStartX, tabY, tabW, tabH,
    "All", PalBlue, PalSkyBlue, PalWhite)
  viewButtons[1] = newPixelButton(tabStartX + tabW + tabGap, tabY, tabW, tabH,
    "Suit", PalBlueDark, PalBlue, PalWhite)
  viewButtons[2] = newPixelButton(tabStartX + (tabW + tabGap) * 2, tabY, tabW, tabH,
    "Stage", PalBlueDark, PalBlue, PalWhite)

  # Suit filter buttons
  let suitBtnW: float32 = 36
  let suitGap: float32 = 4
  let suitTotalW = suitBtnW * 4 + suitGap * 3
  let suitStartX = (ScreenW.float32 - suitTotalW) / 2
  let suitY: float32 = 40
  let suitLabels = ["\xe2\x99\xa5", "\xe2\x99\xa6", "\xe2\x99\xa3", "\xe2\x99\xa0"]
  let suitColors = [PalRed, PalCoral, PalGreen, PalGrayDark]
  for i in 0..3:
    suitButtons[i] = newPixelButton(
      suitStartX + float32(i) * (suitBtnW + suitGap), suitY,
      suitBtnW, 12, suitLabels[i], suitColors[i], PalWhite, PalWhite)

  # Stage tab buttons
  let stgBtnW: float32 = 34
  let stgGap: float32 = 3
  let stgTotalW = stgBtnW * 7 + stgGap * 6
  let stgStartX = (ScreenW.float32 - stgTotalW) / 2
  let stgY: float32 = 40
  let stageAbbr = ["Face", "Hrt", "Dia", "Clb", "Spd", "Half", "Full"]
  for i in 0..6:
    stageTabButtons[i] = newPixelButton(
      stgStartX + float32(i) * (stgBtnW + stgGap), stgY,
      stgBtnW, 12, stageAbbr[i], StageColors[i], PalWhite, PalBlack)

  updateSuitFilter()
  updateStageFilter()

proc openPopup(cardIdx: int) =
  popupVisible = true
  popupCardIdx = cardIdx

proc closePopup() =
  popupVisible = false

proc updateBrowseScene*(dt: float32) =
  updateHints(dt)

  # Handle popup dismissal first
  if popupVisible:
    if isKeyPressed(Escape) or isKeyPressed(Enter) or isKeyPressed(Space):
      closePopup()
      return
    # Click outside popup to dismiss
    let mp = gameMousePos()
    if isMouseButtonPressed(Left):
      let popRect = Rectangle(x: 30, y: 24, width: 260, height: 136)
      if not checkCollisionPointRec(mp, popRect):
        closePopup()
        return
    return

  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneHome)
    return

  # View tabs
  for i in 0..2:
    if updateButton(viewButtons[i]):
      browseView = BrowseView(i)

  case browseView
  of BrowseGrid:
    # Click detection on grid cards
    let mp = gameMousePos()
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gapX: int32 = 2
    let gapY: int32 = 2
    let startX: int32 = 18
    let startY: int32 = 42

    if isMouseButtonPressed(Left):
      for i in 0..51:
        let col = i mod 13
        let row = i div 13
        let cx = startX + int32(col) * (cardW + gapX)
        let cy = startY + int32(row) * (cardH + gapY)
        let rect = Rectangle(x: cx.float32, y: cy.float32,
                              width: cardW.float32, height: cardH.float32)
        if checkCollisionPointRec(mp, rect):
          openPopup(i)
          break

  of BrowseSuit:
    for i in 0..3:
      if updateButton(suitButtons[i]):
        suitFilter = i
        updateSuitFilter()

    # Click cards in suit row
    let mp = gameMousePos()
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gap: int32 = 2
    let totalGridW = 13 * (cardW + gap)
    let startX = (ScreenW - totalGridW) div 2
    let startY: int32 = 54

    if isMouseButtonPressed(Left):
      for i in 0..<suitFilteredCards.len:
        let cx = startX + int32(i) * (cardW + gap)
        let cy = startY
        let rect = Rectangle(x: cx.float32, y: cy.float32,
                              width: cardW.float32, height: cardH.float32)
        if checkCollisionPointRec(mp, rect):
          openPopup(suitFilteredCards[i])
          break

    # Scroll PAO list
    let maxScroll = max(0, suitFilteredCards.len - 7)
    if isKeyPressed(Down) and suitScrollOffset < maxScroll:
      suitScrollOffset += 1
    if isKeyPressed(Up) and suitScrollOffset > 0:
      suitScrollOffset -= 1

  of BrowseStage:
    for i in 0..6:
      if updateButton(stageTabButtons[i]):
        stageFilter = i
        updateStageFilter()

    # Click cards in stage grid
    let mp = gameMousePos()
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gap: int32 = 2
    let cols = min(stageFilteredCards.len, 13)
    let totalGridW = cols * (cardW + gap)
    let startX = (ScreenW - int32(totalGridW)) div 2
    let startY: int32 = 54

    if isMouseButtonPressed(Left):
      for i in 0..<stageFilteredCards.len:
        let col = i mod 13
        let row = i div 13
        let cx = startX + int32(col) * (cardW + gap)
        let cy = startY + int32(row) * (cardH + gap)
        let rect = Rectangle(x: cx.float32, y: cy.float32,
                              width: cardW.float32, height: cardH.float32)
        if checkCollisionPointRec(mp, rect):
          openPopup(stageFilteredCards[i])
          break

    # Scroll PAO list
    let maxScroll = max(0, stageFilteredCards.len - 7)
    if isKeyPressed(Down) and stageScrollOffset < maxScroll:
      stageScrollOffset += 1
    if isKeyPressed(Up) and stageScrollOffset > 0:
      stageScrollOffset -= 1

proc drawMasteryBorder(x, y, w, h: int32; mastery: int) =
  let col = masteryColor(mastery)
  drawRectangle(x - 1, y - 1, w + 2, h + 2, col)

proc drawPaoLine(cardIdx: int; x, y: int32) =
  let card = paoTable[cardIdx].card
  let pao = paoTable[cardIdx]
  let label = rankChar(card.rank) & suitChar(card.suit) & " = " &
    pao.person & "  " & pao.action & " " & pao.obj
  drawPixelText(label, x, y, FontTiny, PalLightGray)

proc drawBrowseScene*() =
  drawHeader("BROWSE")
  drawButton(backButton)

  # View tab buttons with highlight
  for i in 0..2:
    var btn = viewButtons[i]
    if BrowseView(i) == browseView:
      btn.color = PalBlue
      btn.hoverColor = PalSkyBlue
    else:
      btn.color = PalBlueDark
      btn.hoverColor = PalBlue
    drawButton(btn)

  case browseView
  of BrowseGrid:
    # All 52 cards in 13x4 grid
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gapX: int32 = 2
    let gapY: int32 = 2
    let startX: int32 = 18
    let startY: int32 = 42

    for i in 0..51:
      let col = i mod 13
      let row = i div 13
      let cx = startX + int32(col) * (cardW + gapX)
      let cy = startY + int32(row) * (cardH + gapY)

      # Mastery border
      let mastery = if playerDataPtr != nil: playerDataPtr[].cardMastery[i] else: 0
      drawMasteryBorder(cx, cy, cardW, cardH, mastery)

      # Card face
      let card = paoTable[i].card
      drawCardFace(card, cx, cy, cardW, cardH)

  of BrowseSuit:
    # Suit filter buttons with highlight
    for i in 0..3:
      var btn = suitButtons[i]
      if i == suitFilter:
        btn.color = PalGold
        btn.textColor = PalBlack
      drawButton(btn)

    # 13 cards in a row
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gap: int32 = 2
    let totalGridW = 13 * (cardW + gap)
    let startX = (ScreenW - totalGridW) div 2
    let startY: int32 = 54

    for i in 0..<suitFilteredCards.len:
      let ci = suitFilteredCards[i]
      let cx = startX + int32(i) * (cardW + gap)
      let mastery = if playerDataPtr != nil: playerDataPtr[].cardMastery[ci] else: 0
      drawMasteryBorder(cx, startY, cardW, cardH, mastery)
      drawCardFace(paoTable[ci].card, cx, startY, cardW, cardH)

    # PAO list below
    let listY: int32 = 86
    let maxVisible = 7
    let listX: int32 = 16
    for i in 0..<min(maxVisible, suitFilteredCards.len - suitScrollOffset):
      let ci = suitFilteredCards[suitScrollOffset + i]
      drawPaoLine(ci, listX, listY + int32(i) * 10)

    # Scroll indicators
    if suitScrollOffset > 0:
      drawPixelText("^", int32(ScreenW - 16), listY, FontTiny, PalGold)
    if suitScrollOffset < suitFilteredCards.len - maxVisible:
      drawPixelText("v", int32(ScreenW - 16), listY + int32((maxVisible - 1) * 10), FontTiny, PalGold)

  of BrowseStage:
    # Stage tab buttons with highlight
    for i in 0..6:
      var btn = stageTabButtons[i]
      if i == stageFilter:
        btn.color = PalGold
        btn.textColor = PalBlack
      drawButton(btn)

    # Cards grid
    let cardW: int32 = 20
    let cardH: int32 = 28
    let gap: int32 = 2
    let cols = min(stageFilteredCards.len, 13)
    let totalGridW = cols * (cardW + gap)
    let startX = (ScreenW - int32(totalGridW)) div 2
    let startY: int32 = 54

    for i in 0..<stageFilteredCards.len:
      let ci = stageFilteredCards[i]
      let col = i mod 13
      let row = i div 13
      let cx = startX + int32(col) * (cardW + gap)
      let cy = startY + int32(row) * (cardH + gap)
      let mastery = if playerDataPtr != nil: playerDataPtr[].cardMastery[ci] else: 0
      drawMasteryBorder(cx, cy, cardW, cardH, mastery)
      drawCardFace(paoTable[ci].card, cx, cy, cardW, cardH)

    # PAO list below grid
    let rows = (stageFilteredCards.len + 12) div 13
    let listY = int32(startY) + int32(rows) * (cardH + gap) + 4
    let maxVisible = min(7, (int32(HintBarY) - listY) div 10)
    let listX: int32 = 16

    if maxVisible > 0:
      for i in 0..<min(int(maxVisible), stageFilteredCards.len - stageScrollOffset):
        let ci = stageFilteredCards[stageScrollOffset + i]
        drawPaoLine(ci, listX, listY + int32(i) * 10)

      if stageScrollOffset > 0:
        drawPixelText("^", int32(ScreenW - 16), listY, FontTiny, PalGold)
      if stageScrollOffset < stageFilteredCards.len - int(maxVisible):
        drawPixelText("v", int32(ScreenW - 16), listY + int32((int(maxVisible) - 1) * 10), FontTiny, PalGold)

  # Detail popup overlay
  if popupVisible:
    # Semi-transparent overlay
    drawRectangle(0, 0, GameWidth, GameHeight,
      Color(r: 0, g: 0, b: 0, a: 160))

    # Panel
    let px: int32 = 30
    let py: int32 = 24
    let pw: int32 = 260
    let ph: int32 = 136
    drawRectangle(px, py, pw, ph, PalNavy)
    drawRectangleLines(Rectangle(x: px.float32, y: py.float32,
      width: pw.float32, height: ph.float32), 1.0, PalGold)

    let ci = popupCardIdx
    let card = paoTable[ci].card
    let pao = paoTable[ci]

    # Large card on left
    let cardX: int32 = px + 8
    let cardY: int32 = py + 10
    drawCardFace(card, cardX, cardY, CardLGW, CardLGH)

    # PAO info on right
    let infoX: int32 = cardX + CardLGW + 12
    let infoY: int32 = py + 12
    drawPixelText("Person:", infoX, infoY, FontTiny, PalGray)
    drawPixelText(pao.person, infoX, infoY + 10, FontSmall, PalGold)
    drawPixelText("Action:", infoX, infoY + 24, FontTiny, PalGray)
    drawPixelText(pao.action, infoX, infoY + 34, FontSmall, PalCyan)
    drawPixelText("Object:", infoX, infoY + 48, FontTiny, PalGray)
    drawPixelText(pao.obj, infoX, infoY + 58, FontSmall, PalPink)

    # Suit theme hint
    drawPixelText(suitThemeHint(card.suit), px + 8, py + 80, FontTiny, PalGray)

    # Mastery dots
    if playerDataPtr != nil:
      let mastery = playerDataPtr[].cardMastery[ci]
      drawPixelText("Mastery:", px + 8, py + 94, FontTiny, PalGray)
      drawMasteryDots(px + 60, py + 94, mastery)

    # Related cards (same suit)
    let suitStart = card.suit.ord * 13
    drawPixelText("Same suit:", px + 8, py + 108, FontTiny, PalGray)
    var relX: int32 = px + 68
    for i in 0..12:
      let relIdx = suitStart + i
      if relIdx != ci:
        let relCard = paoTable[relIdx].card
        let rk = rankChar(relCard.rank)
        let col = if playerDataPtr != nil and playerDataPtr[].cardMastery[relIdx] >= 3:
          PalGreen else: PalLightGray
        drawPixelText(rk, relX, py + 108, FontTiny, col)
        relX += int32(measureText(rk, FontTiny)) + 3

    # Dismiss hint
    drawPixelText("ESC / click outside to close", px + 8, py + ph - 14, FontTiny, PalGray)

  # Hint bar
  drawHintBar()

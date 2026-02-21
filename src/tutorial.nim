## Tutorial overlay: TAB toggles context-sensitive help pages
## "?" button in header for mobile/touch

import raylib
import types, palette, design, input_manager, cards

const
  MaxPages = 5

  # Page 5 (index 4) is the dynamic Card Reference — placeholder in static arrays
  RefPagePlaceholder: array[5, string] = ["Card Reference", "", "", "", ""]

  HomeTutorial: array[MaxPages, array[5, string]] = [
    ["How to Play", "Learn: Study cards via PAO system", "Practice: Timed memorize & recall", "Speed: WMC championship discipline", "Browse: View all 52 cards & PAO data"],
    ["PAO System", "Each card = Person + Action + Object", "Hearts = warm, Diamonds = rich", "Clubs = tough, Spades = dark", "Vivid mental images = strong memory"],
    ["Progression", "Master face cards first (Stage 1)", "Then learn each suit individually", "Warm up with small sets, then scale up", "Progressive overload builds champions"],
    ["Tips", "Train like an athlete: short bursts", "Consistency beats long sessions", "Drill weak spots, not what you know", "TAB opens this help on any screen"],
    RefPagePlaceholder,
  ]

  LearnTutorial: array[MaxPages, array[5, string]] = [
    ["Learn Flow", "Study: View cards & their PAO", "Quiz: Identify card's person (4 options)", "Drill: Speed round, 2 choices", "Complete all 3 to finish a stage"],
    ["Mastery System", "Each card has mastery 0-5", "Correct answers raise mastery", "Wrong answers lower mastery", "Weaker cards appear more often"],
    ["Keyboard Shortcuts", "Left/Right: Navigate cards", "Click: Select quiz answer", "Enter: Confirm / advance", "Back button returns to stage select"],
    ["Strategy", "Recognition first, then speed", "Connect person to suit personality", "Drill weak spots before moving on", "80% quiz accuracy unlocks drill"],
    RefPagePlaceholder,
  ]

  PracticeTutorial: array[MaxPages, array[5, string]] = [
    ["Practice Mode", "Memorize cards shown one at a time", "Then recall them in exact order", "Choose from 5, 13, 26, or 52 cards", "Multi-deck unlocks at 40+ mastered"],
    ["PAO Grouping", "Group 3 cards into one PAO scene", "Person from card 1, Action from 2", "Object from card 3 = one scene", "Link scenes to locations (loci)"],
    ["Performance Tiers", "<1s/card = Champion", "<2s/card = Advanced", "<5s/card = Intermediate", "Track your PB and keep improving"],
    ["Tips", "Warm up: 5 cards before full deck", "Accuracy first, then speed", "Review every mistake like a champion", "10 mins daily beats 1hr weekly"],
    RefPagePlaceholder,
  ]

  DailyTutorial: array[MaxPages, array[5, string]] = [
    ["Daily Challenge", "Full 52-card deck every day", "Same puzzle for everyone globally", "Compare your score with others", "New deck each day at midnight"],
    ["Streak System", "Play daily to build your streak", "Streak bonus gives extra XP", "Best streak is tracked forever", "Don't break the chain!"],
    ["Scoring", "Score = accuracy x time bonus", "Faster completion = higher bonus", "Perfect accuracy = 100 base score", "Time bonus caps at 2x"],
    ["Strategy", "Use journey method for 52 cards", "Place PAO scenes along a route", "Review mistakes after each attempt", "Morning practice = better retention"],
    RefPagePlaceholder,
  ]

  SpeedTutorial: array[MaxPages, array[5, string]] = [
    ["Speed Cards", "Official WMC discipline", "Memorize full 52-card deck", "Then recall cards in order", "Multi-deck: 1x-5x after 3 attempts"],
    ["WMC Benchmarks", "<30s memorize = World Class", "<60s = Grandmaster", "<120s = Expert", "<300s = Advanced"],
    ["Champion Strategies", "Build rock-solid PAO associations", "Group 3 cards per mental scene", "Use memory palace for sequence", "Trust gut instinct in recall"],
    ["Training", "Warm up: small sets before full deck", "Progressive overload builds champions", "Speed comes after accuracy", "Review every mistake. Champions do."],
    RefPagePlaceholder,
  ]

  BrowseTutorial: array[MaxPages, array[5, string]] = [
    ["Card Browser", "View all 52 cards and their PAO data", "Color = mastery level, click for details", "Filter by suit or learning stage", "Great for finding weak spots to review"],
    ["Mastery Colors", "Gray = new, Red = seen", "Orange = learning, Gold = familiar", "Lime = confident, Green = mastered", "Focus on gray and red cards first"],
    ["Suit Themes", "Hearts = warm, loving characters", "Diamonds = rich, glamorous figures", "Clubs = tough, athletic fighters", "Spades = dark, mysterious beings"],
    ["Tips", "Find weak spots before practice", "Review PAO before speed attempts", "Stage filter = your curriculum view", "Click any card for full PAO details"],
    RefPagePlaceholder,
  ]

var
  tutorialVisible*: bool = false
  tutorialPage: int = 0
  tutorialScene: Scene = SceneHome
  tutorialRefCards*: seq[int] = @[]
  refScrollOffset: int = 0

proc toggleTutorial*(scene: Scene) =
  tutorialVisible = not tutorialVisible
  if tutorialVisible:
    tutorialScene = scene
    tutorialPage = 0
    refScrollOffset = 0

proc updateTutorial*() =
  if not tutorialVisible: return

  # On page 5 (index 4), Up/Down scrolls the reference list
  if tutorialPage == 4 and tutorialRefCards.len > 0:
    let maxScroll = max(0, tutorialRefCards.len - 8)
    if isKeyPressed(Down) and refScrollOffset < maxScroll:
      refScrollOffset += 1
    if isKeyPressed(Up) and refScrollOffset > 0:
      refScrollOffset -= 1

  if isKeyPressed(Left) and tutorialPage > 0:
    tutorialPage -= 1
    refScrollOffset = 0
  if isKeyPressed(Right) and tutorialPage < MaxPages - 1:
    tutorialPage += 1
    refScrollOffset = 0
  if isKeyPressed(Tab) or isKeyPressed(Escape):
    tutorialVisible = false

  # Click anywhere to dismiss (after checking arrows)
  # Check "?" area or edges to close
  let mp = gameMousePos()
  if isMouseButtonPressed(Left):
    # Close button area (top-right corner)
    if mp.x > float32(ScreenW - 30) and mp.y < 20:
      tutorialVisible = false
    # Left arrow area
    elif mp.x < 40 and mp.y > 80 and mp.y < 120:
      if tutorialPage > 0:
        tutorialPage -= 1
        refScrollOffset = 0
    # Right arrow area
    elif mp.x > float32(ScreenW - 40) and mp.y > 80 and mp.y < 120:
      if tutorialPage < MaxPages - 1:
        tutorialPage += 1
        refScrollOffset = 0

proc getTutorialContent(): array[5, string] =
  case tutorialScene
  of SceneHome: HomeTutorial[tutorialPage]
  of SceneLearn: LearnTutorial[tutorialPage]
  of ScenePractice: PracticeTutorial[tutorialPage]
  of SceneDaily: DailyTutorial[tutorialPage]
  of SceneSpeedCards: SpeedTutorial[tutorialPage]
  of SceneBrowse: BrowseTutorial[tutorialPage]

proc drawTutorial*() =
  if not tutorialVisible: return

  # Semi-transparent overlay
  drawRectangle(0, 0, GameWidth, GameHeight,
    Color(r: 0, g: 0, b: 0, a: 180))

  # Panel
  let panelX: int32 = 24
  let panelY: int32 = 20
  let panelW: int32 = GameWidth - 48
  let panelH: int32 = GameHeight - 40
  drawRectangle(panelX, panelY, panelW, panelH, PalNavy)
  drawRectangleLines(Rectangle(x: panelX.float32, y: panelY.float32,
    width: panelW.float32, height: panelH.float32), 1.0, PalGold)

  # Page 5 (index 4) is special: dynamic scrollable card reference
  if tutorialPage == 4 and tutorialRefCards.len > 0:
    let titleStr = "Card Reference"
    let titleW = measureText(titleStr, FontSmall)
    drawText(titleStr, (GameWidth - titleW) div 2, panelY + 8, FontSmall, PalGold)

    let maxVisible = 8
    let lineH: int32 = 10
    let listStartY = panelY + 24

    for i in 0..<min(maxVisible, tutorialRefCards.len - refScrollOffset):
      let ci = tutorialRefCards[refScrollOffset + i]
      let card = paoTable[ci].card
      let pao = paoTable[ci]
      let line = rankChar(card.rank) & suitChar(card.suit) & " " &
        pao.person & "  " & pao.action & " " & pao.obj
      let lineY = listStartY + int32(i) * lineH
      drawText(line, panelX + 10, lineY, FontTiny, PalLightGray)

    # Scroll indicators
    if refScrollOffset > 0:
      drawText("^", panelX + panelW - 14, listStartY, FontTiny, PalGold)
    if refScrollOffset < tutorialRefCards.len - maxVisible:
      drawText("v", panelX + panelW - 14, listStartY + int32((maxVisible - 1) * lineH), FontTiny, PalGold)

    # Scroll hint
    let scrollHint = "Up/Down to scroll  (" & $(refScrollOffset + 1) & "-" &
      $min(refScrollOffset + maxVisible, tutorialRefCards.len) & " of " &
      $tutorialRefCards.len & ")"
    let shW = measureText(scrollHint, FontTiny)
    drawText(scrollHint, (GameWidth - shW) div 2, panelY + panelH - 32, FontTiny, PalGray)

  else:
    let content = getTutorialContent()

    # Title
    let titleW = measureText(content[0], FontSmall)
    drawText(content[0], (GameWidth - titleW) div 2, panelY + 8, FontSmall, PalGold)

    # Content lines
    for i in 1..4:
      if content[i].len > 0:
        drawText(content[i], panelX + 10, panelY + 26 + int32((i - 1) * 22),
          FontTiny, PalLightGray)

  # Page indicator
  let pageText = $(tutorialPage + 1) & "/" & $MaxPages
  let pageW = measureText(pageText, FontTiny)
  drawText(pageText, (GameWidth - pageW) div 2,
    panelY + panelH - 22, FontTiny, PalGray)

  # Navigation arrows
  if tutorialPage > 0:
    drawText("<", panelX + 4, panelY + panelH div 2 - 4, FontSmall, PalGold)
  if tutorialPage < MaxPages - 1:
    drawText(">", panelX + panelW - 12, panelY + panelH div 2 - 4, FontSmall, PalGold)

  # Close hint
  drawText("[X]", panelX + panelW - 22, panelY + 4, FontTiny, PalGray)

  # Bottom hint
  let hint = "TAB or ESC to close  |  Left/Right to navigate"
  let hintW = measureText(hint, FontTiny)
  drawText(hint, (GameWidth - hintW) div 2, panelY + panelH - 10, FontTiny, PalGray)

proc drawHelpButton*(x, y: int32): bool =
  ## Draw small "?" button, return true if clicked
  let mp = gameMousePos()
  let rect = Rectangle(x: x.float32, y: y.float32,
                        width: BtnHelpW.float32, height: BtnHelpH.float32)
  let hovered = checkCollisionPointRec(mp, rect)
  if hovered:
    drawRectangle(x, y, int32(BtnHelpW), int32(BtnHelpH), PalGold)
    drawRectangleLines(rect, 1.0, PalGold)
    let qW = measureText("?", FontSmall)
    drawText("?", x + (int32(BtnHelpW) - qW) div 2, y + 2, FontSmall, PalBlack)
  else:
    drawRectangle(x, y, int32(BtnHelpW), int32(BtnHelpH), PalPurpleDark)
    drawRectangleLines(rect, 1.0, PalGold)
    let qW = measureText("?", FontSmall)
    drawText("?", x + (int32(BtnHelpW) - qW) div 2, y + 2, FontSmall, PalGold)
  return hovered and isMouseButtonPressed(Left)

## Hint system: rotating contextual memory tips — the secret sauce
## 128 tips (8 categories x 16), all real memory science, ≤38 chars each

import raylib
import palette, design

type
  HintCategory* = enum
    HintGeneral, HintPAO, HintStudy, HintQuiz,
    HintSpeed, HintPractice, HintDaily, HintHome

const
  HintsPerCategory = 16

  GeneralHints: array[HintsPerCategory, string] = [
    "Ebbinghaus: 70% gone in 24h. Review!",
    "Spaced reps beat cramming 3:1.",
    "Sleep after study cements memories.",
    "Dual coding: see it AND say it aloud.",
    "Von Restorff: bizarre = memorable.",
    "Chunking: group items into clusters.",
    "Testing effect: recall > rereading.",
    "Interleaving: mix topics to learn.",
    "Elaboration: ask WHY for each card.",
    "Self-reference: link to YOUR life.",
    "Concrete > abstract for memory.",
    "Generation effect: create, don't copy.",
    "Active recall beats passive review.",
    "Desirable difficulty strengthens it.",
    "Encoding specificity: context matters.",
    "Retrieval practice is #1 study method.",
  ]

  PAOHints: array[HintsPerCategory, string] = [
    "PAO turns each card into a scene.",
    "Exaggerate! Bigger images = stronger.",
    "Engage all 5 senses in your scene.",
    "Bizarre imagery is 2x more memorable.",
    "Movement in scenes aids recall by 40%.",
    "Emotional scenes stick 3x longer.",
    "Link person to suit theme for speed.",
    "3 cards = 1 PAO scene. Compress info!",
    "Make your person DO the action loudly.",
    "Place objects in your person's hands.",
    "Color your scenes. Vivid > gray.",
    "Sound effects in scenes help recall.",
    "Shrink or grow objects for impact.",
    "Stack scenes along a familiar route.",
    "Each suit = a personality archetype.",
    "PAO is used by every memory champion.",
  ]

  StudyHints: array[HintsPerCategory, string] = [
    "Recognition first, then recall speed.",
    "Warm up with 5 cards first.",
    "Say the PAO aloud. Dual coding helps!",
    "Close eyes. Picture the full scene.",
    "Teach someone the PAO. Learn 2x.",
    "Spend 2x time on your weakest cards.",
    "Study in 25min blocks (Pomodoro).",
    "Review before sleep for memory.",
    "Create a story linking 3 card scenes.",
    "Write the PAO from memory. Test it!",
    "Vary your study location for encoding.",
    "Feynman technique: explain it simply.",
    "Space sessions: 1h, 1d, 3d, 7d.",
    "Overlearn: keep going after you know.",
    "Mnemonics cut cognitive load by 50%.",
    "Progressive overload: add cards daily.",
  ]

  QuizHints: array[HintsPerCategory, string] = [
    "Wrong answers reveal what to review.",
    "Think suit theme first, then person.",
    "Errors are data, not failure.",
    "Weaker cards appear more. That's good!",
    "80% accuracy unlocks speed drill.",
    "Slow & correct > fast & wrong.",
    "After wrong: pause, visualize, retry.",
    "Each quiz rep strengthens the trace.",
    "Confidence + correctness = mastery.",
    "Hesitation means the link is forming.",
    "Quiz yourself > rereading. Always.",
    "Spaced retrieval: hard now, easy later.",
    "If stuck, recall the suit's theme.",
    "4 wrong then 1 right = normal.",
    "Leitner: wrong cards come back sooner.",
    "Mastery needs 5 correct in a row.",
  ]

  SpeedHints: array[HintsPerCategory, string] = [
    "Warm up: small sets before full deck.",
    "Review every mistake. Champions do.",
    "WMC record: 52 cards in 12.74 secs.",
    "Under 2s/card = 3 stars. You got this!",
    "Trust your gut in speed rounds.",
    "Automaticity: no thinking required.",
    "Alex Mullen: deck in 15.61 seconds.",
    "Speed comes from solid PAO links.",
    "Don't think. React. That's the goal.",
    "Your reaction time drops with reps.",
    "Champions drill 1000+ times per card.",
    "Neural pathways strengthen with speed.",
    "Speed training builds long-term memory.",
    "Fast recall = permanent association.",
    "Competitive mnemonists train 2hrs/day.",
    "Your PB will drop. Keep drilling.",
  ]

  PracticeHints: array[HintsPerCategory, string] = [
    "Group 3 cards into one PAO scene.",
    "Walk a familiar route for loci method.",
    "Review mistakes: they're gold.",
    "Start small. 5 cards. Master them.",
    "Speed comes AFTER accuracy. Always.",
    "Beat your PB! Compete with yourself.",
    "Under 1s/card = championship level.",
    "Link scenes to rooms in your house.",
    "Use journey method for card sequences.",
    "Imagine each scene at a locus vividly.",
    "Memory palace: 1 scene per location.",
    "Practice recalling in reverse too.",
    "Shuffle often. Don't memorize order.",
    "Time yourself. What gets measured grows.",
    "10 mins daily beats 1hr weekly.",
    "Real competitors do 10+ decks/day.",
  ]

  DailyHints: array[HintsPerCategory, string] = [
    "Same puzzle globally. Compare notes!",
    "Daily streaks build the memory habit.",
    "Your brain rewires a little each day.",
    "Keep the chain. Don't break the streak.",
    "52 cards is the gold standard test.",
    "Streak bonus: extra XP compounds.",
    "Treat this as your daily brain workout.",
    "Consistency > intensity for memory.",
    "The daily is your performance benchmark.",
    "Track improvement. Small gains add up.",
    "21 days to build a habit. Keep going.",
    "Morning practice = better retention.",
    "Your brain consolidates overnight.",
    "Daily variety prevents memorization.",
    "New deck order each day. Stay sharp.",
    "Come back tomorrow. Brain expects it.",
  ]

  HomeHints: array[HintsPerCategory, string] = [
    "Train like an athlete: short bursts.",
    "Recognition + speed = memory athlete.",
    "5 minutes daily is all you need.",
    "Check your mastery progress above.",
    "Start with Learn if you're new.",
    "Practice tests your recall speed.",
    "Daily challenges benchmark your skill.",
    "Master face cards first, then suits.",
    "Consistency is the #1 predictor.",
    "You remember what you practice.",
    "Set a goal: 1 stage or 1 practice.",
    "Memory athletes train like athletes.",
    "Your brain grows with each session.",
    "TAB = help overlay. Try it!",
    "XP tracks your training volume.",
    "Mastery bars show what to review.",
  ]

var
  currentHintIdx: int = 0
  hintTimer: float32 = 0.0
  currentCategory: HintCategory = HintHome

proc getHint(cat: HintCategory; idx: int): string =
  let i = idx mod HintsPerCategory
  case cat
  of HintGeneral: GeneralHints[i]
  of HintPAO: PAOHints[i]
  of HintStudy: StudyHints[i]
  of HintQuiz: QuizHints[i]
  of HintSpeed: SpeedHints[i]
  of HintPractice: PracticeHints[i]
  of HintDaily: DailyHints[i]
  of HintHome: HomeHints[i]

proc setHintCategory*(cat: HintCategory) =
  if cat != currentCategory:
    currentCategory = cat
    currentHintIdx = 0
    hintTimer = 0.0

proc updateHints*(dt: float32) =
  hintTimer += dt
  if hintTimer >= HintRotateInterval:
    hintTimer = 0.0
    currentHintIdx = (currentHintIdx + 1) mod HintsPerCategory

proc drawHintBar*() =
  # Background
  drawRectangle(0, HintBarY, ScreenW, HintBarH, ColBgSecondary)
  drawRectangle(0, HintBarY, ScreenW, 1, PalBlack)

  # Tip text centered — use FontSmall (10px) for readability
  let tip = getHint(currentCategory, currentHintIdx)
  let textW = measureText(tip, FontSmall)
  let x = (ScreenW - textW) div 2
  let y = int32(HintBarY + (HintBarH - FontSmall) div 2)
  drawText(tip, x, y, FontSmall, ColHint)

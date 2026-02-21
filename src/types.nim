## All shared types for Memory Crashers

import raylib
import std/random

var rng* = initRand(42)

proc getRandomValue*(minVal, maxVal: int32): int32 =
  int32(rng.rand(int(minVal)..int(maxVal)))

proc setRandomSeed*(seed: uint32) =
  rng = initRand(int64(seed))

type
  Suit* = enum
    Hearts, Diamonds, Clubs, Spades

  Rank* = enum
    Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten,
    Jack, Queen, King

  Card* = object
    suit*: Suit
    rank*: Rank

  PaoEntry* = object
    card*: Card
    person*: string
    action*: string
    obj*: string

  Scene* = enum
    SceneHome, SceneLearn, ScenePractice, SceneDaily, SceneSpeedCards, SceneBrowse

  BrowseView* = enum
    BrowseGrid, BrowseSuit, BrowseStage

  SpeedPhase* = enum
    SpeedReady, SpeedCountdown, SpeedMemorize, SpeedRecall, SpeedResults

  LearnPhase* = enum
    LearnStageSelect, LearnStudy, LearnQuiz, LearnDrill, LearnStageComplete

  PracticePhase* = enum
    PracticeSetup, PracticeMemorize, PracticeRecall, PracticeResults

  PerformanceTier* = enum
    TierBeginner, TierIntermediate, TierAdvanced, TierChampion

  EaseKind* = enum
    EaseLinear, EaseInQuad, EaseOutQuad, EaseInOutQuad,
    EaseOutBack, EaseOutBounce, EaseOutElastic

  Tween* = object
    active*: bool
    elapsed*: float32
    duration*: float32
    startVal*: float32
    endVal*: float32
    ease*: EaseKind
    current*: float32

  FloatingText* = object
    active*: bool
    text*: string
    pos*: Vector2
    life*: float32
    maxLife*: float32
    color*: Color

  Particle* = object
    active*: bool
    pos*: Vector2
    vel*: Vector2
    life*: float32
    maxLife*: float32
    color*: Color
    size*: float32

  ParticleSystem* = object
    particles*: seq[Particle]

  PixelButton* = object
    rect*: Rectangle
    label*: string
    color*: Color
    hoverColor*: Color
    textColor*: Color
    hovered*: bool
    pressed*: bool

  TransitionState* = enum
    TransNone, TransFadeOut, TransFadeIn

  GameState* = object
    scene*: Scene
    nextScene*: Scene
    transition*: TransitionState
    transitionTimer*: float32
    transitionDuration*: float32
    screenShake*: float32
    screenShakeIntensity*: float32
    particles*: ParticleSystem
    floatingTexts*: seq[FloatingText]
    levelUpTimer*: float32

  StageProgress* = object
    unlocked*: bool
    completed*: bool
    cardsStudied*: int
    quizScore*: int
    quizTotal*: int
    drillBestTime*: float32

  PlayerData* = object
    xp*: int
    level*: int
    streak*: int
    bestStreak*: int
    lastPlayDate*: int  # day number
    cardMastery*: array[52, int]  # 0-5 mastery per card
    arenaHighScores*: array[4, int]  # legacy, kept for compat
    dailyCompleted*: bool
    totalCardsStudied*: int
    totalQuizCorrect*: int
    totalQuizAttempts*: int
    # New fields for learning-first redesign
    stageProgress*: array[7, StageProgress]
    currentStage*: int
    practiceBestTimes*: array[4, float32]    # best time per card count (5,13,26,52)
    practiceBestAccuracy*: array[4, float32] # best accuracy per card count
    totalDrillsCompleted*: int
    # Speed Cards fields
    speedBestTime*: float32
    speedBestMemorizeTime*: float32
    speedBestAccuracy*: float32
    speedAttempts*: int
    # Multi-deck fields
    multiDeckBestTimes*: array[5, float32]     # 1-5 decks
    multiDeckBestAccuracy*: array[5, float32]

  MistakeRecord* = object
    position*: int
    pickedCardIdx*: int
    correctCardIdx*: int

const
  GameWidth* = 320
  GameHeight* = 180
  TransitionTime* = 0.3'f32
  CardWidth* = 28
  CardHeight* = 40
  MaxParticles* = 200

  PracticeCardCounts*: array[4, int] = [5, 13, 26, 52]

proc cardIndex*(suit: Suit; rank: Rank): int =
  suit.ord * 13 + rank.ord

proc cardIndex*(c: Card): int =
  cardIndex(c.suit, c.rank)

proc cardFromIndex*(idx: int): Card =
  Card(suit: Suit(idx div 13), rank: Rank(idx mod 13))

proc rankChar*(r: Rank): string =
  case r
  of Ace: "A"
  of Two: "2"
  of Three: "3"
  of Four: "4"
  of Five: "5"
  of Six: "6"
  of Seven: "7"
  of Eight: "8"
  of Nine: "9"
  of Ten: "10"
  of Jack: "J"
  of Queen: "Q"
  of King: "K"

proc suitChar*(s: Suit): string =
  case s
  of Hearts: "\xe2\x99\xa5"
  of Diamonds: "\xe2\x99\xa6"
  of Clubs: "\xe2\x99\xa3"
  of Spades: "\xe2\x99\xa0"

proc suitColor*(s: Suit): bool =
  ## Returns true if red suit
  s == Hearts or s == Diamonds

proc tierForTime*(secsPerCard: float32): PerformanceTier =
  if secsPerCard < 1.0: TierChampion
  elif secsPerCard < 2.0: TierAdvanced
  elif secsPerCard < 5.0: TierIntermediate
  else: TierBeginner

proc tierName*(tier: PerformanceTier): string =
  case tier
  of TierBeginner: "BEGINNER"
  of TierIntermediate: "INTERMEDIATE"
  of TierAdvanced: "ADVANCED"
  of TierChampion: "CHAMPION"

proc practiceCountIndex*(count: int): int =
  ## Maps card count to index in practiceBest arrays
  case count
  of 5: 0
  of 13: 1
  of 26: 2
  of 52: 3
  else: 0

proc suggestedCardCount*(pd: PlayerData): int =
  ## Suggest practice card count based on mastery
  var mastered = 0
  for m in pd.cardMastery:
    if m >= 3: mastered += 1
  if mastered < 12: 5
  elif mastered < 26: 13
  elif mastered < 40: 26
  else: 52

proc masteredCardCount*(pd: PlayerData): int =
  var count = 0
  for m in pd.cardMastery:
    if m >= 3: count += 1
  count

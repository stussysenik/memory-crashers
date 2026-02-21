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
    SceneTitle, SceneAcademy, SceneArena, ScenePalace, SceneDaily

  ArenaPhase* = enum
    ArenaSetup, ArenaMemorize, ArenaRecall, ArenaResults

  AcademyMode* = enum
    AcademyFlashcard, AcademyQuiz

  Difficulty* = enum
    Easy, Medium, Hard, Insane

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

  PlayerData* = object
    xp*: int
    level*: int
    streak*: int
    bestStreak*: int
    lastPlayDate*: int  # day number
    cardMastery*: array[52, int]  # 0-5 mastery per card
    arenaHighScores*: array[4, int]  # per difficulty
    dailyCompleted*: bool
    totalCardsStudied*: int
    totalQuizCorrect*: int
    totalQuizAttempts*: int

  # Palace types
  RoomKind* = enum
    RoomKitchen, RoomBedroom, RoomGarden, RoomLibrary

  Station* = object
    pos*: Vector2
    cards*: array[3, int]  # card indices, -1 = empty
    filled*: bool

  Room* = object
    kind*: RoomKind
    stations*: array[3, Station]
    exits*: array[4, int]  # N,E,S,W -> room index, -1 = wall

  PalaceKnight* = object
    pos*: Vector2
    targetPos*: Vector2
    moving*: bool
    frame*: int
    frameTimer*: float32
    direction*: int  # 0=down, 1=up, 2=left, 3=right

const
  GameWidth* = 320
  GameHeight* = 180
  TransitionTime* = 0.3'f32
  CardWidth* = 28
  CardHeight* = 40
  MaxParticles* = 200

proc difficultyCardCount*(d: Difficulty): int =
  case d
  of Easy: 5
  of Medium: 13
  of Hard: 26
  of Insane: 52

proc difficultyName*(d: Difficulty): string =
  case d
  of Easy: "Easy (5)"
  of Medium: "Medium (13)"
  of Hard: "Hard (26)"
  of Insane: "Insane (52)"

proc cardIndex*(suit: Suit, rank: Rank): int =
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

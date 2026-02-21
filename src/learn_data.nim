## Learning stage definitions, card sets, unlock logic, Leitner weights

import types

const
  StageCount* = 7

  StageNames*: array[StageCount, string] = [
    "Face Cards",
    "Hearts",
    "Diamonds",
    "Clubs",
    "Spades",
    "Half Deck",
    "Full Deck",
  ]

  StageDescriptions*: array[StageCount, string] = [
    "J, Q, K of all suits",
    "All 13 Hearts",
    "All 13 Diamonds",
    "All 13 Clubs",
    "All 13 Spades",
    "Hearts + Diamonds (26)",
    "The entire deck (52)",
  ]

  # Leitner weights: higher = appears more often in quiz
  LeitnerWeights*: array[6, int] = [8, 6, 4, 2, 1, 0]

proc stageCards*(stage: int): seq[int] =
  ## Returns card indices for a given stage
  case stage
  of 0:  # Face Cards: J, Q, K of all suits
    result = @[]
    for suit in 0..3:
      for rank in [10, 11, 12]:  # Jack=10, Queen=11, King=12
        result.add(suit * 13 + rank)
  of 1:  # Hearts (0-12)
    result = @[]
    for i in 0..12: result.add(i)
  of 2:  # Diamonds (13-25)
    result = @[]
    for i in 13..25: result.add(i)
  of 3:  # Clubs (26-38)
    result = @[]
    for i in 26..38: result.add(i)
  of 4:  # Spades (39-51)
    result = @[]
    for i in 39..51: result.add(i)
  of 5:  # Half Deck: Hearts + Diamonds
    result = @[]
    for i in 0..25: result.add(i)
  of 6:  # Full Deck
    result = @[]
    for i in 0..51: result.add(i)
  else:
    result = @[]

proc stageCardCount*(stage: int): int =
  case stage
  of 0: 12
  of 1, 2, 3, 4: 13
  of 5: 26
  of 6: 52
  else: 0

proc checkStageUnlock*(stage: int; mastery: array[52, int]; progress: array[7, StageProgress]): bool =
  ## Returns true if a stage should be unlocked
  case stage
  of 0: true  # Always unlocked
  of 1:  # Hearts: heart face cards mastery >= 3
    mastery[cardIndex(Hearts, Jack)] >= 3 and
    mastery[cardIndex(Hearts, Queen)] >= 3 and
    mastery[cardIndex(Hearts, King)] >= 3
  of 2:  # Diamonds: diamond face cards mastery >= 3
    mastery[cardIndex(Diamonds, Jack)] >= 3 and
    mastery[cardIndex(Diamonds, Queen)] >= 3 and
    mastery[cardIndex(Diamonds, King)] >= 3
  of 3:  # Clubs: club face cards mastery >= 3
    mastery[cardIndex(Clubs, Jack)] >= 3 and
    mastery[cardIndex(Clubs, Queen)] >= 3 and
    mastery[cardIndex(Clubs, King)] >= 3
  of 4:  # Spades: spade face cards mastery >= 3
    mastery[cardIndex(Spades, Jack)] >= 3 and
    mastery[cardIndex(Spades, Queen)] >= 3 and
    mastery[cardIndex(Spades, King)] >= 3
  of 5:  # Half Deck: stages 2+3 completed
    progress[1].completed and progress[2].completed
  of 6:  # Full Deck: stages 4+5 completed
    progress[3].completed and progress[4].completed
  else: false

proc leitnerWeight*(mastery: int): int =
  if mastery >= 0 and mastery <= 5:
    LeitnerWeights[mastery]
  else:
    0

proc buildWeightedPool*(cardIndices: seq[int]; mastery: array[52, int]): seq[int] =
  ## Build weighted card pool where lower mastery cards appear more
  result = @[]
  var allMastered = true
  for ci in cardIndices:
    let w = leitnerWeight(mastery[ci])
    if w > 0:
      allMastered = false
    for j in 0..<w:
      result.add(ci)
  # If all mastered (weight 0), include each once
  if allMastered:
    for ci in cardIndices:
      result.add(ci)

proc suitThemeHint*(suit: Suit): string =
  case suit
  of Hearts: "Hearts are warm, loving characters."
  of Diamonds: "Diamonds are rich, glamorous figures."
  of Clubs: "Clubs are tough, athletic fighters."
  of Spades: "Spades are dark, mysterious beings."

## 52-card PAO (Person-Action-Object) table and deck operations

import types

var
  paoTable*: array[52, PaoEntry]
  deckOrder*: seq[int]  # indices into paoTable

proc initCardTable*() =
  # Hearts (0-12): Loved ones, performers, warm figures
  paoTable[cardIndex(Hearts, Ace)]   = PaoEntry(card: Card(suit: Hearts, rank: Ace),   person: "Elvis",       action: "singing to",      obj: "microphone")
  paoTable[cardIndex(Hearts, Two)]   = PaoEntry(card: Card(suit: Hearts, rank: Two),   person: "Cupid",       action: "shooting",        obj: "bow & arrow")
  paoTable[cardIndex(Hearts, Three)] = PaoEntry(card: Card(suit: Hearts, rank: Three), person: "Romeo",       action: "serenading",      obj: "balcony")
  paoTable[cardIndex(Hearts, Four)]  = PaoEntry(card: Card(suit: Hearts, rank: Four),  person: "Juliet",      action: "dancing with",    obj: "rose")
  paoTable[cardIndex(Hearts, Five)]  = PaoEntry(card: Card(suit: Hearts, rank: Five),  person: "Marilyn",     action: "blowing",         obj: "kiss")
  paoTable[cardIndex(Hearts, Six)]   = PaoEntry(card: Card(suit: Hearts, rank: Six),   person: "Ellen",       action: "laughing at",     obj: "joke book")
  paoTable[cardIndex(Hearts, Seven)] = PaoEntry(card: Card(suit: Hearts, rank: Seven), person: "Mr. Rogers",  action: "waving from",     obj: "cardigan")
  paoTable[cardIndex(Hearts, Eight)] = PaoEntry(card: Card(suit: Hearts, rank: Eight), person: "Oprah",       action: "giving away",     obj: "car keys")
  paoTable[cardIndex(Hearts, Nine)]  = PaoEntry(card: Card(suit: Hearts, rank: Nine),  person: "Einstein",    action: "scribbling on",   obj: "chalkboard")
  paoTable[cardIndex(Hearts, Ten)]   = PaoEntry(card: Card(suit: Hearts, rank: Ten),   person: "Mother Teresa",action: "hugging",        obj: "blanket")
  paoTable[cardIndex(Hearts, Jack)]  = PaoEntry(card: Card(suit: Hearts, rank: Jack),  person: "Prince",      action: "strumming",       obj: "guitar")
  paoTable[cardIndex(Hearts, Queen)] = PaoEntry(card: Card(suit: Hearts, rank: Queen), person: "Cleopatra",   action: "reclining on",    obj: "throne")
  paoTable[cardIndex(Hearts, King)]  = PaoEntry(card: Card(suit: Hearts, rank: King),  person: "King Arthur", action: "pulling out",     obj: "sword")

  # Diamonds (13-25): Rich, prestigious, glamorous
  paoTable[cardIndex(Diamonds, Ace)]   = PaoEntry(card: Card(suit: Diamonds, rank: Ace),   person: "Trump",       action: "pointing at",     obj: "gold tower")
  paoTable[cardIndex(Diamonds, Two)]   = PaoEntry(card: Card(suit: Diamonds, rank: Two),   person: "Midas",       action: "touching",        obj: "golden apple")
  paoTable[cardIndex(Diamonds, Three)] = PaoEntry(card: Card(suit: Diamonds, rank: Three), person: "Scrooge",     action: "diving into",     obj: "coin pile")
  paoTable[cardIndex(Diamonds, Four)]  = PaoEntry(card: Card(suit: Diamonds, rank: Four),  person: "Gatsby",      action: "toasting with",   obj: "champagne")
  paoTable[cardIndex(Diamonds, Five)]  = PaoEntry(card: Card(suit: Diamonds, rank: Five),  person: "James Bond",  action: "shuffling",       obj: "poker chips")
  paoTable[cardIndex(Diamonds, Six)]   = PaoEntry(card: Card(suit: Diamonds, rank: Six),   person: "Beyonce",     action: "strutting in",    obj: "high heels")
  paoTable[cardIndex(Diamonds, Seven)] = PaoEntry(card: Card(suit: Diamonds, rank: Seven), person: "Jay Leno",    action: "polishing",       obj: "sports car")
  paoTable[cardIndex(Diamonds, Eight)] = PaoEntry(card: Card(suit: Diamonds, rank: Eight), person: "Liberace",    action: "playing",         obj: "grand piano")
  paoTable[cardIndex(Diamonds, Nine)]  = PaoEntry(card: Card(suit: Diamonds, rank: Nine),  person: "Da Vinci",    action: "painting",        obj: "canvas")
  paoTable[cardIndex(Diamonds, Ten)]   = PaoEntry(card: Card(suit: Diamonds, rank: Ten),   person: "Rockefeller", action: "signing",         obj: "big check")
  paoTable[cardIndex(Diamonds, Jack)]  = PaoEntry(card: Card(suit: Diamonds, rank: Jack),  person: "Sinatra",     action: "crooning into",   obj: "martini glass")
  paoTable[cardIndex(Diamonds, Queen)] = PaoEntry(card: Card(suit: Diamonds, rank: Queen), person: "Marie Antoinette", action: "eating",     obj: "cake")
  paoTable[cardIndex(Diamonds, King)]  = PaoEntry(card: Card(suit: Diamonds, rank: King),  person: "Louis XIV",   action: "admiring",        obj: "mirror")

  # Clubs (26-38): Athletes, tough, action figures
  paoTable[cardIndex(Clubs, Ace)]   = PaoEntry(card: Card(suit: Clubs, rank: Ace),   person: "Ali",         action: "punching",        obj: "heavy bag")
  paoTable[cardIndex(Clubs, Two)]   = PaoEntry(card: Card(suit: Clubs, rank: Two),   person: "Hercules",    action: "lifting",         obj: "boulder")
  paoTable[cardIndex(Clubs, Three)] = PaoEntry(card: Card(suit: Clubs, rank: Three), person: "Ninja",       action: "throwing",        obj: "shuriken")
  paoTable[cardIndex(Clubs, Four)]  = PaoEntry(card: Card(suit: Clubs, rank: Four),  person: "Tarzan",      action: "swinging on",     obj: "vine")
  paoTable[cardIndex(Clubs, Five)]  = PaoEntry(card: Card(suit: Clubs, rank: Five),  person: "Schwarzenegger", action: "flexing",      obj: "dumbbell")
  paoTable[cardIndex(Clubs, Six)]   = PaoEntry(card: Card(suit: Clubs, rank: Six),   person: "Bruce Lee",   action: "kicking",         obj: "wooden dummy")
  paoTable[cardIndex(Clubs, Seven)] = PaoEntry(card: Card(suit: Clubs, rank: Seven), person: "Jordan",      action: "dunking",         obj: "basketball")
  paoTable[cardIndex(Clubs, Eight)] = PaoEntry(card: Card(suit: Clubs, rank: Eight), person: "Thor",        action: "swinging",        obj: "hammer")
  paoTable[cardIndex(Clubs, Nine)]  = PaoEntry(card: Card(suit: Clubs, rank: Nine),  person: "Robin Hood",  action: "firing",          obj: "longbow")
  paoTable[cardIndex(Clubs, Ten)]   = PaoEntry(card: Card(suit: Clubs, rank: Ten),   person: "Gladiator",   action: "slashing with",   obj: "trident")
  paoTable[cardIndex(Clubs, Jack)]  = PaoEntry(card: Card(suit: Clubs, rank: Jack),  person: "Rocky",       action: "running up",      obj: "stairs")
  paoTable[cardIndex(Clubs, Queen)] = PaoEntry(card: Card(suit: Clubs, rank: Queen), person: "Wonder Woman",action: "blocking with",   obj: "shield")
  paoTable[cardIndex(Clubs, King)]  = PaoEntry(card: Card(suit: Clubs, rank: King),  person: "Spartacus",   action: "rallying",        obj: "army flag")

  # Spades (39-51): Powerful, dark, mysterious
  paoTable[cardIndex(Spades, Ace)]   = PaoEntry(card: Card(suit: Spades, rank: Ace),   person: "Death",       action: "reaping with",    obj: "scythe")
  paoTable[cardIndex(Spades, Two)]   = PaoEntry(card: Card(suit: Spades, rank: Two),   person: "Dracula",     action: "biting into",     obj: "goblet")
  paoTable[cardIndex(Spades, Three)] = PaoEntry(card: Card(suit: Spades, rank: Three), person: "Houdini",     action: "escaping from",   obj: "chains")
  paoTable[cardIndex(Spades, Four)]  = PaoEntry(card: Card(suit: Spades, rank: Four),  person: "Darth Vader", action: "force-choking",   obj: "helmet")
  paoTable[cardIndex(Spades, Five)]  = PaoEntry(card: Card(suit: Spades, rank: Five),  person: "Sherlock",    action: "inspecting",      obj: "magnifier")
  paoTable[cardIndex(Spades, Six)]   = PaoEntry(card: Card(suit: Spades, rank: Six),   person: "Witch",       action: "stirring",        obj: "cauldron")
  paoTable[cardIndex(Spades, Seven)] = PaoEntry(card: Card(suit: Spades, rank: Seven), person: "Merlin",      action: "casting on",      obj: "crystal ball")
  paoTable[cardIndex(Spades, Eight)] = PaoEntry(card: Card(suit: Spades, rank: Eight), person: "Phantom",     action: "lurking behind",  obj: "mask")
  paoTable[cardIndex(Spades, Nine)]  = PaoEntry(card: Card(suit: Spades, rank: Nine),  person: "Rasputin",    action: "hypnotizing",     obj: "pendulum")
  paoTable[cardIndex(Spades, Ten)]   = PaoEntry(card: Card(suit: Spades, rank: Ten),   person: "Voldemort",   action: "zapping with",    obj: "wand")
  paoTable[cardIndex(Spades, Jack)]  = PaoEntry(card: Card(suit: Spades, rank: Jack),  person: "Joker",       action: "cackling at",     obj: "playing card")
  paoTable[cardIndex(Spades, Queen)] = PaoEntry(card: Card(suit: Spades, rank: Queen), person: "Medusa",      action: "petrifying",      obj: "mirror shield")
  paoTable[cardIndex(Spades, King)]  = PaoEntry(card: Card(suit: Spades, rank: King),  person: "Grim Reaper", action: "summoning",       obj: "hourglass")

proc newDeck*(): seq[int] =
  result = @[]
  for i in 0..<52:
    result.add(i)

proc shuffleDeck*(deck: var seq[int]) =
  for i in countdown(deck.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(deck[i], deck[j])

proc shuffleDeckSeeded*(deck: var seq[int], seed: int) =
  setRandomSeed(uint32(seed))
  shuffleDeck(deck)

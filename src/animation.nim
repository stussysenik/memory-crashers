## Easing functions, tweens, and particle system

import raylib
import types, palette
import std/math

# --- Easing functions ---

proc easeLinear*(t: float32): float32 = t

proc easeInQuad*(t: float32): float32 = t * t

proc easeOutQuad*(t: float32): float32 = t * (2.0 - t)

proc easeInOutQuad*(t: float32): float32 =
  if t < 0.5: 2.0 * t * t
  else: -1.0 + (4.0 - 2.0 * t) * t

proc easeOutBack*(t: float32): float32 =
  let c1 = 1.70158'f32
  let c3 = c1 + 1.0
  let t1 = t - 1.0
  1.0 + c3 * t1 * t1 * t1 + c1 * t1 * t1

proc easeOutBounce*(t: float32): float32 =
  var t = t
  if t < 1.0 / 2.75:
    7.5625 * t * t
  elif t < 2.0 / 2.75:
    t -= 1.5 / 2.75
    7.5625 * t * t + 0.75
  elif t < 2.5 / 2.75:
    t -= 2.25 / 2.75
    7.5625 * t * t + 0.9375
  else:
    t -= 2.625 / 2.75
    7.5625 * t * t + 0.984375

proc easeOutElastic*(t: float32): float32 =
  if t == 0 or t == 1: return t
  let c4 = (2.0 * PI) / 3.0
  pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0

proc applyEase*(kind: EaseKind, t: float32): float32 =
  case kind
  of EaseLinear: easeLinear(t)
  of EaseInQuad: easeInQuad(t)
  of EaseOutQuad: easeOutQuad(t)
  of EaseInOutQuad: easeInOutQuad(t)
  of EaseOutBack: easeOutBack(t)
  of EaseOutBounce: easeOutBounce(t)
  of EaseOutElastic: easeOutElastic(t)

# --- Tweens ---

proc newTween*(startVal, endVal, duration: float32, ease: EaseKind = EaseOutQuad): Tween =
  Tween(
    active: true,
    elapsed: 0,
    duration: duration,
    startVal: startVal,
    endVal: endVal,
    ease: ease,
    current: startVal,
  )

proc updateTween*(t: var Tween, dt: float32) =
  if not t.active: return
  t.elapsed += dt
  if t.elapsed >= t.duration:
    t.elapsed = t.duration
    t.active = false
  let progress = t.elapsed / t.duration
  let eased = applyEase(t.ease, progress)
  t.current = t.startVal + (t.endVal - t.startVal) * eased

proc isComplete*(t: Tween): bool = not t.active

# --- Particles ---

proc spawnParticle*(ps: var ParticleSystem, pos: Vector2, vel: Vector2,
                    life: float32, color: Color, size: float32 = 2.0) =
  # Find inactive particle or add new
  for p in ps.particles.mitems:
    if not p.active:
      p = Particle(active: true, pos: pos, vel: vel, life: life,
                    maxLife: life, color: color, size: size)
      return
  if ps.particles.len < MaxParticles:
    ps.particles.add(Particle(active: true, pos: pos, vel: vel, life: life,
                               maxLife: life, color: color, size: size))

proc spawnBurst*(ps: var ParticleSystem, pos: Vector2, count: int,
                 color: Color, speed: float32 = 50.0, life: float32 = 0.5) =
  for i in 0..<count:
    let angle = float32(getRandomValue(0, 360)) * PI / 180.0
    let spd = float32(getRandomValue(int32(speed * 0.5), int32(speed)))
    let vel = Vector2(x: cos(angle) * spd, y: sin(angle) * spd)
    let sz = float32(getRandomValue(1, 3))
    spawnParticle(ps, pos, vel, life, color, sz)

proc spawnConfetti*(ps: var ParticleSystem, pos: Vector2, count: int = 20) =
  let colors = [PalGold, PalGreen, PalCyan, PalPink, PalCoral, PalLime]
  for i in 0..<count:
    let angle = float32(getRandomValue(0, 360)) * PI / 180.0
    let spd = float32(getRandomValue(30, 80))
    let vel = Vector2(x: cos(angle) * spd, y: sin(angle) * spd - 30.0)
    let col = colors[getRandomValue(0, int32(colors.len - 1))]
    let sz = float32(getRandomValue(1, 3))
    spawnParticle(ps, pos, vel, 0.8, col, sz)

proc updateParticles*(ps: var ParticleSystem, dt: float32) =
  for p in ps.particles.mitems:
    if not p.active: continue
    p.life -= dt
    if p.life <= 0:
      p.active = false
      continue
    p.pos.x += p.vel.x * dt
    p.pos.y += p.vel.y * dt
    p.vel.y += 80.0 * dt  # gravity
    p.vel.x *= 0.98  # friction

proc drawParticles*(ps: ParticleSystem) =
  for p in ps.particles:
    if not p.active: continue
    let alpha = uint8(p.life / p.maxLife * 255.0)
    let col = Color(r: p.color.r, g: p.color.g, b: p.color.b, a: alpha)
    let sz = int32(p.size * (p.life / p.maxLife))
    if sz > 0:
      drawRectangle(int32(p.pos.x), int32(p.pos.y), sz, sz, col)

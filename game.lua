PLAYER_SPIRTE = { 1, 2, 3 }
ENEMY_SPRITE = { 17, 18, 19 }
WEAPON_SPRITES = {
  SWORD = 10,
  PAN = 11,
  SHIELD = 12,
  BROOM = 13
}

-- Controls
-- X = Attack
-- O = Dodge
-- X + O = Throw Weapon (direction of last movement, default to right)
-- Movement arrow keys move the player up down left right top down game

state = {}

function _init()
  srand(1)
  state = {
    map_w = 5,
    map_h = 5,
    rooms = {},
    room_x = 3,
    room_y = 3,
    enemies = {},
    drops = {},
    projectiles = {},
    explosions = {},
    death_anims = {},
    muzzle_flashes = {},
    screen_flashes = {},
    paused = false,
    pause_t = 0
  }

  init_map()
  init_player()
  enter_room(state.room_x, state.room_y, true)
end

function _update()
  if state.paused then
    state.pause_t -= 1
    if state.pause_t <= 0 then
      state.paused = false
    end
    update_juice()
    return
  end

  if update_player() then
    update_juice()
    return
  end
  update_enemies()
  update_projectiles()
  update_drops()
  update_juice()
end

function _draw()
  cls()
  apply_ss()
  draw_room()
  draw_drops()
  draw_projectiles()
  draw_enemies()
  draw_player()
  draw_anims(state.explosions)
  draw_anims(state.death_anims)
  draw_anims(state.screen_flashes)
  draw_ui()
end

function init_map()
  for x = 1, state.map_w do
    state.rooms[x] = {}
    for y = 1, state.map_h do
      state.rooms[x][y] = {
        doors = { n = false, s = false, e = false, w = false },
        generated = false,
        cleared = false
      }
    end
  end

  local sx, sy = state.room_x, state.room_y
  local ex, ey = sx, sy
  repeat
    ex, ey = flr(rnd(state.map_w)) + 1, flr(rnd(state.map_h)) + 1
  until ex != sx or ey != sy
  state.exit_room = { x = ex, y = ey }

  local cx, cy = sx, sy
  while cx != ex or cy != ey do
    local dir = flr(rnd(4)) + 1
    if cx < ex and rnd(1) < 0.6 then dir = 4 end
    if cx > ex and rnd(1) < 0.6 then dir = 3 end
    if cy < ey and rnd(1) < 0.6 then dir = 2 end
    if cy > ey and rnd(1) < 0.6 then dir = 1 end
    local nx, ny = cx, cy
    if dir == 1 and cy > 1 then ny -= 1 end
    if dir == 2 and cy < state.map_h then ny += 1 end
    if dir == 3 and cx > 1 then nx -= 1 end
    if dir == 4 and cx < state.map_w then nx += 1 end
    link_rooms(cx, cy, nx, ny)
    cx, cy = nx, ny
  end

  for x = 1, state.map_w do
    for y = 1, state.map_h do
      if x < state.map_w and rnd(1) < 0.35 then
        link_rooms(x, y, x + 1, y)
      end
      if y < state.map_h and rnd(1) < 0.35 then
        link_rooms(x, y, x, y + 1)
      end
    end
  end
end

function link_rooms(x1, y1, x2, y2)
  if x1 == x2 and y1 == y2 then return end
  local r1 = state.rooms[x1][y1]
  local r2 = state.rooms[x2][y2]
  if x2 == x1 + 1 then r1.doors.e, r2.doors.w = true, true end
  if x2 == x1 - 1 then r1.doors.w, r2.doors.e = true, true end
  if y2 == y1 + 1 then r1.doors.s, r2.doors.n = true, true end
  if y2 == y1 - 1 then r1.doors.n, r2.doors.s = true, true end
end

function init_player()
  state.player = {
    x = 64,
    y = 64,
    w = 8,
    h = 8,
    hp = 1,
    max_hp = 1,
    speed = 1.3,
    last_dir = { x = 1, y = 0 },
    invuln_t = 0,
    dodge_t = 0,
    attack_t = 0,
    attack_hit = {},
    weapons = {}
  }
end

function enter_room(rx, ry, from_init)
  state.room_x, state.room_y = rx, ry
  state.enemies = {}
  state.drops = {}
  state.projectiles = {}
  local room = state.rooms[rx][ry]
  if not room.generated then
    room.generated = true
    local count = flr(rnd(3)) + 2
    for i = 1, count do
      add(state.enemies, make_enemy())
    end
  elseif room.cleared then
    -- no enemies
  else
    local count = flr(rnd(2)) + 1
    for i = 1, count do
      add(state.enemies, make_enemy())
    end
  end

  if not from_init then
    state.player.invuln_t = 10
  end
end

function make_enemy()
  return {
    x = flr(rnd(96)) + 16,
    y = flr(rnd(96)) + 16,
    w = 8,
    h = 8,
    hp = flr(rnd(2)) + 1,
    dmg = 1,
    speed = 0.6,
    stun_t = 0
  }
end

function update_player()
  local p = state.player
  if p.hp <= 0 then
    if btnp(4) or btnp(5) then
      _init()
    end
    return true
  end

  if p.invuln_t > 0 then p.invuln_t -= 1 end

  local both_held = btn(4) and btn(5)
  if both_held and not p.throw_held then
    p.throw_held = true
    try_throw_weapon()
  elseif not both_held then
    p.throw_held = false
  elseif btnp(4) and p.attack_t <= 0 and p.dodge_t <= 0 then
    start_attack()
  elseif btnp(5) and p.dodge_t <= 0 then
    start_dodge()
  end

  local move_x, move_y = 0, 0
  if btn(0) then move_x -= 1 end
  if btn(1) then move_x += 1 end
  if btn(2) then move_y -= 1 end
  if btn(3) then move_y += 1 end

  if move_x != 0 or move_y != 0 then
    local len = sqrt(move_x * move_x + move_y * move_y)
    p.last_dir = { x = move_x / len, y = move_y / len }
  end

  local spd = p.speed
  if p.dodge_t > 0 then
    p.dodge_t -= 1
    spd = 3.0
  end

  local dx, dy = move_x * spd, move_y * spd
  p.x, p.y = sweep_move(
    p.x, p.y, dx, dy, function(nx, ny)
      return room_collides(nx, ny, p.w, p.h)
    end
  )

  if p.attack_t > 0 then
    p.attack_t -= 1
    do_attack_hit()
  end

  handle_room_transition()
end

function start_attack()
  local p = state.player
  p.attack_t = 6
  p.attack_hit = {}
end

function do_attack_hit()
  local p = state.player
  local dir = p.last_dir
  local ax = p.x + p.w / 2 + dir.x * 8 - 4
  local ay = p.y + p.h / 2 + dir.y * 8 - 4
  local aw, ah = 8, 8
  for i = #state.enemies, 1, -1 do
    local e = state.enemies[i]
    if not p.attack_hit[e] and collisions.rect_rect(ax, ay, aw, ah, e.x, e.y, e.w, e.h) then
      p.attack_hit[e] = true
      damage_enemy(e, 1, false)
    end
  end
end

function start_dodge()
  local p = state.player
  p.dodge_t = 8
  p.invuln_t = max(p.invuln_t, 10)
end

function try_throw_weapon()
  local p = state.player
  if #p.weapons <= 0 then return end
  local weapon = p.weapons[#p.weapons]
  deli(p.weapons, #p.weapons)
  local dir = p.last_dir
  local proj = {
    x = p.x + 2,
    y = p.y + 2,
    w = 4,
    h = 4,
    dx = dir.x * 3.2,
    dy = dir.y * 3.2,
    spr = weapon.spr
  }
  add(state.projectiles, proj)
end

function update_enemies()
  local p = state.player
  for i = #state.enemies, 1, -1 do
    local e = state.enemies[i]
    if e.hp <= 0 then
      add_explosion(e.x + 4, e.y + 4, 1, 5, 8)
      if rnd(1) < 0.6 then
        add(state.drops, make_drop(e.x, e.y))
      end
      deli(state.enemies, i)
    else
      if e.stun_t > 0 then
        e.stun_t -= 1
      else
        local vx, vy = 0, 0
        if p.hp > 0 then
          vx = sgn(p.x - e.x) * e.speed
          vy = sgn(p.y - e.y) * e.speed
        else
          if e.wander_t == nil or e.wander_t <= 0 then
            e.wander_t = flr(rnd(40)) + 20
            local ang = rnd(1)
            e.wander_dx = cos(ang) * e.speed
            e.wander_dy = sin(ang) * e.speed
          end
          e.wander_t -= 1
          vx = e.wander_dx or 0
          vy = e.wander_dy or 0
        end
        e.x, e.y = sweep_move(
          e.x, e.y, vx, vy, function(nx, ny)
            return room_collides(nx, ny, e.w, e.h)
          end
        )
      end

      if p.hp > 0 then
        if p.invuln_t <= 0 and collisions.rect_rect(p.x, p.y, p.w, p.h, e.x, e.y, e.w, e.h) then
          player_hit(e, e.dmg or 1)
        end
      end
    end
  end

  if #state.enemies == 0 then
    local room = state.rooms[state.room_x][state.room_y]
    room.cleared = true
  end
end

function update_projectiles()
  for i = #state.projectiles, 1, -1 do
    local pr = state.projectiles[i]
    local nx, ny = pr.x + pr.dx, pr.y + pr.dy
    if room_collides(nx, ny, pr.w, pr.h) then
      add(state.drops, { x = pr.x, y = pr.y, spr = pr.spr })
      deli(state.projectiles, i)
    else
      pr.x, pr.y = nx, ny
      local hit = false
      for j = #state.enemies, 1, -1 do
        local e = state.enemies[j]
        if collisions.rect_rect(pr.x, pr.y, pr.w, pr.h, e.x, e.y, e.w, e.h) then
          damage_enemy(e, 1, true)
          hit = true
          break
        end
      end
      if hit then
        deli(state.projectiles, i)
      end
    end
  end
end

function update_drops()
  local p = state.player
  for i = #state.drops, 1, -1 do
    local d = state.drops[i]
    if collisions.rect_rect(p.x, p.y, p.w, p.h, d.x, d.y, 8, 8) then
      if #p.weapons < 4 then
        add(p.weapons, { spr = d.spr, dur = 1 })
        deli(state.drops, i)
      end
    end
  end
end

function player_hit(e, dmg)
  local p = state.player
  local hit_dmg = flr(dmg or 1)
  if hit_dmg < 1 then
    hit_dmg = 1
  end
  p.invuln_t = 20
  if #p.weapons > 0 then
    local top = p.weapons[1]
    top.dur -= hit_dmg
    if top.dur <= 0 then
      deli(p.weapons, 1)
    end
  else
    p.hp = max(0, p.hp - hit_dmg)
  end

  local dx = sgn(p.x - e.x) * 6
  local dy = sgn(p.y - e.y) * 6
  p.x, p.y = sweep_move(
    p.x, p.y, dx, dy, function(nx, ny)
      return room_collides(nx, ny, p.w, p.h)
    end
  )
  ss(6, 2)
  hitstop(2)
end

function damage_enemy(e, dmg, from_throw)
  e.hp -= dmg
  if from_throw then
    e.stun_t = 30
  end
end

function make_drop(x, y)
  local keys = { WEAPON_SPRITES.SWORD, WEAPON_SPRITES.PAN, WEAPON_SPRITES.SHIELD, WEAPON_SPRITES.BROOM }
  local spr_id = keys[flr(rnd(#keys)) + 1]
  return { x = x, y = y, spr = spr_id }
end

function handle_room_transition()
  local p = state.player
  local room = state.rooms[state.room_x][state.room_y]
  if p.x < 0 and room.doors.w then
    enter_room(state.room_x - 1, state.room_y)
    p.x = 120
  elseif p.x > 120 and room.doors.e then
    enter_room(state.room_x + 1, state.room_y)
    p.x = 0
  elseif p.y < 0 and room.doors.n then
    enter_room(state.room_x, state.room_y - 1)
    p.y = 120
  elseif p.y > 120 and room.doors.s then
    enter_room(state.room_x, state.room_y + 1)
    p.y = 0
  end
end

function room_collides(x, y, w, h)
  local t = 6
  local door_w = 28
  local left = x < t
  local right = x + w > 128 - t
  local top = y < t
  local bottom = y + h > 128 - t
  local room = state.rooms[state.room_x][state.room_y]
  if left then
    if room.doors.w and y + h > 64 - door_w / 2 and y < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if right then
    if room.doors.e and y + h > 64 - door_w / 2 and y < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if top then
    if room.doors.n and x + w > 64 - door_w / 2 and x < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if bottom then
    if room.doors.s and x + w > 64 - door_w / 2 and x < 64 + door_w / 2 then
      return false
    end
    return true
  end
  return false
end

function draw_room()
  rectfill(0, 0, 127, 127, 1)
  local t = 6
  rectfill(0, 0, 127, t, 5)
  rectfill(0, 127 - t, 127, 127, 5)
  rectfill(0, 0, t, 127, 5)
  rectfill(127 - t, 0, 127, 127, 5)

  local room = state.rooms[state.room_x][state.room_y]
  local door_w = 28
  if room.doors.n then rectfill(64 - door_w / 2, 0, 64 + door_w / 2, t, 1) end
  if room.doors.s then rectfill(64 - door_w / 2, 127 - t, 64 + door_w / 2, 127, 1) end
  if room.doors.w then rectfill(0, 64 - door_w / 2, t, 64 + door_w / 2, 1) end
  if room.doors.e then rectfill(127 - t, 64 - door_w / 2, 127, 64 + door_w / 2, 1) end

  if state.room_x == state.exit_room.x and state.room_y == state.exit_room.y then
    circfill(64, 64, 3, 10)
  end
end

function draw_player()
  local p = state.player
  if p.hp <= 0 then
    spr(6, p.x, p.y)
    return
  end
  local flicker = p.invuln_t > 0 and (p.invuln_t % 4) < 2
  if not flicker then
    spr(PLAYER_SPIRTE[1], p.x, p.y)
  end
  if p.attack_t > 0 then
    local dir = p.last_dir
    local ax = p.x + p.w / 2 + dir.x * 8 - 4
    local ay = p.y + p.h / 2 + dir.y * 8 - 4
    rect(ax, ay, ax + 7, ay + 7, 8)
  end
end

function draw_enemies()
  for e in all(state.enemies) do
    spr(ENEMY_SPRITE[1], e.x, e.y)
    if e.stun_t > 0 then
      rect(e.x, e.y - 2, e.x + 7, e.y - 1, 9)
    end
  end
end

function draw_projectiles()
  for pr in all(state.projectiles) do
    spr(pr.spr, pr.x, pr.y)
  end
end

function draw_drops()
  for d in all(state.drops) do
    spr(d.spr, d.x, d.y)
  end
end
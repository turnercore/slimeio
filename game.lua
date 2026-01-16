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
  srand(time())
  state = {
    map_w = 5,
    map_h = 5,
    rooms = {},
    room_x = 3,
    room_y = 3,
    start_room = { x = 3, y = 3 },
    level = 1,
    enemies = {},
    drops = {},
    projectiles = {},
    explosions = {},
    death_anims = {},
    muzzle_flashes = {},
    screen_flashes = {},
    paused = false,
    pause_t = 0,
    t = 0
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

  state.t = (state.t or 0) + 1
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
  state.start_room = { x = state.room_x, y = state.room_y }
  local floor_cols = { 1, 2, 3, 4 }
  for x = 1, state.map_w do
    state.rooms[x] = {}
    for y = 1, state.map_h do
      state.rooms[x][y] = {
        doors = { n = false, s = false, e = false, w = false },
        generated = false,
        cleared = false,
        spawn_pending = false,
        spawn_t = 0,
        floor_col = floor_cols[flr(rnd(#floor_cols)) + 1]
      }
    end
  end

  local sx, sy = state.start_room.x, state.start_room.y
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
    combo_step = 0,
    combo_t = 0,
    attack_cd = 0,
    throw_cd = 0,
    throw_held = false,
    weapons = {}
  }
end

function enter_room(rx, ry, from_init)
  state.room_x, state.room_y = rx, ry
  state.enemies = {}
  state.drops = {}
  state.projectiles = {}
  local room = state.rooms[rx][ry]
  room.spawn_t = 75
  room.spawn_pending = not room.cleared
  if not room.generated then
    room.generated = true
    if rx == state.start_room.x and ry == state.start_room.y then
      room.spawn_list = { make_tutorial_enemy() }
      room.spawn_t = 0
    else
      local count = flr(rnd(3)) + 2
      room.spawn_list = {}
      for i = 1, count do
        add(room.spawn_list, make_enemy())
      end
    end
  elseif room.cleared then
    -- no enemies
  else
    local count = flr(rnd(2)) + 1
    room.spawn_list = {}
    for i = 1, count do
      add(room.spawn_list, make_enemy())
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
    hp = 3,
    max_hp = 3,
    dmg = 1,
    speed = 0.6,
    stun_t = 0
  }
end

function make_tutorial_enemy()
  local e = make_enemy()
  e.no_attack = true
  e.no_move = true
  e.force_drop = true
  e.hp = 2
  e.max_hp = 2
  return e
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

  if p.attack_cd > 0 then
    p.attack_cd -= 1
  end

  if p.throw_cd > 0 then
    p.throw_cd -= 1
  end

  local both_held = btn(4) and btn(5)
  if both_held and not p.throw_held then
    p.throw_held = true
    if p.throw_cd <= 0 then
      try_throw_weapon()
    end
  elseif not both_held then
    p.throw_held = false
  end

  if not both_held then
    if btnp(4) and p.attack_t <= 0 and p.dodge_t <= 0 and p.attack_cd <= 0 then
      start_attack()
    elseif btnp(5) and p.dodge_t <= 0 then
      start_dodge()
    end
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

  if p.combo_t > 0 then
    p.combo_t -= 1
    if p.combo_t <= 0 then
      p.combo_step = 0
    end
  end

  if p.attack_t > 0 then
    p.attack_t -= 1
    do_attack_hit()
  end

  handle_room_transition()
  handle_exit()
end

function handle_exit()
  local p = state.player
  local room = state.rooms[state.room_x][state.room_y]
  if not room.cleared or #state.enemies > 0 or room.spawn_pending then return end
  if state.room_x != state.exit_room.x or state.room_y != state.exit_room.y then
    return
  end
  if collisions.rect_rect(p.x, p.y, p.w, p.h, 60, 60, 8, 8) and btnp(3) then
    new_level()
  end
end

function new_level()
  state.level = (state.level or 1) + 1
  state.room_x, state.room_y = 3, 3
  init_map()
  enter_room(state.room_x, state.room_y, true)
  state.player.x, state.player.y = 64, 64
end

function start_attack()
  local p = state.player
  local weapon_count = #p.weapons
  local max_combo = min(weapon_count, 4)
  if weapon_count <= 0 then
    p.combo_step = 0
    p.combo_t = 0
  else
    p.combo_step = p.combo_step + 1
    if p.combo_step > max_combo then
      p.combo_step = 1
    end
    p.combo_t = 45
  end
  p.attack_hit = {}
  p.attack_boxes, p.attack_dmg, p.attack_t = get_attack_data(p)
  p.attack_fx_kind = p.combo_step
  p.attack_fx_weapon = nil
  if weapon_count > 0 then
    local w = p.weapons[p.combo_step]
    if w then p.attack_fx_weapon = w.spr end
  end
  p.attack_cd = 12
end

function do_attack_hit()
  local p = state.player
  if not p.attack_boxes then return end
  local dmg = p.attack_dmg or 1
  local pad = 3
  for i = #state.enemies, 1, -1 do
    local e = state.enemies[i]
    if not p.attack_hit[e] then
      for b in all(p.attack_boxes) do
        if collisions.rect_rect(b.x - pad, b.y - pad, b.w + pad * 2, b.h + pad * 2, e.x, e.y, e.w, e.h) then
          p.attack_hit[e] = true
          damage_enemy(e, dmg, false, p.x + p.w / 2, p.y + p.h / 2, 3)
          break
        end
      end
    end
  end
end

function get_attack_data(p)
  local dir = p.last_dir
  local center_x = p.x + p.w / 2
  local center_y = p.y + p.h / 2
  local boxes = {}
  local dmg = 1
  local dur = 6
  local px, py = -dir.y, dir.x

  if #p.weapons <= 0 then
    local ax = center_x + dir.x * 8 - 4
    local ay = center_y + dir.y * 8 - 4
    add(boxes, { x = ax, y = ay, w = 8, h = 8 })
    dmg = 1
    dur = 12
    return boxes, dmg, dur
  end
  local weapon = p.weapons[p.combo_step]
  if weapon and weapon.dmg then
    dmg = weapon.dmg * p.combo_step
  end

  if p.combo_step == 1 then
    local ax = center_x + dir.x * 10 - 4
    local ay = center_y + dir.y * 10 - 4
    add(boxes, { x = ax, y = ay, w = 8, h = 8 })
    dur = 6
  elseif p.combo_step == 2 then
    local ax = center_x + dir.x * 8 - 4
    local ay = center_y + dir.y * 8 - 4
    add(boxes, { x = ax - px * 6, y = ay - py * 6, w = 8, h = 8 })
    add(boxes, { x = ax, y = ay, w = 8, h = 8 })
    add(boxes, { x = ax + px * 6, y = ay + py * 6, w = 8, h = 8 })
    dur = 7
  elseif p.combo_step == 3 then
    add(boxes, { x = p.x - 4, y = p.y - 4, w = 16, h = 16 })
    dur = 6
  else
    for i = 1, 3 do
      local dist = 8 * i
      local ax = center_x + dir.x * dist - 4
      local ay = center_y + dir.y * dist - 4
      add(boxes, { x = ax, y = ay, w = 8, h = 8 })
    end
    dur = 8
  end

  return boxes, dmg, dur
end

function start_dodge()
  local p = state.player
  p.dodge_t = 8
  p.invuln_t = max(p.invuln_t, 10)
end

function try_throw_weapon()
  local p = state.player
  if #p.weapons <= 0 then return end
  local weapon = p.weapons[1]
  weapon.dur = max(0, (weapon.dur or 1) - 1)
  if weapon.dur <= 0 then
    weapon.dur = 0
  end
  deli(p.weapons, 1)
  p.combo_step = 0
  p.combo_t = 0
  p.throw_cd = 60
  local dir = p.last_dir
  local proj = {
    x = p.x + 2,
    y = p.y + 2,
    w = 4,
    h = 4,
    dx = dir.x * 3.2,
    dy = dir.y * 3.2,
    spr = weapon.spr,
    dmg = weapon.dmg or 1,
    dur = weapon.dur or 0
  }
  add(state.projectiles, proj)
end

function update_enemies()
  local room = state.rooms[state.room_x][state.room_y]
  if room.spawn_pending then
    room.spawn_t = room.spawn_t - 1
    if room.spawn_t <= 0 then
      room.spawn_pending = false
      if room.spawn_list then
        for e in all(room.spawn_list) do
          add(state.enemies, e)
        end
        room.spawn_list = nil
      end
    end
  end
  local p = state.player
  for i = #state.enemies, 1, -1 do
    local e = state.enemies[i]
    if e.hp <= 0 then
      add_explosion(e.x + 4, e.y + 4, 1, 5, 8)
      if e.force_drop or rnd(1) < 0.6 then
        add(state.drops, make_drop(e.x, e.y))
      end
      deli(state.enemies, i)
    else
      if e.stun_t > 0 then
        e.stun_t -= 1
      else
        if not e.no_move then
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
      end

      if p.hp > 0 and not e.no_attack then
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
      if (pr.dur or 0) > 0 then
        add(state.drops, { x = pr.x, y = pr.y, spr = pr.spr, dmg = pr.dmg, dur = pr.dur })
      end
      deli(state.projectiles, i)
    else
      pr.x, pr.y = nx, ny
      local hit = false
      for j = #state.enemies, 1, -1 do
        local e = state.enemies[j]
        if collisions.rect_rect(pr.x, pr.y, pr.w, pr.h, e.x, e.y, e.w, e.h) then
          apply_throw_impact(pr)
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

function apply_throw_impact(pr)
  local cx = pr.x + pr.w / 2
  local cy = pr.y + pr.h / 2
  local aoe_r = 16
  local aoe_r2 = aoe_r * aoe_r
  local hit_any = false
  for e in all(state.enemies) do
    local ex = e.x + e.w / 2
    local ey = e.y + e.h / 2
    local dx = ex - cx
    local dy = ey - cy
    if dx * dx + dy * dy <= aoe_r2 then
      e.stun_t = max(e.stun_t or 0, 90)
      local len = sqrt(dx * dx + dy * dy)
      if len > 0 then
        local kx = dx / len * 4
        local ky = dy / len * 4
        e.x, e.y = sweep_move(e.x, e.y, kx, ky, function(nx, ny)
          return room_collides(nx, ny, e.w, e.h)
        end)
      end
      hit_any = true
    end
    if collisions.rect_rect(pr.x, pr.y, pr.w, pr.h, e.x, e.y, e.w, e.h) then
      damage_enemy(e, pr.dmg or 1, true, cx, cy, 2)
    end
  end
  if hit_any then
    ss(8, 2)
  end
end

function update_drops()
  local p = state.player
  for i = #state.drops, 1, -1 do
    local d = state.drops[i]
    if d.fly_t and d.fly_t > 0 then
      d.fly_t -= 1
      d.x += d.vx
      d.y += d.vy
      d.vx *= 0.9
      d.vy *= 0.9
    end
    if (not d.fly_t or d.fly_t <= 0) and collisions.rect_rect(p.x, p.y, p.w, p.h, d.x, d.y, 8, 8) then
      if #p.weapons < 4 then
        local stats = weapon_stats(d.spr)
        add(p.weapons, { spr = d.spr, dmg = d.dmg or stats.dmg, dur = d.dur or stats.dur })
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
    local top = p.weapons[#p.weapons]
    top.dur -= hit_dmg
    if top.dur <= 0 then
      deli(p.weapons, #p.weapons)
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
  ss(10, 3)
  add_screen_flash(6, 8)
  hitstop(2)
end

function damage_enemy(e, dmg, from_throw, src_x, src_y, kb)
  e.hp -= dmg
  local stun = from_throw and 90 or 8
  e.stun_t = max(e.stun_t or 0, stun)
  if src_x and src_y and kb and kb > 0 then
    local dx = e.x + e.w / 2 - src_x
    local dy = e.y + e.h / 2 - src_y
    local len = sqrt(dx * dx + dy * dy)
    if len > 0 then
      dx = dx / len
      dy = dy / len
      local kx = dx * kb
      local ky = dy * kb
      e.x, e.y = sweep_move(e.x, e.y, kx, ky, function(nx, ny)
        return room_collides(nx, ny, e.w, e.h)
      end)
    end
  end
end

function make_drop(x, y)
  local keys = { WEAPON_SPRITES.SWORD, WEAPON_SPRITES.PAN, WEAPON_SPRITES.SHIELD, WEAPON_SPRITES.BROOM }
  local spr_id = keys[flr(rnd(#keys)) + 1]
  local stats = weapon_stats(spr_id)
  local ang = rnd(1)
  return {
    x = x,
    y = y,
    spr = spr_id,
    dmg = stats.dmg,
    dur = stats.dur,
    fly_t = 12,
    vx = cos(ang) * 1.4,
    vy = sin(ang) * 1.4
  }
end

function weapon_stats(spr)
  local stats = {
    [WEAPON_SPRITES.SWORD] = { dmg = 1, dur = 1 },
    [WEAPON_SPRITES.PAN] = { dmg = 1, dur = 1 },
    [WEAPON_SPRITES.SHIELD] = { dmg = 1, dur = 1 },
    [WEAPON_SPRITES.BROOM] = { dmg = 1, dur = 1 }
  }
  return stats[spr] or { dmg = 1, dur = 1 }
end

function handle_room_transition()
  local p = state.player
  local room = state.rooms[state.room_x][state.room_y]
  if #state.enemies > 0 or room.spawn_pending then
    return
  end
  local t = 6
  local door_w = 28
  local door_min = 64 - door_w / 2
  local door_max = 64 + door_w / 2
  if p.x < 0 and room.doors.w then
    enter_room(state.room_x - 1, state.room_y)
    p.x = 128 - t - p.w
    p.y = mid(door_min + 1, p.y, door_max - p.h - 1)
  elseif p.x > 120 and room.doors.e then
    enter_room(state.room_x + 1, state.room_y)
    p.x = t
    p.y = mid(door_min + 1, p.y, door_max - p.h - 1)
  elseif p.y < 0 and room.doors.n then
    enter_room(state.room_x, state.room_y - 1)
    p.y = 128 - t - p.h
    p.x = mid(door_min + 1, p.x, door_max - p.w - 1)
  elseif p.y > 120 and room.doors.s then
    enter_room(state.room_x, state.room_y + 1)
    p.y = t
    p.x = mid(door_min + 1, p.x, door_max - p.w - 1)
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
  local locked = #state.enemies > 0 or room.spawn_pending
  if left then
    if not locked and room.doors.w and y + h > 64 - door_w / 2 and y < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if right then
    if not locked and room.doors.e and y + h > 64 - door_w / 2 and y < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if top then
    if not locked and room.doors.n and x + w > 64 - door_w / 2 and x < 64 + door_w / 2 then
      return false
    end
    return true
  end
  if bottom then
    if not locked and room.doors.s and x + w > 64 - door_w / 2 and x < 64 + door_w / 2 then
      return false
    end
    return true
  end
  return false
end

function draw_room()
  local room = state.rooms[state.room_x][state.room_y]
  rectfill(0, 0, 127, 127, room.floor_col or 1)
  local t = 6
  rectfill(0, 0, 127, t, 5)
  rectfill(0, 127 - t, 127, 127, 5)
  rectfill(0, 0, t, 127, 5)
  rectfill(127 - t, 0, 127, 127, 5)

  local locked = #state.enemies > 0 or room.spawn_pending
  local door_w = 28
  if room.doors.n and not locked then rectfill(64 - door_w / 2, 0, 64 + door_w / 2, t, 1) end
  if room.doors.s and not locked then rectfill(64 - door_w / 2, 127 - t, 64 + door_w / 2, 127, 1) end
  if room.doors.w and not locked then rectfill(0, 64 - door_w / 2, t, 64 + door_w / 2, 1) end
  if room.doors.e and not locked then rectfill(127 - t, 64 - door_w / 2, 127, 64 + door_w / 2, 1) end

  if room.cleared and state.room_x == state.exit_room.x and state.room_y == state.exit_room.y then
    spr(62, 56, 56, 2, 2)
  end
  if state.room_x == state.start_room.x and state.room_y == state.start_room.y then
    spr(63, 56, 56, 2, 2)
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
  if p.attack_t > 0 and p.attack_boxes then
    draw_attack_fx(p)
  end
end

function draw_attack_fx(p)
  local dir = p.last_dir
  local cx = p.x + p.w / 2
  local cy = p.y + p.h / 2
  local px, py = -dir.y, dir.x
  local col = 10
  local spr_id = p.attack_fx_weapon

  if #p.weapons <= 0 or p.attack_fx_kind == 0 then
    return
  end

  if p.attack_fx_kind == 1 then
    if spr_id then
      spr(spr_id, cx + dir.x * 10 - 4, cy + dir.y * 10 - 4)
    end
  elseif p.attack_fx_kind == 2 then
    for i = -1, 1 do
      local ox = px * i * 6
      local oy = py * i * 6
      if spr_id then
        spr(spr_id, cx + ox + dir.x * 10 - 4, cy + oy + dir.y * 10 - 4)
      end
    end
  elseif p.attack_fx_kind == 3 then
    if spr_id then
      spr(spr_id, cx + 12 - 4, cy - 4)
      spr(spr_id, cx - 12 - 4, cy - 4)
      spr(spr_id, cx - 4, cy + 12 - 4)
      spr(spr_id, cx - 4, cy - 12 - 4)
    end
  else
    line(cx, cy, cx + dir.x * 24, cy + dir.y * 24, col)
    if spr_id then
      spr(spr_id, cx + dir.x * 22 - 4, cy + dir.y * 22 - 4)
    end
  end
end

function draw_enemies()
  for e in all(state.enemies) do
    spr(ENEMY_SPRITE[1], e.x, e.y)
    if e.max_hp and e.hp < e.max_hp then
      local ratio = e.hp / e.max_hp
      local bw = 8
      local filled = flr(bw * ratio)
      rectfill(e.x, e.y - 3, e.x + bw - 1, e.y - 2, 0)
      rectfill(e.x, e.y - 3, e.x + filled - 1, e.y - 2, 11)
    end
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

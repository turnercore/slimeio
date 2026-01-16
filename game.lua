state = {}

function _init()
  --enable hidden colors
  -- srand(time())
  state = {
    mode = "menu",
    map_w = 5,
    map_h = 5,
    rooms = {},
    room_x = 3,
    room_y = 3,
    start_room = { x = 3, y = 3 },
    level = 1,
    enemies = {},
    drops = {},
    enemy_projectiles = {},
    corpses = {},
    effects = {},
    explosions = {},
    death_anims = {},
    screen_flashes = {},
    paused = false,
    pause_t = 0,
    t = 0,
    logo_t = 0,
    score = 0,
    pickup_msg = nil,
    pickup_t = 0,
    gameover_t = nil,
    floor_color = rand_floor_color(),
    ss_t = 0
  }
  init_map()
  init_player()
  enter_room(state.room_x, state.room_y, true)
end

function _update()
  if state.mode == "menu" then
    if state.menu_ready and (btnp(4) or btnp(5)) then
      state.mode = "game"
    end
    return
  end
  if state.paused then
    state.pause_t -= 1
    if state.pause_t <= 0 then
      state.paused = false
    end
    update_juice()
    return
  end

  state.t = state.t + 1
  if update_player() then
    update_juice()
    return
  end
  update_enemies()
  update_projectiles()
  update_enemy_projectiles()
  update_drops()
  update_juice()
end

function _draw()
  cls()
  if state.mode == "menu" then
    draw_menu()
    return
  end
  apply_ss()
  draw_room()
  draw_slime()
  draw_spawn_markers()
  draw_corpses()
  draw_drops()
  draw_projectiles()
  draw_enemy_projectiles()
  draw_enemies()
  draw_player()
  draw_anim_lists({ state.explosions, state.death_anims, state.screen_flashes })
  draw_fx()
  draw_ui()
  draw_game_over()
end

function draw_game_over()
  local p = state.player
  if p.hp > 0 then return end
  game_over_overlay_dim()
  -- rectfill(16, 44, 111, 88, 0)
  local msg = "you have slime'd"
  local score_txt = "score " .. state.score
  local mx = (128 - (#msg * 4)) \ 2
  local sx = (128 - (#score_txt * 4)) \ 2
  draw_shiny_text(msg, mx, 52, { 7, 11, 3, 8 }, state.gameover_t)
  print(score_txt, sx, 62, 7)
  if p.dead_t and p.dead_t <= 0 then
    local restart = "press x or o to restart"
    local rx = (128 - (#restart * 4)) \ 2
    print(restart, rx, 76, 6)
  end
end

function draw_shiny_text(txt, x, y, cols, t)
  local w = #txt * 4 + (#cols - 1) * 3
  local h = 6
  local cw = min(t, w)
  for layer = 0, #cols - 1 do
    clip(x, y, cw - 3 * layer, h)
    print(txt, x, y, cols[layer + 1])
  end
  clip()
end

function draw_menu()
  cls(-14)
  if not state.logo_w then
    init_shiny_logo("slimeo's saga", { 7, 12, 3, 11 })
  end
  local wipe_w = min(state.logo_t, 61)
  local ry = state.logo_center_y - 2
  local rx = state.logo_rect_center_x
  local ty = state.logo_center_y
  local tx = state.logo_text_center_x
  if state.logo_moved then
    ry = flr(state.logo_center_y + (state.logo_y_target - state.logo_center_y) * state.logo_move_t) - 2
    rx = flr(state.logo_rect_center_x + (state.logo_rect_target_x - state.logo_rect_center_x) * state.logo_move_t)
    ty = flr(state.logo_center_y + (state.logo_y_target - state.logo_center_y) * state.logo_move_t)
    tx = flr(state.logo_text_center_x + (state.logo_text_target_x - state.logo_text_center_x) * state.logo_move_t)
  end
  clip(rx, ry, wipe_w, 10)
  rrect(rx, ry, 61, 10, 2, 14)
  clip()
  draw_shiny_logo("slimeo's saga", tx, ty, { 7, 12, 3, 11 })
  if state.logo_t < state.logo_w then
    state.logo_t += 1
    return
  end
  if not state.logo_moved then
    state.logo_moved = true
    state.logo_move_t = 0
  end
  if state.logo_move_t < 1 then
    state.logo_move_t = min(1, state.logo_move_t + 0.05)
    return
  end
  if not state.menu_music_started then
    music(0)
    state.menu_music_started = true
  end
  state.menu_ready = true
  print("A JELLY'S JOURNEY DEMAKE", 16, 30, 6)
  if not state.menu_typed then
    state.menu_typed = true
    print("\^d2press o or x to start", 22, 40, 7)
  else
    print("press o or x to start", 22, 40, 7)
  end
  print("controls", 45, 72, 6)
  print("move", 8, 82, 11)
  print("attack", 8, 92, 11)
  print("dodge", 8, 102, 11)
  print("throw", 8, 112, 11)
  print(": UP/DOWN/LEFT/RIGHT", 35, 82, 7)
  print(": x (keyboard Z)", 35, 92, 7)
  print(": o (keyboard X)", 35, 102, 7)
  print(": x+o", 35, 112, 7)
end

function init_shiny_logo(txt, cols)
  clip(0, 0, 0, 0)
  local w, h = print(txt, 0, 0)
  clip()
  state.logo_w = w + (#cols - 1) * 3
  state.logo_h = h
  state.logo_t = 0
  state.logo_y_target = 19
  state.logo_center_y = flr(64 - (h / 2))
  state.logo_rect_center_x = 35
  state.logo_rect_target_x = 35
  state.logo_text_center_x = 40
  state.logo_text_target_x = 40
  state.logo_moved = false
  state.logo_move_t = 0
  state.menu_music_started = false
  state.menu_ready = false
  sfx(0)
end

function draw_shiny_logo(txt, x, y, cols)
  local h = state.logo_h
  for layer = 0, #cols - 1 do
    clip(x, y, state.logo_t - 3 * layer, h)
    print(txt, x, y, cols[layer + 1])
  end
  clip()
end

function restart()
  music(-1)
  _init()
end

function init_map()
  state.rooms = {}
  state.start_room = { x = state.room_x, y = state.room_y }
  for x = 1, state.map_w do
    state.rooms[x] = {}
    for y = 1, state.map_h do
      state.rooms[x][y] = {
        doors = { n = false, s = false, e = false, w = false },
        generated = false,
        cleared = false,
        spawn_pending = false,
        spawn_t = 0,
        drops = {},
        corpses = {},
        slime = {}
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
    speed = 1.3,
    last_dir = { x = 1, y = 0 },
    facing = "right",
    invuln_t = 0,
    dodge_t = 0,
    attack_t = 0,
    attack_hit = {},
    combo_step = 0,
    combo_t = 0,
    attack_cd = 0,
    attack_held = false,
    dead_t = nil,
    throw_cd = 0,
    throw_held = false,
    weapons = {},
    trail_t = 0,
    trail_rate = 4,
    moving = false
  }
end

function enter_room(rx, ry, from_init)
  state.room_x, state.room_y = rx, ry
  state.enemies = {}
  state.projectiles = {}
  state.enemy_projectiles = {}
  local room = state.rooms[rx][ry]
  room.drops = room.drops or {}
  room.corpses = room.corpses or {}
  state.drops = room.drops
  state.corpses = room.corpses
  room.spawn_markers = {}
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
        local e = make_enemy(pick_enemy_kind())
        add(room.spawn_list, e)
      end
    end
  elseif room.cleared then
    -- no enemies
  else
    local count = flr(rnd(2)) + 1
    room.spawn_list = {}
    for i = 1, count do
      local e = make_enemy(pick_enemy_kind())
      add(room.spawn_list, e)
    end
  end
  if room.spawn_pending and room.spawn_list then
    for e in all(room.spawn_list) do
      add(room.spawn_markers, { x = e.x, y = e.y, t = 0, scale = e.scale or 1 })
    end
  end

  if not from_init then
    state.player.invuln_t = 10
  end
end

function make_enemy(kind)
  local lvl = state.level or 1
  local hp_mult = 1 + 0.2 * max(0, lvl - 1)
  local padding = kind == "big" and 24 or 16
  local e = {
    x = flr(rnd(128 - padding * 2)) + padding,
    y = flr(rnd(128 - padding * 2)) + padding,
    w = 8,
    h = 8,
    scale = 1,
    max_hp = flr(4 * hp_mult),
    dmg = 1,
    speed = 0.6,
    stun_t = 0,
    frames = { 57, 58 },
    anim_speed = 8,
    death_frames = { 60, 61 },
    kind = kind or "base"
  }
  if kind == "big" then
    e.max_hp = flr(10 * hp_mult)
    e.speed = 0.25
    e.w = 16
    e.h = 16
    e.scale = 2
    e.frames = { 36, 37, 38, 37 }
    e.death_frames = { 39, 40 }
  elseif kind == "ranged" then
    e.max_hp = flr(1 * hp_mult)
    e.speed = 0
    e.no_move = true
    e.no_attack = true
    e.frames = { 41, 42, 43 }
    e.death_frames = { 44, 45 }
    e.shoot_cd = 60
    e.shoot_t = flr(rnd(30))
    e.projectile_dmg = 1
  elseif kind == "fast" then
    e.max_hp = flr(3 * hp_mult)
    e.speed = 1.1
    e.frames = { 52, 53 }
    e.death_frames = { 55, 56 }
  end

  e.hp = e.max_hp
  return e
end

function make_tutorial_enemy()
  local e = make_enemy("base")
  e.no_attack = true
  e.no_move = true
  e.force_drop = true
  e.hp = 2
  e.max_hp = 2
  return e
end

function pick_enemy_kind()
  local r = rnd(1)
  if r < 0.5 then return "base" end
  if r < 0.7 then return "big" end
  if r < 0.85 then return "ranged" end
  return "fast"
end

function update_player()
  local p = state.player
  if p.hp <= 0 then
    if p.dead_t == nil then
      p.dead_t = 68
      state.gameover_t = 0
      sfx(5)
    elseif p.dead_t > 0 then
      p.dead_t -= 1
    end
    if state.gameover_t and state.gameover_t < 128 then
      state.gameover_t += 1
    end
    if p.dead_t <= 0 and (btnp(4) or btnp(5)) then
      restart()
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
    if btn(4) and not p.attack_held and p.attack_t <= 0 and p.dodge_t <= 0 and p.attack_cd <= 0 then
      start_attack()
    elseif btnp(5) and p.dodge_t <= 0 then
      start_dodge()
    end
  end
  p.attack_held = btn(4)

  local move_x, move_y = 0, 0
  if btn(0) then move_x -= 1 end
  if btn(1) then move_x += 1 end
  if btn(2) then move_y -= 1 end
  if btn(3) then move_y += 1 end

  if move_x != 0 or move_y != 0 then
    local len = sqrt(move_x * move_x + move_y * move_y)
    p.last_dir = { x = move_x / len, y = move_y / len }
    if abs(move_x) >= abs(move_y) then
      if move_x > 0 then p.facing = "right" else p.facing = "left" end
    else
      if move_y > 0 then p.facing = "down" else p.facing = "up" end
    end
  end

  local spd = p.speed
  if p.dodge_t > 0 then
    p.dodge_t -= 1
    spd = 3.0
  end

  local dx, dy = move_x * spd, move_y * spd
  local old_x, old_y = p.x, p.y
  p.x, p.y = sweep_move(
    p.x, p.y, dx, dy, function(nx, ny)
      return room_collides(nx, ny, p.w, p.h)
    end
  )
  p.moving = p.x != old_x or p.y != old_y
  if p.moving then
    p.trail_t = p.trail_t - 1
    if p.trail_t <= 0 then
      add_slime(p.x + p.w / 2, p.y + p.h - 1)
      p.trail_t = p.trail_rate
    end
  else
    p.trail_t = 0
  end

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
  if aabb(p.x, p.y, p.w, p.h, 56, 56, 16, 16) and btnp(3) then
    new_level()
  end
end

function new_level()
  state.level = state.level + 1
  state.room_x, state.room_y = 3, 3
  state.floor_color = rand_floor_color()
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
  if weapon_count <= 0 then
    sfx(10)
  else
    if p.combo_step == 1 then
      sfx(11)
    elseif p.combo_step == 2 then
      sfx(12)
    elseif p.combo_step == 3 then
      sfx(13)
    else
      sfx(14)
    end
  end
  p.attack_hit = {}
  p.attack_boxes, p.attack_dmg, p.attack_t = get_attack_data(p)
  p.attack_dur = p.attack_t
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
        if aabb(b.x - pad, b.y - pad, b.w + pad * 2, b.h + pad * 2, e.x, e.y, e.w, e.h) then
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
    for i = 0, 3 do
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
  sfx(3)
end

function try_throw_weapon()
  local p = state.player
  if #p.weapons <= 0 then return end
  sfx(4)
  local weapon = p.weapons[1]
  local spawn_trail = weapon.dur and weapon.dur > 0
  deli(p.weapons, 1)
  p.combo_step = 0
  p.combo_t = 0
  p.throw_cd = 18
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
    dur = weapon.dur or 0,
    trail = spawn_trail
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
        room.spawn_markers = nil
      end
    end
  end
  local p = state.player
  for i = #state.enemies, 1, -1 do
    local e = state.enemies[i]
    if e.hp <= 0 then
      sfx(8)
      state.score = state.score + e.max_hp * 10
      add_explosion(e.x + 4, e.y + 4, 1, 5, 8)
      local df = e.death_frames or { 20, 21 }
      add_death_anim(e.x + e.w / 2, e.y + e.h / 2, df, 6, e.scale or 1)
      add(state.corpses, { x = e.x, y = e.y, spr = df[#df], scale = e.scale or 1 })
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
            vx = e.wander_dx
            vy = e.wander_dy
          end
          e.x, e.y = sweep_move(
            e.x, e.y, vx, vy, function(nx, ny)
              return room_collides(nx, ny, e.w, e.h)
            end
          )
        end
      end

      if e.kind == "ranged" and p.hp > 0 then
        e.shoot_t = e.shoot_t - 1
        if e.shoot_t <= 0 then
          spawn_enemy_projectile(e, p)
          e.shoot_t = e.shoot_cd or 60
        end
      end

      if p.hp > 0 and not e.no_attack then
        if p.invuln_t <= 0 and aabb(p.x, p.y, p.w, p.h, e.x, e.y, e.w, e.h) then
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
    if pr.trail then
      trail_fx(pr.x + pr.w / 2, pr.y + pr.h / 2, 2, { 12, 13, 1 }, 1)
    end
    local nx, ny = pr.x + pr.dx, pr.y + pr.dy
    if room_collides(nx, ny, pr.w, pr.h) then
      add(state.drops, { x = pr.x, y = pr.y, spr = pr.spr, dmg = pr.dmg, dur = pr.dur })
      deli(state.projectiles, i)
    else
      pr.x, pr.y = nx, ny
      local hit = false
      for j = #state.enemies, 1, -1 do
        local e = state.enemies[j]
        if aabb(pr.x, pr.y, pr.w, pr.h, e.x, e.y, e.w, e.h) then
          apply_throw_impact(pr)
          hit = true
          break
        end
      end
      if hit then
        pr.dur = max(0, (pr.dur or 1) - 1)
        if pr.dur > 0 then
          add(state.drops, { x = pr.x, y = pr.y, spr = pr.spr, dmg = pr.dmg, dur = pr.dur })
        end
        deli(state.projectiles, i)
      end
    end
  end
end

function spawn_enemy_projectile(e, p)
  local ex = e.x + e.w / 2
  local ey = e.y + e.h / 2
  local px = p.x + p.w / 2
  local py = p.y + p.h / 2
  local dx = px - ex
  local dy = py - ey
  local len = sqrt(dx * dx + dy * dy)
  if len <= 0 then
    dx, dy = 1, 0
    len = 1
  end
  dx /= len
  dy /= len
  add(
    state.enemy_projectiles, {
      x = ex - 2,
      y = ey - 2,
      w = 4,
      h = 4,
      dx = dx * 1.6,
      dy = dy * 1.6,
      dmg = e.projectile_dmg or 1
    }
  )
  sfx(7)
end

function update_enemy_projectiles()
  local p = state.player
  for i = #state.enemy_projectiles, 1, -1 do
    local pr = state.enemy_projectiles[i]
    local nx, ny = pr.x + pr.dx, pr.y + pr.dy
    if room_collides(nx, ny, pr.w, pr.h) then
      deli(state.enemy_projectiles, i)
    else
      pr.x, pr.y = nx, ny
      if p.hp > 0 and p.invuln_t <= 0 and aabb(pr.x, pr.y, pr.w, pr.h, p.x, p.y, p.w, p.h) then
        player_hit({ x = pr.x, y = pr.y }, pr.dmg or 1)
        deli(state.enemy_projectiles, i)
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
      damage_enemy(e, pr.dmg, true, cx, cy, 2)
      e.stun_t = max(e.stun_t, 90)
      local len = sqrt(dx * dx + dy * dy)
      if len > 0 then
        local kx = dx / len * 4
        local ky = dy / len * 4
        e.x, e.y = sweep_move(
          e.x, e.y, kx, ky, function(nx, ny)
            return room_collides(nx, ny, e.w, e.h)
          end
        )
      end
      hit_any = true
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
    if (not d.fly_t or d.fly_t <= 0) and aabb(p.x, p.y, p.w, p.h, d.x, d.y, 8, 8) then
      if #p.weapons < 4 then
        local stats = weapon_stats(d.spr)
        add(p.weapons, { spr = d.spr, dmg = d.dmg or stats.dmg, dur = d.dur or stats.dur })
        state.pickup_msg = weapon_name(d.spr) .. ": " .. (d.dmg or stats.dmg) .. "DMG, " .. (d.dur or stats.dur) .. "DUR"
        state.pickup_t = 90
        sfx(9)
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
  local play_hit_sfx = p.invuln_t <= 0 and hit_dmg > 0
  local back_x = sgn(p.x - e.x)
  local back_y = sgn(p.y - e.y)
  local slime_x = p.x + p.w / 2 + back_x * 3
  local slime_y = p.y + p.h / 2 + back_y * 3
  for i = 1, 15 do
    add_slime(
      slime_x + back_x * rnd(i) * 2 + rnd(3) - 1.5,
      slime_y + back_y * rnd(i) * 2 + rnd(3) - 1.5
    )
  end
  trail_fx(slime_x, slime_y, 6, { 11, 10, 3 }, 6)
  p.invuln_t = 25
  if #p.weapons > 0 then
    if play_hit_sfx then
      local slice = flr(rnd(3)) * 3
      sfx(1, -1, slice, 3)
    end
    local top = p.weapons[#p.weapons]
    top.dur -= hit_dmg
    if top.dur <= 0 then
      deli(p.weapons, #p.weapons)
    end
  else
    if play_hit_sfx then
      sfx(2)
    end
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
  local slice = flr(rnd(3)) * 3
  sfx(6, -1, slice, 3)
  e.hp -= dmg
  blood_fx(e.x + e.w / 2, e.y + e.h / 2, 2, { 8, 2, 1 }, 4)
  local stun = from_throw and 90 or 8
  e.stun_t = max(e.stun_t, stun)
  if src_x and src_y and kb and kb > 0 then
    local dx = e.x + e.w / 2 - src_x
    local dy = e.y + e.h / 2 - src_y
    local len = sqrt(dx * dx + dy * dy)
    if len > 0 then
      dx = dx / len
      dy = dy / len
      local kx = dx * kb
      local ky = dy * kb
      e.x, e.y = sweep_move(
        e.x, e.y, kx, ky, function(nx, ny)
          return room_collides(nx, ny, e.w, e.h)
        end
      )
    end
  end
end

function make_drop(x, y)
  local keys = { 10, 11, 12, 13 }
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

function rand_floor_color()
  local cols = { 3, 15, 1 }
  return cols[flr(rnd(#cols)) + 1]
end

function weapon_stats(spr)
  local stats = {
    [10] = { dmg = 2, dur = 1 },
    [11] = { dmg = 1, dur = 2 },
    [12] = { dmg = 1, dur = 3 },
    [13] = { dmg = 1, dur = 1 }
  }
  return stats[spr] or { dmg = 1, dur = 1 }
end

function weapon_name(spr)
  local names = {
    [10] = "SWORD",
    [11] = "POT",
    [12] = "SHIELD",
    [13] = "BROOM"
  }
  return names[spr] or "WEAPON"
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

function add_slime(x, y)
  local room = state.rooms[state.room_x][state.room_y]
  room.slime = room.slime or {}
  local c = rnd(1) < 0.5 and 11 or 10
  add(room.slime, { x = x + rnd(3) - 1.5, y = y + rnd(3) - 1.5, c = c, r = 1 })
  if #room.slime > 120 then
    deli(room.slime, 1)
  end
end

function draw_slime()
  local room = state.rooms[state.room_x][state.room_y]
  if not room.slime then return end
  for s in all(room.slime) do
    if s.r and s.r > 1 then
      circfill(s.x, s.y, s.r, s.c)
    else
      pset(s.x, s.y, s.c)
    end
  end
end

function draw_room()
  local room = state.rooms[state.room_x][state.room_y]
  rectfill(0, 0, 127, 127, state.floor_color)
  rectfill(0, 0, 127, 6, 5)
  rectfill(0, 127 - 6, 127, 127, 5)
  rectfill(0, 0, 6, 127, 5)
  rectfill(127 - 6, 0, 127, 127, 5)
  local locked = #state.enemies > 0 or room.spawn_pending
  local door_w = 28
  if room.doors.n and not locked then rectfill(64 - door_w / 2, 0, 64 + door_w / 2, 6, state.floor_color) end
  if room.doors.s and not locked then rectfill(64 - door_w / 2, 127 - 6, 64 + door_w / 2, 127, state.floor_color) end
  if room.doors.w and not locked then rectfill(0, 64 - door_w / 2, 6, 64 + door_w / 2, state.floor_color) end
  if room.doors.e and not locked then rectfill(127 - 6, 64 - door_w / 2, 127, 64 + door_w / 2, state.floor_color) end
  if room.cleared and state.room_x == state.exit_room.x and state.room_y == state.exit_room.y then
    draw_scaled_sprite(62, 56, 56, 2)
  end
  if state.room_x == state.start_room.x and state.room_y == state.start_room.y then
    draw_scaled_sprite(63, 56, 56, 2)
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
    local spr_id = 1
    if p.facing == "right" then spr_id = 2 end
    if p.facing == "up" then spr_id = 3 end
    if p.facing == "down" then spr_id = 4 end
    if p.facing == "left" then spr_id = 5 end
    if p.attack_t and p.attack_t > 0 then
      spr_id += 16
    elseif p.moving then
      local anim = (state.t \ 8) % 2
      if anim == 1 then
        spr_id += 16
      end
    end
    spr(spr_id, p.x, p.y)
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
  local spr_id, flipx, flipy = weapon_sprite_for_dir(p.attack_fx_weapon, dir.x, dir.y)
  local t = p.attack_t
  local dur = max(1, p.attack_dur or 1)
  local prog = 1 - t / dur

  if #p.weapons <= 0 or p.attack_fx_kind == 0 then
    local max_len = 8
    local phase = prog < 0.5 and prog * 2 or (1 - prog) * 2
    local len = max_len * phase
    local w = 3
    local sx = cx + dir.x * len
    local sy = cy + dir.y * len
    local ex = cx
    local ey = cy
    local lx = min(sx, ex)
    local ly = min(sy, ey)
    local rx = max(sx, ex)
    local ry = max(sy, ey)
    rectfill(lx - w / 2, ly - w / 2, rx + w / 2, ry + w / 2, 11)
    return
  end

  if p.attack_fx_kind == 1 then
    local max_dist = 10
    local phase = prog < 0.5 and prog * 2 or (1 - prog) * 2
    local dist = max_dist * phase
    if spr_id then
      spr(spr_id, cx + dir.x * dist - 4, cy + dir.y * dist - 4, 1, 1, flipx, flipy)
    end
  elseif p.attack_fx_kind == 2 then
    local spread = 12
    local sweep = (prog * 2) - 1
    local ox = px * sweep * spread
    local oy = py * sweep * spread
    local fx = cx + ox + dir.x * 10
    local fy = cy + oy + dir.y * 10
    if spr_id then
      spr(spr_id, fx - 4, fy - 4, 1, 1, flipx, flipy)
    end
  elseif p.attack_fx_kind == 3 then
    local ang = prog
    local r = 12
    local ox = cos(ang) * r
    local oy = sin(ang) * r
    if spr_id then
      spr(spr_id, cx + ox - 4, cy + oy - 4, 1, 1, flipx, flipy)
    end
  else
    local max_dist = 24
    local phase = prog < 0.5 and prog * 2 or (1 - prog) * 2
    local dist = max_dist * phase
    if spr_id then
      spr(spr_id, cx + dir.x * dist - 4, cy + dir.y * dist - 4, 1, 1, flipx, flipy)
    end
  end
end

function draw_enemies()
  for e in all(state.enemies) do
    local frames = e.frames or { 17, 18, 19, 18 }
    local spd = e.anim_speed or 8
    local idx = (state.t \ spd) % #frames + 1
    draw_scaled_sprite(frames[idx], e.x, e.y, e.scale or 1)
    if e.max_hp and e.hp < e.max_hp then
      local ratio = e.hp / e.max_hp
      local bw = e.w
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
    local spr_id, flipx, flipy = weapon_sprite_for_dir(pr.spr, pr.dx, pr.dy)
    spr(spr_id, pr.x, pr.y, 1, 1, flipx, flipy)
  end
end

function draw_enemy_projectiles()
  for pr in all(state.enemy_projectiles) do
    circfill(pr.x + 2, pr.y + 2, 2, 8)
  end
end

function draw_drops()
  for d in all(state.drops) do
    spr(d.spr, d.x, d.y)
  end
end

function weapon_sprite_for_dir(spr_id, dx, dy)
  if not spr_id then return nil, false, false end
  local horiz = {
    [10] = 26,
    [11] = 27,
    [12] = 28,
    [13] = 29
  }
  local ax = abs(dx)
  local ay = abs(dy)
  if ax >= ay then
    local base = horiz[spr_id] or spr_id
    return base, dx < 0, false
  end
  return spr_id, false, dy > 0
end

function draw_corpses()
  for c in all(state.corpses) do
    draw_scaled_sprite(c.spr, c.x, c.y, c.scale or 1)
  end
end

function draw_spawn_markers()
  local room = state.rooms[state.room_x][state.room_y]
  if not room.spawn_pending or not room.spawn_markers then
    return
  end
  local frames = { 32, 33, 34, 33 }
  for m in all(room.spawn_markers) do
    m.t = m.t + 1
    local idx = (m.t \ 6) % #frames + 1
    draw_scaled_sprite(frames[idx], m.x, m.y, m.scale or 1)
  end
end
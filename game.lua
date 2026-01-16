function _init()
  init_state()
  init_spawn_progression()
  create_starfield()
end

function _update()
  if (state.pause_t or 0) > 0 then
    state.pause_t -= 1
    if state.pause_t <= 0 then state.paused = false end
    return
  end
  local f = upd[state.current_state]
  if f then f() end
end

function _draw()
  cls()
  local f = drw[state.current_state]
  if f then f() end
end

function update_game()
  if state.paused then
    return
  end

  if state.alert_t > 0 then state.alert_t -= 1 end

  state.upgrade_t += 1
  local interval = state.upgrade_interval
  if state.upgrade_t >= interval then
    state.upgrade_t = 0
    enter_upgrade_screen()
    return
  end
  -- Game update logic goes here
  for player in all(state.players) do
    update_player(player)
  end
  -- See if player 2 has joined
  if state.number_of_players < 2 and btnp(4, 1) then
    player_join(1)
  end
  update_anim_lists({ state.projectiles, state.pickups, state.players })
  update_enemies()
end

function draw_game()
  -- Draw game elements in world space
  apply_ss()
  draw_starfield()
  draw_anim_lists({ state.enemies, state.pickups, state.players, state.projectiles })
  draw_juice()
  camera()
  draw_hud()
end

function update_player(player)
  if player.dead or state.paused then
    return
  end
  if player.hit_invuln_t and player.hit_invuln_t > 0 then
    player.hit_invuln_t -= 1
  end
  if player.dodge_t and player.dodge_t > 0 then
    player.dodge_t -= 1
  end
  if player.fire_cooldown_t and player.fire_cooldown_t > 0 then
    player.fire_cooldown_t -= 1
  end
  for p in all(state.pickups) do
    if not p.dead and aabb(player.x, player.y, 8, 8, p.x - 4, p.y - 4, 8, 8) then
      if p.picked_up then
        p:picked_up(player)
      else
        p.dead = true
      end
    end
  end
  -- Update player state
  local b4 = btn(4, player.id)
  local b5 = btn(5, player.id)
  local l = btn(0, player.id)
  local r = btn(1, player.id)
  local u = btn(2, player.id)
  local d = btn(3, player.id)
  local dx = b2n(r) - b2n(l)
  local dy = b2n(d) - b2n(u)
  if b5 and (player.dodge_t or 0) <= 0 then
    player_dodge(player, dx, dy)
  end
  local moving_back = dy > 0
  player.moving_back = moving_back
  player_move(player, dx, dy)

  player.spr = moving_back and 4
      or l and not r and 1
      or r and not l and 3
      or 2

  if b4 and btn(5, player.id) then
    activate_ready_upgrade(player)
  end
  if b4 and not b5 then
    if player.fire_cooldown_t > 0 then
      return
    end
    local rate = (player.fire_rate or 1) * (player.fire_rate_mult or 1)
    player.fire_cooldown_t = flr(30 / rate)
    local p = copy_tbl(player.bullet)
    p.owner = player
    p.x = player.x - dx
    p.y = player.y - 4
    p.dy = -(player.bullet.speed + player.proj_speed_bonus)
    p.dmg = player.bullet.dmg + player.proj_dmg_bonus
    p.ignore_player = state.safe_bullets
    player_shoot(player, p)
  end
end

function player_shoot(player, projectile)
  -- Play shooting sound effect, allows for slicing to add pitch variation
  if not player.single_fire then
    shoot(projectile)
    add_muzzle_flash(player, 4, -2, 3, 4, 7, 2)
    if player.bullet.sfx then sfx(player.bullet.sfx, -1, (rnd(1) < 0.5) and 0 or player.bullet.sfx_slice, player.bullet.sfx_slice) end
  end
end

function player_dodge(player, dx, dy)
  if dx == 0 and dy == 0 then return end
  local dist = player.dodge_dist
  local tx = mid(0, player.x + dx * dist, 120)
  local ty = mid(0, player.y + dy * dist, 100)
  local function collides(nx, ny)
    for other in all(state.players) do
      if other ~= player and not other.dead
          and aabb(nx, ny, 8, 8, other.x, other.y, 8, 8) then
        return true
      end
    end
    return false
  end
  local nx, ny = sweep_move(player.x, player.y, tx - player.x, ty - player.y, collides)
  if nx ~= tx or ny ~= ty then
    sfx(12)
  end
  player.x = nx
  player.y = ny
  player.hit_invuln_t = max(player.hit_invuln_t, 7)
  add_sprite_flash(player, { 8, 2, 14 }, 7, player.hit_invuln_t)
  sfx(13)
  add_death_anim(player.x, player.y, { 5, 6 })
  player.dodge_t = player.dodge_cd or 60
end

function player_move(player, dx, dy)
  -- update player sprite based on movement direction, 1 = left, 2 = idle/forward, 3 = right, 4 = back
  local f = (dx < 0 and 1)
      or (dx > 0 and 3)
      or (dy > 0 and 4)
      or 2
  player.frames = { f }

  -- Prevent players from overlapping each other.
  local function overlaps_other(next_x, next_y)
    for other in all(state.players) do
      if other ~= player and not other.dead then
        if aabb(next_x, next_y, 8, 8, other.x, other.y, 8, 8) then
          return true
        end
      end
    end
    return false
  end

  player.speed = (player.base_speed or player.speed or 1) + (player.speed_bonus or 0)
  local next_x = player.x + dx * player.speed
  next_x = mid(0, next_x, 120)
  if not overlaps_other(next_x, player.y) then
    player.x = next_x
  end

  local next_y = player.y + dy * player.speed
  next_y = mid(0, next_y, 100)
  if not overlaps_other(player.x, next_y) then
    player.y = next_y
  end

  local trail_found = false
  -- rocket trail animation delete or add as needed
  for trail in all(state.rocket_trails) do
    if trail.owner == player then
      trail_found = true
      -- update trail position to follow behind player
      trail.x = player.x
      trail.y = player.y + 8
      -- delete trail if player is not moving or moving back
      if dx == 0 and dy == 0 or player.moving_back or player.dead then
        trail.dead = true
      end
    end
  end
  if not trail_found and (dx ~= 0 or dy ~= 0) and not player.moving_back then
    local trail = {
      owner = player,
      x = player.x,
      y = player.y + 8,
      frames = { 7, 8, 9, 10 },
      loop = true,
      anim_speed = 5,
      t = 0
    }
    add(state.rocket_trails, trail)
  end
end

function shoot(projectile)
  if not projectile.draw and not projectile.frames and projectile.shape == "circle" then
    projectile.draw = function(self)
      local r = self.radius or 2
      if self.pulse and (self.t or 0) % 6 < 3 then
        r += 1
      end
      -- Treat x/y as top-left; offset to center the circle.
      local cx = self.x + r - 1
      local cy = self.y + r - 1
      circfill(cx, cy, r, self.color or 8)
    end
  end
  add(state.projectiles, projectile)
  return projectile
end

upd = {
  main_menu = update_main_menu,
  playing = update_game,
  game_over = update_game_over,
  upgrade_screen = update_upgrade_screen
}

drw = {
  main_menu = draw_main_menu,
  playing = function() update_juice() draw_game() end,
  game_over = draw_game_over,
  upgrade_screen = draw_upgrade_screen
}
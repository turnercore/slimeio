-- generic anim helpers
function update_anim_lists(lists)
  for _, anim_list in pairs(lists) do
    if anim_list then update_anim(anim_list) end
  end
end

function update_anim(anim_list)
  for i = #anim_list, 1, -1 do
    local a = anim_list[i]
    -- increment time
    a.t = a.t and a.t + (a.dec and -1 or 1) or 1
    if a.dead then
      deli(anim_list, i)
    else
      if a.frames then
        local spd = a.anim_speed or 1
        local cyc = spd * #a.frames
        if a.loop and not a.dec and a.t >= cyc then
          a.t = 0
        elseif not a.loop and ((a.dec and a.t <= 0) or (not a.dec and a.t > cyc)) then
          deli(anim_list, i)
        end
      elseif a.dur then
        if (a.dec and a.t <= 0) or (not a.dec and a.t >= a.dur) then
          deli(anim_list, i)
        end
      elseif a.dec and a.t <= 0 then
        deli(anim_list, i)
      end
      if a.dx or a.dy then
        a.x = a.x + (a.dx or 0)
        a.y = a.y + (a.dy or 0)
      end
      -- update flash timer if present
      if a.flash then
        a.flash.t -= 1
        if a.flash.t <= 0 then
          a.flash = nil
        end
      end

      if a.update then
        a:update()
      end
    end
  end
end

function draw_anim_lists(lists)
  for anim_list in all(lists) do
    draw_anims(anim_list)
  end
end

function draw_anims(anim_list)
  for i = #anim_list, 1, -1 do
    local a = anim_list[i]
    if a.draw then
      a:draw()
    elseif a.frames then
      -- update palette if needed
      if a.pal then pal(a.pal[1], a.pal[2]) end
      -- determine frame to draw
      local spd = a.anim_speed or 1
      local idx = (a.t \ spd) + 1
      if idx > #a.frames then idx = #a.frames end

      if a.flash then
        -- handle sprite flashing
        local flash_phase = flr((a.flash.dur - a.flash.t) / a.flash.dur * 4)
        if (flash_phase % 2) == 0 then
          for base_col in all(a.flash.base_cols) do
            pal(base_col, a.flash.flash_col)
          end
        end
      end
      -- draw the sprite
      spr(a.frames[idx], a.x, a.y, a.w or 1, a.h or 1, a.flipx or false, a.flipy or false)
      -- reset palette
      pal()
      if not a.loop and not a.dec and a.t > spd * #a.frames then
        deli(anim_list, i)
      end
    end
  end
end

function add_explosion(x, y, size, duration, col)
  local e = {
    x = x,
    y = y,
    t = duration,
    dec = true,
    size = size or 1,
    col = col,
    draw = function(self)
      local r = self.t
      if r <= 0 then return end
      local c = self.col or 8
      for i = 1, self.size do
        local ox = flr(rnd(3)) - 1
        local oy = flr(rnd(3)) - 1
        circfill(self.x + ox, self.y + oy, r, c)
        if r > 2 then
          circfill(self.x + ox, self.y + oy, r - 2, 7)
        end
      end
    end
  }
  add(state.explosions, e)
  return e
end

function add_screen_flash(duration, col)
  local f = {
    t = duration or 8,
    dec = true,
    col = col or 7,
    draw = function(self)
      rectfill(0, 0, 127, 127, self.col)
    end
  }
  add(state.screen_flashes, f)
  return f
end

function add_sprite_flash(obj, base_cols, flash_col, duration)
  obj.flash = {
    is_flashing = true,
    t = duration or 4,
    dur = duration or 4,
    flash_col = flash_col or 7,
    base_cols = base_cols or { 8 }
  }
end

function add_death_anim(x, y, frames, rate, w, h, pal)
  local a = {
    x = x - 4,
    y = y - 4,
    w = w or 1,
    h = h or 1,
    pal = pal,
    frames = frames,
    anim_speed = rate or 4,
    loop = false,
    t = 0
  }
  add(state.death_anims, a)
  return a
end

-- screenshake helpers
function ss(frames, mag)
  frames = frames or 0
  if frames <= 0 then
    return
  end
  state.ss_t = max(state.ss_t or 0, frames)
  state.ss_mag = max(state.ss_mag or 0, mag or 1)
end

function update_ss()
  local t = state.ss_t or 0
  if t > 0 then
    t -= 1
    state.ss_t = t
    if t <= 0 then
      state.ss_mag = nil
    end
  end
end

function apply_ss()
  local t = state.ss_t or 0
  if t <= 0 then
    camera()
    return
  end
  local mag = state.ss_mag or 1
  local ox = flr(rnd(mag * 2 + 1)) - mag
  local oy = flr(rnd(mag * 2 + 1)) - mag
  camera(ox, oy)
end

-- hitstop helper (freeze frames)
function hitstop(duration)
  if duration <= 0 then
    return
  end
  state.pause_t = max(state.pause_t or 0, duration)
  state.paused = true
end

function update_juice()
  update_anim_lists({ state.explosions, state.death_anims, state.muzzle_flashes, state.screen_flashes })
  update_fx()
  update_ss()
end

function draw_juice()
  draw_anim_lists({ state.explosions, state.death_anims, state.muzzle_flashes, state.screen_flashes })
  draw_fx()
end

-- particle helpers
function add_fx(x, y, die, dx, dy, grav, grow, shrink, r, c_table)
  local fx = {
    x = x,
    y = y,
    t = 0,
    die = die,
    dx = dx,
    dy = dy,
    grav = grav,
    grow = grow,
    shrink = shrink,
    r = r,
    c = 0,
    c_table = c_table
  }
  add(state.effects, fx)
end

function update_fx()
  if not state.effects then return end
  for fx in all(state.effects) do
    fx.t += 1
    if fx.t > fx.die then
      del(state.effects, fx)
    else
      local phase = fx.t / fx.die
      local n = #fx.c_table
      local idx = min(n, flr(phase * n) + 1)
      fx.c = fx.c_table[idx]

      if fx.grav then fx.dy += 0.5 end
      if fx.grow then fx.r += 0.1 end
      if fx.shrink then fx.r -= 0.1 end

      fx.x += fx.dx
      fx.y += fx.dy
    end
  end
end

function draw_fx()
  if not state.effects then return end
  for fx in all(state.effects) do
    if fx.r <= 1 then
      pset(fx.x, fx.y, fx.c)
    else
      circfill(fx.x, fx.y, fx.r, fx.c)
    end
  end
end

function trail_fx(x, y, w, c_table, num)
  for i = 0, num do
    add_fx(
      x + rnd(w) - w / 2,
      y + rnd(w) - w / 2,
      18 + rnd(10),
      0,
      0,
      false,
      false,
      true,
      1,
      c_table
    )
  end
end

function blood_fx(x, y, r, c_table, num)
  for i = 0, num do
    add_fx(
      x,
      y,
      20 + rnd(10),
      rnd(2) - 1,
      rnd(2) - 1,
      false,
      false,
      true,
      r,
      c_table
    )
  end
end

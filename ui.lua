function draw_ui()
  local x, y = 1, 77
  local weapon_count = #state.player.weapons
  local combo_slot = 0
  if weapon_count > 0 then
    combo_slot = state.player.combo_step > 0 and state.player.combo_step or 1
  end

  rectfill(0, 75, 11, 127, 0)
  for slot = 1, 4 do
    local sy = y + (4 - slot) * 10
    local outline = 7
    if slot == combo_slot and slot <= weapon_count then
      outline = 10
    end
    rect(x, sy, x + 9, sy + 9, outline)
    if state.player.weapons[slot] then
      spr(state.player.weapons[slot].spr, x + 1, sy + 1)
    end
  end

  local heart_y = y + 4 * 10
  if weapon_count == 0 then
    if state.player.hp <= 0 then
      spr(51, x + 1, heart_y + 1)
    else
      local frames = { 48, 49, 50, 49 }
      local t = state.t or 0
      local idx = (t \ 18) % #frames + 1
      spr(frames[idx], x + 1, heart_y + 1)
    end
  end

  local room = state.rooms[state.room_x][state.room_y]
  if room.spawn_pending and not room.cleared then
    local secs = max(0, flr((room.spawn_t + 29) / 30))
    print(secs, 60, 1, 7)
  end
  local floor_txt = "floor "..(state.level or 1)
  local room_txt = "room "..state.room_x..","..state.room_y
  print(room_txt, 6, 1, 7)
  print(floor_txt, 93, 1, 7)

  if state.pickup_t and state.pickup_t > 0 and state.pickup_msg then
    state.pickup_t -= 1
    local msg = state.pickup_msg
    local x = 20
    local y = 122
    print(msg, x, y, 7)
  end

  local score_txt = "score "..(state.score or 0)
  local score_x = 128 - (#score_txt * 4) - 2
  print(score_txt, score_x, 122, 7)
end

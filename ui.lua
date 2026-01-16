function draw_ui()
  local x, y = 2, 2
  local weapon_count = #state.player.weapons
  local combo_slot = 0
  if weapon_count > 0 then
    combo_slot = state.player.combo_step > 0 and state.player.combo_step or 1
  end

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
    local frames = { 48, 49, 50, 49 }
    local t = state.t or 0
    local idx = (t \ 18) % #frames + 1
    spr(frames[idx], x + 1, heart_y + 1)
  end

  local room = state.rooms[state.room_x][state.room_y]
  if room.spawn_pending and not room.cleared then
    local secs = max(0, flr((room.spawn_t + 29) / 30))
    print(secs, 60, 2, 7)
  end
  print("floor "..(state.level or 1), 96, 2, 7)
  print("room "..state.room_x..","..state.room_y, 80, 10, 7)

  if state.pickup_t and state.pickup_t > 0 and state.pickup_msg then
    state.pickup_t -= 1
    local msg = state.pickup_msg
    local w = #msg * 4
    local x = (128 - w) \ 2
    local y = 118
    rectfill(x - 2, y - 1, x + w + 1, y + 6, 0)
    print(msg, x, y, 7)
  end
end

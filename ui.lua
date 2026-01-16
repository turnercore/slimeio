function draw_ui()
  local x, y = 1, 77
  local p = state.player
  local weapons = p.weapons
  local weapon_count = #weapons
  local combo_slot = 0
  if weapon_count > 0 then
    local max_combo = min(weapon_count, 4)
    combo_slot = 1
    if p.combo_step > 0 and (p.combo_t or 0) > 0 then
      combo_slot = p.combo_step + 1
      if combo_slot > max_combo then combo_slot = 1 end
    end
  end

  rectfill(0, 75, 11, 127, 0)
  for slot = 1, 4 do
    local sy = y + (4 - slot) * 10
    local outline = (slot == combo_slot and slot <= weapon_count) and 10 or 7
    rect(x, sy, x + 9, sy + 9, outline)
    local w = weapons[slot]
    if w then spr(w.spr, x + 1, sy + 1) end
  end

  if weapon_count == 0 then
    local heart_y = y + 40
    local spr_id = 51
    if p.hp > 0 then
      local frames = { 48, 49, 50, 49 }
      spr_id = frames[(state.t \ 18) % #frames + 1]
    end
    spr(spr_id, x + 1, heart_y + 1)
  end

  local room = state.rooms[state.room_x][state.room_y]
  if room.spawn_pending and not room.cleared then
    local secs = max(0, flr((room.spawn_t + 29) / 30))
    print(secs, 60, 1, 7)
  end
  print("room " .. state.room_x .. "," .. state.room_y, 6, 1, 7)
  print("floor " .. (state.level or 1), 93, 1, 7)

  if state.pickup_t and state.pickup_t > 0 and state.pickup_msg then
    state.pickup_t -= 1
    print(state.pickup_msg, 14, 122, 7)
  end

  local score_txt = "score " .. (state.score or 0)
  print(score_txt, 128 - (#score_txt * 4) - 2, 122, 7)
end
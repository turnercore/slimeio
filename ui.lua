function draw_ui()
  local x, y = 2, 2
  for i = 1, 4 do
    rect(x, y + (i - 1) * 10, x + 9, y + (i - 1) * 10 + 9, 7)
    if state.player.weapons[i] then
      spr(state.player.weapons[i].spr, x + 1, y + (i - 1) * 10 + 1)
    end
  end
  local max_hp = state.player.max_hp or 1
  for i = 1, max_hp do
    local col = (i <= state.player.hp) and 8 or 5
    rectfill(112 + (i - 1) * 5, 2, 115 + (i - 1) * 5, 5, col)
  end
end

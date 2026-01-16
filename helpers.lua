function aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

function sweep_move(x, y, dx, dy, collides)
  local steps = max(abs(dx), abs(dy))
  steps = max(1, flr(steps + 0.999))
  if steps == 0 then
    return x, y
  end
  local step_x = dx / steps
  local step_y = dy / steps
  local nx = x
  local ny = y
  for i = 1, steps do
    local tx = nx + step_x
    local ty = ny + step_y
    if collides(tx, ty) then
      return nx, ny
    end
    nx = tx
    ny = ty
  end
  return nx, ny
end

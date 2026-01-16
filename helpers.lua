-- Axis-aligned bounding box collision detection
function aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

-- Find the index of value v in table t, or nil if not found
function find(t, v)
  for i = 1, #t do
    if t[i] == v then
      return i
    end
  end
  return nil
end
-- Count the number of key/value pairs in a table
function count(t)
  local c = 0
  for _ in pairs(t) do
    c += 1
  end
  return c
end

-- Sweep movement helper
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

-- Check if a rectangle is offscreen, with optional margin
function is_offscreen_xy(x, y, w, h, margin)
  w = w or 0
  h = h or 0
  margin = margin or 0
  return x + w < -margin or x > (128 - 1 + margin) or y + h < -margin or y > (128 - 1 + margin)
end

-- shallow copy helper (copies key/value pairs; nested tables are shared)
function copy_tbl(t)
  local out = {}
  if t then
    for k, v in pairs(t) do
      out[k] = v
    end
  end
  return out
end

-- extend a base table with multiple extension tables, add them togeather, overriding existing keys if they exist
function extend(base, exts)
  local out = copy_tbl(base)
  for ext in all(exts) do
    for k, v in pairs(ext) do
      out[k] = v
    end
  end
  return out
end

-- boolean to number helper
function b2n(b) return b and 1 or 0 end
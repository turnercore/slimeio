-- Collision Detection

collisions = {
  rect_rect = function(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
  end,

  color = function(c, x, y, w, h)
    if w and h then
      for ix = x, x + w - 1 do
        for iy = y, y + h - 1 do
          if pget(ix, iy) == c then
            return true
          end
        end
      end
      return false
    else
      return pget(x, y) == c
    end
  end,

  -- boundary = function(obj, min_x, min_y, max_x, max_y)
  --   obj.x, obj.y = mid(min_x,obj.x,max_x), mid(min_y,obj.y,max_y)
  -- end,

  point_point = function(p1, p2)
    return p1.x == p2.x and p1.y == p2.y
  end,

  point_rect = function(p, r)
    return p.x >= r.x
        and p.x <= r.x + r.w
        and p.y >= r.y
        and p.y <= r.y + r.h
  end,

  point_circle = function(p, c)
    local dx, dy = p.x - c.x, p.y - c.y
    return dx * dx + dy * dy <= c.r * c.r
  end,

  circle_circle = function(c1, c2)
    local dx, dy, rsum = c2.x - c1.x, c2.y - c1.y, c1.r + c2.r
    return dx * dx + dy * dy <= rsum * rsum
  end,

  rect_circle = function(r, c)
    local dx, dy = c.x - mid(c.x, r.x, r.x + r.w), c.y - mid(c.y, r.y, r.y + r.h)
    return dx * dx + dy * dy <= c.r * c.r
  end,

  line_point = function(l, p)
    return abs((l.x2 - l.x1) * (l.y1 - p.y) - (l.x1 - p.x) * (l.y2 - l.y1)) < .1 and p.x >= min(l.x1, l.x2) and p.x <= max(l.x1, l.x2) and p.y >= min(l.y1, l.y2) and p.y <= max(l.y1, l.y2)
  end,

  line_line = function(l1, l2)
    local d1 = sgn((l1.x2 - l1.x1) * (l2.y1 - l1.y1) - (l1.y2 - l1.y1) * (l2.x1 - l1.x1))
    local d2 = sgn((l1.x2 - l1.x1) * (l2.y2 - l1.y1) - (l1.y2 - l1.y1) * (l2.x2 - l1.x1))
    local d3 = sgn((l2.x2 - l2.x1) * (l1.y1 - l2.y1) - (l2.y2 - l2.y1) * (l1.x1 - l2.x1))
    local d4 = sgn((l2.x2 - l2.x1) * (l1.y2 - l2.y1) - (l2.y2 - l2.y1) * (l1.x2 - l2.x1))
    return d1 != d2 and d3 != d4
  end
}

-- Find the index of value v in table t, or nil if not found
-- function find(t, v)
--   for i = 1, #t do
--     if t[i] == v then
--       return i
--     end
--   end
--   return nil
-- end

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
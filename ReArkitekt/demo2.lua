-- ReaScript: Region→Next (SnM-style)

local R = reaper

local regs = {}
local cur = -1
local nxt = -1
local ca, cb, na, nb = 0, -1, 0, -1
local last_pos = -1
local last_seek = -1.0

local function build()
  regs = {}
  local _, nm, nr = R.CountProjectMarkers(0)
  for i = 0, nm + nr - 1 do
    local ok, isrgn, a, b, _, num = R.EnumProjectMarkers(i)
    if ok and isrgn then regs[#regs+1] = {num=num, a=a, b=b} end
  end
  table.sort(regs, function(x,y) return x.a < y.a end)
  cur, nxt, ca, cb, na, nb = -1, (#regs>0 and 1 or -1), 0, -1, (regs[1] and regs[1].a or 0), (regs[1] and regs[1].b or -1)
end

local function idx_at(p)
  for i=1,#regs do local r=regs[i]; if p >= r.a and p < r.b-1e-9 then return i end end
  return -1
end

local function seek_region(region_num)
  local c = R.GetCursorPositionEx(0)
  R.PreventUIRefresh(1)
  R.GoToRegion(0, region_num, false)
  if R.GetPlayState() & 1 == 0 then R.OnPlayButton() end
  R.SetEditCurPos2(0, c, false, false)
  R.PreventUIRefresh(-1)
end

local function main()
  if #regs == 0 then build() end
  if #regs == 0 then R.defer(main) return end
  if R.GetPlayState() & 1 == 0 then R.OnPlayButton() end

  local p = R.GetPlayPosition2()
  if nxt >= 1 and p > na and p < nb + 0.01 then
    local first_pass = (cur ~= nxt) or (p < last_pos)
    if first_pass then
      cur = nxt; local r = regs[cur]; ca, cb = r.a, r.b
    end
    local n = (cur < #regs) and (cur + 1) or -1
    if n >= 1 then
      nxt = n; local r = regs[n]; na, nb = r.a, r.b
      local now = R.time_precise()
      if now - last_seek > 0.06 then
        seek_region(regs[n].num)
        last_seek = now
      end
    else
      nxt = -1
    end
  elseif ca < cb and p >= ca and p < cb + 0.01 then
    -- in current region
  else
    local i = idx_at(p)
    if i >= 1 then
      cur = i; local r = regs[i]; ca, cb = r.a, r.b
      local n = (i < #regs) and (i + 1) or -1
      if n >= 1 then nxt = n; local rr=regs[n]; na, nb = rr.a, rr.b end
    elseif p < regs[1].a then
      cur = -1; nxt = 1; local r = regs[1]; na, nb = r.a, r.b
    end
  end

  last_pos = p
  R.defer(main)
end

build()
main()

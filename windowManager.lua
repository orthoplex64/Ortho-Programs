-- wip

local component = require("component")
local wm = {}

function wm.rectIntersection(x1, y1, w1, h1, x2, y2, w2, h2)
  local xmin1, ymin1, xmax1, ymax1, xmin2, ymin2, xmax2, ymax2
    = x1, y1, x1 + w1, y1 + h1, x2, y2, x2 + w2, y2 + h2
  -- first test intersection
  if xmin2 > xmax1 or xmax2 < xmin1 or ymin2 > ymax1 or ymax2 < ymin1 then return end
  -- consider rect1 static; squish rect2 to fit within rect1
  if xmin2 < xmin1 then xmin2 = xmin1 end
  if xmax2 > xmax1 then xmax2 = xmax1 end
  if ymin2 < ymin1 then ymin2 = ymin1 end
  if ymax2 > ymax1 then ymax2 = ymax1 end
  return xmin2, ymin2, xmax2 - xmin2 + 1, ymax2 - ymin2 + 1
end

-- one wrapper is associated with each panel
function wm.gpuWrapper(gpu, clipX, clipY, clipW, clipH)
  if not clipX then
    clipX, clipY = 0, 0
    clipW, clipH = gpu.getResolution()
  end
  local res = {}
  res.__index = gpu
  -- state stores the previous state when drawing,
  --   and the current state when not drawing
  local state = {palette = {}}
  function res.wrapperGetClip()
    return clipX, clipY, clipW, clipH
  end
  function res.wrapperSetClip(x, y, width, height)
    clipX, clipY, clipW, clipH = x, y, width, height
  end
  function res.wrapperSwapState()
    if state.colorDepth then
      res.setDepth(state.colorDepth)
    end
    if state.bgColor then
      res.setBackground(state.bgColor, state.bgColorIsPaletteIndex)
    end
    if state.fgColor then
      res.setForeground(state.fgColor, state.fgColorIsPaletteIndex)
    end
    for k, v in pairs(state.palette) do
      res.setPaletteColor(k, v)
    end
  end
  function res.setBackground(...)
    if not state.bgColor then
      state.bgColor, state.bgColorIsPaletteIndex = gpu.getBackground()
    end
    return gpu.setBackground(...)
  end
  function res.setForeground(...)
    if not state.fgColor then
      state.fgColor, state.fgColorIsPaletteIndex = gpu.getForeground()
    end
    return gpu.setForeground(...)
  end
  function res.setPaletteColor(index, value)
    if not state.palette[index] then
      state.palette[index] = gpu.getPaletteColor(index)
    end
    return gpu.setPaletteColor(index, value)
  end
  function res.setDepth(...)
    if not state.colorDepth then
      state.colorDepth = gpu.getDepth()
    end
    return gpu.setDepth(...)
  end
  function res.maxResolution()
    return clipW, clipH
  end
  res.getResolution = res.maxResolution
  function res.setResolution()
    return false
  end
  function res.set(x, y, value, vertical)
    if x < 1 or x > clipW or y < 1 or y > clipH then return end
    value = value:sub(1, vertical and clipH - (y - 1) or clipW - (x - 1))
    return gpu.set(clipX + (x - 1), clipY + (y - 1), value, vertical)
  end
  function res.copy(x, y, width, height, tx, ty)
    if x < 1 or x > clipW or y < 1 or y > clipH
      or tx < 1 or tx > clipW or ty < 1 or ty > clipH
      then return end
    width = math.min(width, clipW - (x - 1), clipW - (tx - 1))
    height = math.min(height, clipH - (y - 1), clipH - (ty - 1))
    return gpu.copy(clipX + (x - 1), clipY + (y - 1)
	  , width, height, clipX + (tx - 1), clipY + (ty - 1))
  end
  function res.fill(x, y, width, height, char)
    if x < 1 or x > clipW or y < 1 or y > clipH then return end
    if width > clipW - (x - 1) then
      width = clipW - (x - 1)
    end
    if height > clipH - (y - 1) then
      height = clipH - (y - 1)
    end
    return gpu.fill(clipX + (x - 1), clipY + (y - 1)
	  , width, height, char)
  end
  return res
end

-- Panel class
wm.Panel = {}
local Panel = wm.Panel
Panel.__index = Panel
function Panel:new(parentGpu, x, y, width, height)
  local res = {}
  res.gpu = wm.gpuWrapper(parentGpu, x, y, width, height)
  res.x, res.y = x, y
  res.width, res.height = width, height
  res.children = {}
  setmetatable(res, self)
  return res
end
function Panel:paint()
  for k, v in ipairs(children) do
    v.gpu.wrapperSwapState()
    v:paint()
	v.gpu.wrapperSwapState()
  end
end

-- Window class
wm.Window = Panel:new()
local Window = wm.Window
Window.__index = Window
function Window:new(parentGpu, x, y, width, height, title)
  local res = {}
  res.title = title or "Window " .. (#wm.windows + 1)
  res.mainPanel = Panel:new()
  res.width = 1
  res.height = 1
  setmetatable(res, self)
  return res
end
function Window:paint()
  gpu.gpu.set(0, 0, self.title)
  self.mainPanel:paint()
end

return wm

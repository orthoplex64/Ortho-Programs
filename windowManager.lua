-- wip

local component = require("component")
local wm = {}

local function rectIntersection(x1, y1, w1, h1, x2, y2, w2, h2)
  local xmin1, ymin1, xmax1, ymax1, xmin2, ymin2, xmax2, ymax2
    = x1, y1, x1 + w1, y1 + h1, x2, y2, x2 + w2, y2 + h2
  -- first test intersection
  if xmin2 > xmax1 or xmax2 < xmin1 or ymin2 > ymax1 or ymax2 < ymin1 then return nil end
  -- consider rect1 static; squish rect2 to fit within rect1
  if xmin2 < xmin1 then xmin2 = xmin1 end
  if xmax2 > xmax1 then xmax2 = xmax1 end
  if ymin2 < ymin1 then ymin2 = ymin1 end
  if ymax2 > ymax1 then ymax2 = ymax1 end
  return xmin2, ymin2, xmax2 - xmin2 + 1, ymax2 - ymin2 + 1
end

local function gpuWrapper(gpu, clipX, clipY, clipW, clipH)
  local res = {}
  res.__index = gpu
  local prevState = {palette = {}}
  function res.setBackground(...)
    if not prevState.bgColor then
      prevState.bgColor, prevState.bgColorIsPaletteIndex = gpu.getBackground()
    end
    return gpu.setBackground(...)
  end
  function res.setForeground(...)
    if not prevState.fgColor then
      prevState.fgColor, prevState.fgColorIsPaletteIndex = gpu.getForeground()
    end
    return gpu.setForeground(...)
  end
  function res.setPaletteColor(index, value)
    if not prevState.palette[index] then
      prevState.palette[index] = gpu.getPaletteColor(index)
    end
    return gpu.setPaletteColor(index, value)
  end
  function res.setDepth(...)
    if not prevState.colorDepth then
      prevState.colorDepth = gpu.getDepth()
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
    asdf
    return gpu.copy(x, y, width, height, tx, ty)
  end
  return res
end

-- Panel class
wm.Panel = {}
local Panel = wm.Panel
Panel.__index = Panel
function Panel:new()
  local res = {}
  res.children = {}
  setmetatable(res, self)
  return res
end
function Panel:paint()
  asdf
end

-- Window class
wm.Window = {}
local Window = wm.Window
Window.__index = Window
function Window:new(title)
  local res = {}
  res.title = title or "Window " .. (#wm.windows + 1)
  res.mainPanel = Panel:new()
  res.width = 1
  res.height = 1
  setmetatable(res, self)
  return res
end
function Window:paint(gpu)
  gpu.set(self.x, self.y, self.title)
  self.mainPanel:paint()
end

return wm

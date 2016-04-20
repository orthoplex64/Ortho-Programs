-- wip

local component = require("component")
local wm = {}

local function gpuWrapper(gpu, x, y, width, height)
  local res = {}
  res.__index = gpu
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
